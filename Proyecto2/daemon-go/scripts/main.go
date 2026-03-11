package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"
)

// Representa la informacion global de RAM del sistema
type MemoriaGlobal struct {
	TotalRAM int64
	LibreRAM int64
	UsoRAM   int64
}

// Representa un proceso individual o contenedor leido desde el kernel
type Proceso struct {
	PID           int
	Nombre        string
	VSZ           int64 // Tamaño de memoria virtual en KB
	RSS           int64 // Memoria fisica residente en KB
	PorcentajeRAM float64
	CPU           int64
}

// Representa la captura completa de un instante (para enviar a Valkey)
type CapturaTelemetria struct {
	Timestamp int64
	Memoria   MemoriaGlobal
	Procesos  []Proceso
}

func main() {
	fmt.Println("Iniciando Daemon Gestor de Contenedores...")

	// 1. Inicialización
	iniciarInfraestructura()
	iniciarCronjob()
	cargarModuloKernel()

	// 2. Configurar el apagado seguro (Graceful Shutdown)
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	// 3. Configurar el Loop Principal (ej. cada 30 segundos)
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	// Goroutine principal
	go func() {
		for {
			select {
			case <-ticker.C:
				fmt.Println("--- Ejecutando iteracion de monitoreo ---")
				// A. Leer y parsear /proc
				// B. Guardar en Valkey
				// C. Analizar y aplicar reglas de eliminacion
			}
		}
	}()

	// Esperar señal de interrupción (Ctrl+C)
	<-c
	fmt.Println("\nApagando servicio...")
	
	// 4. Finalización del servicio
	limpiarCronjob()
	
	fmt.Println("Servicio finalizado correctamente.")
}

func iniciarInfraestructura() {
	fmt.Println("Levantando contenedores de Grafana y Valkey...")
	cmd := exec.Command("docker-compose", "up", "-d")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		fmt.Printf("Error al iniciar la infraestructura: %v\n", err)
	}
}

func iniciarCronjob() {
	// TODO: Ejecutar script para agregar cronjob
}

func cargarModuloKernel() {
	// TODO: Ejecutar script para cargar el .ko
}

func limpiarCronjob() {
	// TODO: Eliminar el cronjob del sistema
	fmt.Println("Cronjob eliminado del sistema.")
}