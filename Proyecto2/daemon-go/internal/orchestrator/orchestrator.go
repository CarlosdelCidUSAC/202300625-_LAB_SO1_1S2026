package orchestrator

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"proyecto2-daemon-202300625/internal/analyzer"
	"proyecto2-daemon-202300625/internal/config"
	"proyecto2-daemon-202300625/internal/logger"
	"proyecto2-daemon-202300625/internal/parser"
	"proyecto2-daemon-202300625/internal/storage"
)

// Orchestrator es el coordinador central del sistema
type Orchestrator struct {
	cfg       *config.Config
	logger    *logger.Logger
	valkey    *storage.ValkeyClient
	analyzer  *analyzer.Analyzer
	iterCount int
}

// NewOrchestrator crea una nueva instancia del orquestrador
func NewOrchestrator(cfg *config.Config, log *logger.Logger, 
	valkeyClient *storage.ValkeyClient) *Orchestrator {
	return &Orchestrator{
		cfg:       cfg,
		logger:    log,
		valkey:    valkeyClient,
		analyzer:  analyzer.NewAnalyzer(cfg, log),
		iterCount: 0,
	}
}

// Initialize realiza las tareas de inicialización
func (o *Orchestrator) Initialize() error {
	o.logger.Info("=== INICIALIZANDO DAEMON ===")
	o.logger.Info("Carnet: " + o.cfg.Carnet)

	// 1. Iniciar infraestructura (Docker Compose)
	if err := o.startInfrastructure(); err != nil {
		o.logger.Error("Error iniciando infraestructura", "error", err)
		return err
	}

	// 2. Cargar módulo del kernel
	if err := o.loadKernelModule(); err != nil {
		o.logger.Error("Error cargando módulo kernel", "error", err)
		// No es fatal, continuar
	}

	// 3. Instalar cronjob
	if err := o.installCronjob(); err != nil {
		o.logger.Error("Error instalando cronjob", "error", err)
		// No es fatal, continuar
	}

	// 4. Esperar a que Valkey esté listo
	o.logger.Info("Esperando conexión a Valkey...")
	for i := 0; i < 10; i++ {
		if err := o.valkey.Ping(); err == nil {
			o.logger.Info("✓ Conexión a Valkey establecida")
			break
		}
		o.logger.Debug("Reintentando conexión a Valkey", "intento", i+1)
		time.Sleep(2 * time.Second)
	}

	o.logger.Info("=== INICIALIZACIÓN COMPLETADA ===\n")
	return nil
}

// Run inicia el loop principal del daemon
func (o *Orchestrator) Run(stopChan <-chan struct{}) error {
	o.logger.Info("=== INICIANDO LOOP PRINCIPAL ===")
	o.logger.Info("Duracion de ciclo:", "segundos", o.cfg.CycleDuration.Seconds())

	ticker := time.NewTicker(o.cfg.CycleDuration)
	defer ticker.Stop()

	for {
		select {
		case <-stopChan:
			o.logger.Info("Señal de parada recibida")
			return nil

		case <-ticker.C:
			o.iterCount++
			o.logger.Info("=== ITERACIÓN DE MONITOREO ===", "numero", o.iterCount)

			// Ejecutar ciclo de monitoreo
			if err := o.executeCycle(); err != nil {
				o.logger.Error("Error en ciclo de monitoreo", "error", err)
			}

			// Verificar si hay límite de iteraciones
			if o.cfg.MaxIterations > 0 && o.iterCount >= o.cfg.MaxIterations {
				o.logger.Info("Límite de iteraciones alcanzado")
				return nil
			}
		}
	}
}

