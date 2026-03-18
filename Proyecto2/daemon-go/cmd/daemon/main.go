package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"proyecto2-daemon-202300625/internal/config"
	"proyecto2-daemon-202300625/internal/logger"
	"proyecto2-daemon-202300625/internal/orchestrator"
	"proyecto2-daemon-202300625/internal/storage"
)

const VERSION = "1.0.0"

func main() {
	// Crear canal para manejo de señales
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, SIGTERM)

	// Crear canal para parar el daemon
	stopChan := make(chan struct{})

	// Cargar configuración
	cfg := config.LoadConfig()

	// Inicializar logger
	log, err := logger.NewLogger(logger.INFO, "")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error inicializando logger: %v\n", err)
		os.Exit(1)
	}
	defer log.Close()

	log.Info("╔════════════════════════════════════════════╗")
	log.Info("║  DAEMON GESTOR DE CONTENEDORES   ║")
	log.Info("║  Proyecto 2: SO1 Carnet: 202300625        ║")
	log.Info("║  Versión: " + VERSION + "                        ║")
	log.Info("╚════════════════════════════════════════════╝")

	// Conectar a Valkey
	log.Info("Conectando a Valkey...")
	valkeyClient, err := storage.NewValkeyClient(cfg.ValkeyHost, cfg.ValkeyPort)
	if err != nil {
		log.Fatal("No se pudo conectar a Valkey", "error", err)
	}
	defer valkeyClient.Close()

	// Crear orquestrador
	orch := orchestrator.NewOrchestrator(cfg, log, valkeyClient)

	// Inicializar
	if err := orch.Initialize(); err != nil {
		log.Fatal("Error en inicialización", "error", err)
	}

	// Goroutine para el loop principal
	go func() {
		if err := orch.Run(stopChan); err != nil {
			log.Error("Error en loop principal", "error", err)
			sigChan <- syscall.SIGINT
		}
	}()

	// Esperar por señal de interrupción
	sig := <-sigChan
	log.Info("Señal recibida", "señal", sig)

	// Enviar señal de parada
	close(stopChan)

	// Dar tiempo para que finalice el loop
	<-sigChan

	// Cleanup
	if err := orch.Cleanup(); err != nil {
		log.Error("Error en limpieza", "error", err)
	}

	log.Info("Daemon finalizado")
}

// Nota: En Linux, SIGTERM es 15
const SIGTERM = syscall.SIGTERM
