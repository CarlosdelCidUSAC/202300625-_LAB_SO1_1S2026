package analyzer

import (
	"fmt"
	"os/exec"
	"strings"

	"proyecto2-daemon-202300625/internal/config"
	"proyecto2-daemon-202300625/internal/logger"
	"proyecto2-daemon-202300625/internal/parser"
)

// ContainerType define el tipo de contenedor
type ContainerType int

const (
	LowConsumption ContainerType = iota
	HighRAM
	HighCPU
	Unknown
)

// Analyzer estructura del analizador de contenedores
type Analyzer struct {
	cfg    *config.Config
	logger *logger.Logger
}

// NewAnalyzer crea una nueva instancia del analizador
func NewAnalyzer(cfg *config.Config, log *logger.Logger) *Analyzer {
	return &Analyzer{
		cfg:    cfg,
		logger: log,
	}
}

// AnalyzeAndDecide realiza el análisis y decide qué contenedores eliminar
func (a *Analyzer) AnalyzeAndDecide(captura *parser.CapturaTelemetria) ([]int, error) {
	a.logger.Info("Iniciando análisis de contenedores", 
		"total_procesos", len(captura.Procesos),
		"ram_usada", captura.Memoria.UsoRAM)

	toDelete := []int{}

	// 1. Obtener estado actual de contenedores
	containers, err := a.getDockerContainers()
	if err != nil {
		a.logger.Warn("Error obteniendo contenedores de Docker", "error", err)
	}

	// 2. Clasificar contenedores
	classified := a.classifyContainers(containers)

	// 3. Contar tipos actuales
	lowCount := len(classified["low"])
	highCount := len(classified["high"])

	a.logger.Info("Estado actual de contenedores",
		"bajo_consumo", lowCount,
		"alto_consumo", highCount)

	// 4. Aplicar restricciones clave
	// Siempre mantener mínimo 3 de bajo consumo y 2 de alto consumo

	// 5. Determinar si hay exceso de consumo
	ramUsagePercent := float64(captura.Memoria.UsoRAM) / float64(captura.Memoria.TotalRAM) * 100

	if ramUsagePercent > a.cfg.RAMThreshold {
		a.logger.Warn("ALERTA: Consumo de RAM alto", 
			"porcentaje", fmt.Sprintf("%.2f%%", ramUsagePercent),
			"umbral", a.cfg.RAMThreshold)

		// Eliminar contenedores que excedan límites
		toDelete = a.selectContainersToDelete(captura, classified)
	}

	a.logger.Info("Decisión", "contenedores_a_eliminar", len(toDelete))
	return toDelete, nil
}

// selectContainersToDelete selecciona qué contenedores eliminar respetando restricciones
func (a *Analyzer) selectContainersToDelete(captura *parser.CapturaTelemetria, 
	classified map[string][]string) []int {
	
	toDelete := []int{}

	// Ordenar procesos por RAM (descendente)
	sortedByRAM := captura.SortByRAM()

	// Contar contenedores de cada tipo que podemos eliminar
	lowCount := len(classified["low"])
	highCount := len(classified["high"])

	// Estrategia: eliminar del tipo que está por encima del mínimo
	canDeleteFromLow := lowCount - a.cfg.MinLowConsumption
	canDeleteFromHigh := highCount - a.cfg.MinHighConsumption

	a.logger.Debug("Capacidad de eliminación",
		"de_bajo_consumo", canDeleteFromLow,
		"de_alto_consumo", canDeleteFromHigh)

	// Intentar eliminar contenedores de alto consumo primero
	var deletedCount int

	for _, proc := range sortedByRAM {
		// Solo considerar procesos que son contenedores Docker reales
		// (deben tener el prefijo "container:" del módulo kernel)
		if !strings.Contains(proc.ComandoID, "container:") {
			continue
		}

		// Verificar que sea un contenedor Docker real (no sandbox del navegador)
		if !a.isDockerContainer(proc.PID) {
			a.logger.Debug("Saltando: no es contenedor Docker", "pid", proc.PID, "nombre", proc.Nombre)
			continue
		}

		// No eliminar contenedores de infraestructura
		nombreLower := strings.ToLower(proc.Nombre)
		if strings.Contains(nombreLower, "grafana") ||
			strings.Contains(nombreLower, "valkey") ||
			strings.Contains(nombreLower, "redis") {
			a.logger.Debug("Saltando contenedor de infraestructura", "pid", proc.PID, "nombre", proc.Nombre)
			continue
		}

		// Si es de alto consumo y podemos eliminar
		if canDeleteFromHigh > 0 && a.isHighConsumptionContainer(&proc) {
			toDelete = append(toDelete, proc.PID)
			canDeleteFromHigh--
			deletedCount++
			a.logger.Info("Marcado para eliminación (alto consumo)", 
				"pid", proc.PID,
				"nombre", proc.Nombre,
				"ram_pct", fmt.Sprintf("%.2f%%", proc.PorcentajeRAM))
		}

		// Si quedó capacidad para eliminar bajo consumo
		if canDeleteFromLow > 0 && !a.isHighConsumptionContainer(&proc) {
			toDelete = append(toDelete, proc.PID)
			canDeleteFromLow--
			deletedCount++
			a.logger.Info("Marcado para eliminación (bajo consumo)", 
				"pid", proc.PID,
				"nombre", proc.Nombre,
				"ram_pct", fmt.Sprintf("%.2f%%", proc.PorcentajeRAM))
		}

		// Limitar a no más de 5 eliminaciones por iteración
		if deletedCount >= 5 {
			break
		}
	}

	return toDelete
}