// executeCycle ejecuta un ciclo completo de monitoreo
func (o *Orchestrator) executeCycle() error {
	startTime := time.Now()

	// 1. Leer datos del módulo kernel
	captura, err := parser.ParseProcFile(o.cfg.ProcFile)
	if err != nil {
		o.logger.Error("Error parseando archivo /proc", "error", err)
		return err
	}

	o.logger.Info("Datos parseados correctamente",
		"procesos", len(captura.Procesos),
		"memoria_usada", captura.Memoria.UsoRAM)

	// 2. Almacenar telemetría en Valkey
	if err := o.valkey.StoreTelemetry(captura); err != nil {
		o.logger.Error("Error almacenando telemetría", "error", err)
	}

	// 3. Analizar y decidir
	toDelete, err := o.analyzer.AnalyzeAndDecide(captura)
	if err != nil {
		o.logger.Error("Error en análisis", "error", err)
	}

	// 4. Ejecutar decisiones (eliminar contenedores)
	if len(toDelete) > 0 {
		o.logger.Info("Ejecutando eliminación de contenedores", "cantidad", len(toDelete))
		for _, pid := range toDelete {
			containerID, err := o.analyzer.GetContainerIDByPID(pid)
			if err != nil {
				o.logger.Warn("Error obteniendo container ID del PID", "pid", pid, "error", err)
				continue
			}
			
			// Eliminar contenedor
			if err := o.analyzer.DeleteContainer(containerID); err != nil {
				o.logger.Error("Error eliminando contenedor", "container_id", containerID)
			} else {
				// Registrar en Valkey
				o.valkey.StoreDeletedContainer(int64(time.Now().Unix()), pid, 
					"container:"+containerID, "high_resource_usage")
			}
		}
	}

	// 5. Ir generar reporte
	report := o.analyzer.GenerateReport(captura, toDelete)
	o.logger.Info("Reporte de ciclo",
		"procesos", report["total_procesos"],
		"eliminados", report["contenedores_eliminados"],
		"ram_usage", fmt.Sprintf("%.2f%%", report["ram_usage_pct"]))

	elapsed := time.Since(startTime)
	o.logger.Debug("Ciclo completado", "duracion_ms", elapsed.Milliseconds())

	return nil
}

// startInfrastructure inicia los servicios de Docker Compose
func (o *Orchestrator) startInfrastructure() error {
	o.logger.Info("Iniciando infraestructura con Docker Compose...")

	composeFile := filepath.Join(o.cfg.DockerComposePath, o.cfg.DockerComposeFile)
	
	// Verificar que el archivo existe
	if _, err := os.Stat(composeFile); err != nil {
		return fmt.Errorf("archivo docker-compose no encontrado: %s", composeFile)
	}

	cmd := exec.Command("docker-compose", 
		"-f", composeFile, 
		"up", "-d")
	cmd.Dir = o.cfg.DockerComposePath
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("error ejecutando docker-compose: %v", err)
	}

	o.logger.Info("✓ Docker Compose iniciado")
	time.Sleep(3 * time.Second) // Esperar a que se inicie
	return nil
}

// loadKernelModule carga el módulo del kernel
func (o *Orchestrator) loadKernelModule() error {
	o.logger.Info("Cargando módulo del kernel...")

	// Intentar cargar el módulo
	cmd := exec.Command("sudo", "insmod", 
		"/home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko")
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		// Podría estar ya cargado
		o.logger.Warn("Módulo kernel", "archivo", string(output), "error", err)
		return nil
	}

	time.Sleep(1 * time.Second)
	o.logger.Info("✓ Módulo kernel cargado")
	return nil
}

// installCronjob instala el cronjob
func (o *Orchestrator) installCronjob() error {
	o.logger.Info("Instalando cronjob automático...")

	cmd := exec.Command("bash", o.cfg.CronInstall)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		o.logger.Warn("Error en instalación de cronjob", "output", string(output))
		return nil // No es fatal
	}

	o.logger.Info("✓ Cronjob instalado")
	return nil
}

// Cleanup realiza la limpieza al finalizar
func (o *Orchestrator) Cleanup() error {
	o.logger.Info("=== FINALIZANDO DAEMON ===")

	// 1. Desinstalar cronjob
	o.logger.Info("Desinstalando cronjob...")
	cmd := exec.Command("bash", o.cfg.CronUninstall)
	if err := cmd.Run(); err != nil {
		o.logger.Warn("Error desinstalando cronjob", "error", err)
	}

	// 2. Descargar módulo del kernel
	o.logger.Info("Descargando módulo del kernel...")
	cmd = exec.Command("sudo", "rmmod", "sonda")
	if err := cmd.Run(); err != nil {
		o.logger.Warn("Error descargando módulo kernel", "error", err)
	}

	// 3. Detener Docker Compose
	o.logger.Info("Deteniendo servicios...")
	composeFile := filepath.Join(o.cfg.DockerComposePath, o.cfg.DockerComposeFile)
	cmd = exec.Command("docker-compose", "-f", composeFile, "down")
	cmd.Dir = o.cfg.DockerComposePath
	if err := cmd.Run(); err != nil {
		o.logger.Warn("Error deteniendo docker-compose", "error", err)
	}

	// 4. Cerrar conexión a Valkey
	if err := o.valkey.Close(); err != nil {
		o.logger.Warn("Error cerrando conexión Valkey", "error", err)
	}

	o.logger.Info("=== DAEMON FINALIZADO ===")
	return nil
}

// GetStats retorna estadísticas del daemon
func (o *Orchestrator) GetStats() map[string]interface{} {
	stats, _ := o.valkey.GetStats()
	stats["iteraciones"] = o.iterCount
	return stats
}
