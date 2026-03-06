package parser

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// MemoriaGlobal estructura para los datos globales de memoria del sistema
type MemoriaGlobal struct {
	TotalRAM int64
	LibreRAM int64
	UsoRAM   int64
}

// Proceso estructura para un contenedor/proceso individual
type Proceso struct {
	PID           int
	Nombre        string
	VSZ           int64   // Tamaño de memoria virtual en KB
	RSS           int64   // Memoria física residente en KB
	PorcentajeRAM float64 // Porcentaje de RAM utilizada
	CPU           int64   // Porcentaje de CPU utilizado
	ComandoID     string  // ID del contenedor o línea de comando
}

// CapturaTelemetria estructura que agrupa una captura completa
type CapturaTelemetria struct {
	Timestamp int64
	Memoria   MemoriaGlobal
	Procesos  []Proceso
}

// ParseProcFile parsea el archivo /proc del módulo kernel
func ParseProcFile(filepath string) (*CapturaTelemetria, error) {
	file, err := os.Open(filepath)
	if err != nil {
		return nil, fmt.Errorf("error abriendo archivo %s: %v", filepath, err)
	}
	defer file.Close()

	captura := &CapturaTelemetria{
		Timestamp: int64(0),
		Procesos:  []Proceso{},
	}

	scanner := bufio.NewScanner(file)
	lineNum := 0
	inMemoriaSection := false
	inProcesosSection := false

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		lineNum++

		// Ignorar líneas vacías y comentarios
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Detectar secciones
		if strings.HasPrefix(line, "[MEMORIA]") {
			inMemoriaSection = true
			inProcesosSection = false
			continue
		}
		if strings.HasPrefix(line, "[PROCESOS]") {
			inMemoriaSection = false
			inProcesosSection = true
			continue
		}

		// Parsear sección de memoria
		if inMemoriaSection {
			if err := parseMemoriaLine(line, captura); err != nil {
				return nil, fmt.Errorf("error en línea %d: %v", lineNum, err)
			}
		}

		// Parsear sección de procesos
		if inProcesosSection {
			if strings.HasPrefix(line, "PID|Nombre|") {
				// Encabezado, ignorar
				continue
			}
			proceso, err := parseProcesoLine(line)
			if err != nil {
				return nil, fmt.Errorf("error parseando proceso en línea %d: %v", lineNum, err)
			}
			if proceso != nil {
				captura.Procesos = append(captura.Procesos, *proceso)
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("error leyendo archivo: %v", err)
	}

	// Si no hay procesos, podría ser un error
	if len(captura.Procesos) == 0 {
		return nil, fmt.Errorf("no se encontraron procesos en el archivo")
	}

	captura.Timestamp = int64(0) // Se puede mejorar con timestamp del kernel

	return captura, nil
}

// parseMemoriaLine parsea una línea de la sección MEMORIA
func parseMemoriaLine(line string, captura *CapturaTelemetria) error {
	parts := strings.Split(line, ":")
	if len(parts) != 2 {
		return nil // Ignorar líneas mal formadas
	}

	key := strings.TrimSpace(parts[0])
	value := strings.TrimSpace(parts[1])

	// Extraer solo el número (sin "KB" o "MB")
	valueStr := strings.FieldsFunc(value, func(r rune) bool {
		return r == ' ' || r == 'K' || r == 'B' || r == 'M'
	})
	if len(valueStr) == 0 {
		return nil
	}

	val, err := strconv.ParseInt(valueStr[0], 10, 64)
	if err != nil {
		return err
	}

	switch key {
	case "Total":
		captura.Memoria.TotalRAM = val
	case "Libre":
		captura.Memoria.LibreRAM = val
	case "Uso":
		captura.Memoria.UsoRAM = val
	}

	return nil
}

// parseProcesoLine parsea una línea de la sección PROCESOS
// Formato esperado: PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID
func parseProcesoLine(line string) (*Proceso, error) {
	parts := strings.Split(line, "|")
	if len(parts) < 7 {
		return nil, fmt.Errorf("formato de línea inválido: se esperaban 7 campos, se encontraron %d", len(parts))
	}

	pid, err := strconv.Atoi(strings.TrimSpace(parts[0]))
	if err != nil {
		return nil, fmt.Errorf("PID inválido: %v", err)
	}

	vsz, err := strconv.ParseInt(strings.TrimSpace(parts[2]), 10, 64)
	if err != nil {
		return nil, fmt.Errorf("VSZ inválido: %v", err)
	}

	rss, err := strconv.ParseInt(strings.TrimSpace(parts[3]), 10, 64)
	if err != nil {
		return nil, fmt.Errorf("RSS inválido: %v", err)
	}

	porcentajeRAM, err := strconv.ParseFloat(strings.TrimSpace(parts[4]), 64)
	if err != nil {
		return nil, fmt.Errorf("Porcentaje RAM inválido: %v", err)
	}

	cpu, err := strconv.ParseInt(strings.TrimSpace(parts[5]), 10, 64)
	if err != nil {
		return nil, fmt.Errorf("CPU inválido: %v", err)
	}

	return &Proceso{
		PID:           pid,
		Nombre:        strings.TrimSpace(parts[1]),
		VSZ:           vsz,
		RSS:           rss,
		PorcentajeRAM: porcentajeRAM,
		CPU:           cpu,
		ComandoID:     strings.TrimSpace(parts[6]),
	}, nil
}

// GetContainerProcesses filtra solo procesos de contenedores
func (cap *CapturaTelemetria) GetContainerProcesses() []Proceso {
	var containers []Proceso
	for _, proc := range cap.Procesos {
		// Un proceso es de contenedor si su ComandoID comienza con 'sha256:' o similar
		if strings.HasPrefix(proc.ComandoID, "sha256:") || 
		   strings.HasPrefix(proc.ComandoID, "docker") ||
		   strings.Contains(proc.ComandoID, "/docker/") {
			containers = append(containers, proc)
		}
	}
	return containers
}

// SortByRAM ordena los procesos por consumo de RAM (descendente)
func (cap *CapturaTelemetria) SortByRAM() []Proceso {
	procs := make([]Proceso, len(cap.Procesos))
	copy(procs, cap.Procesos)
	
	// Implementar quicksort simple por RAM
	for i := 0; i < len(procs)-1; i++ {
		for j := i + 1; j < len(procs); j++ {
			if procs[j].PorcentajeRAM > procs[i].PorcentajeRAM {
				procs[i], procs[j] = procs[j], procs[i]
			}
		}
	}
	return procs
}

// SortByCPU ordena los procesos por consumo de CPU (descendente)
func (cap *CapturaTelemetria) SortByCPU() []Proceso {
	procs := make([]Proceso, len(cap.Procesos))
	copy(procs, cap.Procesos)
	
	for i := 0; i < len(procs)-1; i++ {
		for j := i + 1; j < len(procs); j++ {
			if procs[j].CPU > procs[i].CPU {
				procs[i], procs[j] = procs[j], procs[i]
			}
		}
	}
	return procs
}