// isHighConsumptionContainer detecta si es contenedor de alto consumo
func (a *Analyzer) isHighConsumptionContainer(proc *parser.Proceso) bool {
	// Alto consumo: RAM > 10% o CPU > 50%
	return proc.PorcentajeRAM > 10.0 || proc.CPU > 50
}

// isDockerContainer verifica si un PID pertenece a un contenedor Docker real
// (no a un proceso sandbox del navegador u otro proceso con namespace propio)
func (a *Analyzer) isDockerContainer(pid int) bool {
	// Verificar que el cgroup del proceso contenga "docker"
	cgroupFile := fmt.Sprintf("/proc/%d/cgroup", pid)
	cmd := exec.Command("grep", "-q", "docker", cgroupFile)
	if err := cmd.Run(); err == nil {
		return true
	}
	// También verificar por containerd
	cmd = exec.Command("grep", "-q", "containerd", cgroupFile)
	return cmd.Run() == nil
}

// getDockerContainers obtiene lista de contenedores Docker activos
func (a *Analyzer) getDockerContainers() ([]string, error) {
	cmd := exec.Command("docker", "ps", "--format", "table {{.ID}}\t{{.Image}}\t{{.Status}}")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var containers []string
	lines := strings.Split(string(output), "\n")
	
	for i, line := range lines {
		if i == 0 || strings.TrimSpace(line) == "" {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) > 0 {
			containers = append(containers, fields[0])
		}
	}

	return containers, nil
}

// classifyContainers clasifica contenedores por tipo
func (a *Analyzer) classifyContainers(containers []string) map[string][]string {
	classified := map[string][]string{
		"low":     {},
		"high":    {},
		"grafana": {},
	}

	for _, containerID := range containers {
		// Obtener información del contenedor
		cmd := exec.Command("docker", "inspect", containerID, "--format", "{{.Config.Image}}")
		output, err := cmd.Output()
		if err != nil {
			continue
		}

		imageName := strings.TrimSpace(string(output))

		if strings.Contains(imageName, "grafana") {
			classified["grafana"] = append(classified["grafana"], containerID)
		} else if strings.Contains(imageName, "go-client") {
			classified["high"] = append(classified["high"], containerID)
		} else if strings.Contains(imageName, "alpine") {
			// Alpine puede ser bajo o alto consumo, asumimos bajo por defecto
			classified["low"] = append(classified["low"], containerID)
		} else {
			classified["high"] = append(classified["high"], containerID)
		}
	}

	return classified
}

// DeleteContainer elimina un contenedor especificado
func (a *Analyzer) DeleteContainer(containerID string) error {
	a.logger.Info("Eliminando contenedor", "id", containerID)

	cmd := exec.Command("docker", "stop", containerID)
	if err := cmd.Run(); err != nil {
		a.logger.Error("Error deteniendo contenedor", "id", containerID, "error", err)
		return err
	}

	cmd = exec.Command("docker", "rm", containerID)
	if err := cmd.Run(); err != nil {
		a.logger.Error("Error removiendo contenedor", "id", containerID, "error", err)
		return err
	}

	a.logger.Info("Contenedor eliminado correctamente", "id", containerID)
	return nil
}

// GetContainerIDByPID obtiene el Docker ID de un contenedor por PID del kernel
func (a *Analyzer) GetContainerIDByPID(pid int) (string, error) {
	// En cgroup v2 el formato es: 0::/system.slice/docker-{ID}.scope
	cgroupFile := fmt.Sprintf("/proc/%d/cgroup", pid)
	cmd := exec.Command("grep", "docker", cgroupFile)
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}

	// Extraer ID del contenedor de la línea de cgroup v2
	line := strings.TrimSpace(string(output))
	parts := strings.Split(line, "/")

	if len(parts) > 0 {
		lastPart := parts[len(parts)-1]
		// Formato cgroup v2: "docker-{64hexchars}.scope"
		// Quitar prefijo "docker-" y sufijo ".scope"
		lastPart = strings.TrimPrefix(lastPart, "docker-")
		lastPart = strings.TrimSuffix(lastPart, ".scope")
		if len(lastPart) >= 12 {
			return lastPart[:12], nil // Retornar primeros 12 caracteres del ID
		}
	}

	return "", fmt.Errorf("no se pudo extraer container ID del PID %d", pid)
}

// GenerateReport genera un reporte del análisis
func (a *Analyzer) GenerateReport(captura *parser.CapturaTelemetria, deleted []int) map[string]interface{} {
	report := map[string]interface{}{
		"timestamp":            captura.Timestamp,
		"total_procesos":       len(captura.Procesos),
		"memoria_total":        captura.Memoria.TotalRAM,
		"memoria_usada":        captura.Memoria.UsoRAM,
		"memoria_libre":        captura.Memoria.LibreRAM,
		"ram_usage_pct":        float64(captura.Memoria.UsoRAM) / float64(captura.Memoria.TotalRAM) * 100,
		"contenedores_eliminados": len(deleted),
		"ids_eliminados":       deleted,
	}

	return report
}
