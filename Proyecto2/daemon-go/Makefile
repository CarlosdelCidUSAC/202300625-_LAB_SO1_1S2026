.PHONY: build run clean help test lint install-deps

# Variables
GO := go
BINARY_NAME := daemon-so1
BINARY_PATH := ./cmd/daemon/main.go
OUTPUT_DIR := ./bin
VERSION := 1.0.0
CARNET := 202300625

# Rutas
BUILDFLAGS := -ldflags "-X main.VERSION=$(VERSION)"
GOFLAGS := -v

help: ## Mostrar esta ayuda
	@echo "╔════════════════════════════════════════════╗"
	@echo "║         DAEMON SO1 - FASE 4                ║"
	@echo "║  Gestor de Contenedores en Go              ║"
	@echo "╚════════════════════════════════════════════╝"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

install-deps: ## Instalar dependencias de Go
	@echo "Instalando dependencias..."
	$(GO) mod download
	$(GO) mod tidy
	@echo "✓ Dependencias instaladas"

build: clean install-deps ## Compilar el daemon
	@echo "Compilando daemon..."
	@mkdir -p $(OUTPUT_DIR)
	$(GO) build $(GOFLAGS) $(BUILDFLAGS) -o $(OUTPUT_DIR)/$(BINARY_NAME) $(BINARY_PATH)
	@chmod +x $(OUTPUT_DIR)/$(BINARY_NAME)
	@echo "✓ Binary creado: $(OUTPUT_DIR)/$(BINARY_NAME)"
	@ls -lh $(OUTPUT_DIR)/$(BINARY_NAME)

run: build ## Compilar y ejecutar el daemon
	@echo "Ejecutando daemon..."
	@sudo $(OUTPUT_DIR)/$(BINARY_NAME)

run-debug: clean install-deps ## Compilar en debug y ejecutar
	@echo "Compilando en modo debug..."
	@mkdir -p $(OUTPUT_DIR)
	$(GO) build -gcflags="all=-N -l" -o $(OUTPUT_DIR)/$(BINARY_NAME)-debug $(BINARY_PATH)
	@echo "Ejecutando en debug..."
	@sudo $(OUTPUT_DIR)/$(BINARY_NAME)-debug

test: install-deps ## Ejecutar tests
	@echo "Ejecutando tests..."
	$(GO) test ./... -v

lint: ## Verificar código
	@echo "Verificando código..."
	@which golangci-lint > /dev/null || (echo "golangci-lint no instalado"; exit 1)
	golangci-lint run ./...

clean: ## Limpiar compilados
	@echo "Limpiando..."
	@rm -rf $(OUTPUT_DIR)
	@rm -f go.sum
	@echo "✓ Limpieza completada"

fmt: ## Formatear código
	@echo "Formateando código..."
	$(GO) fmt ./...
	@echo "✓ Código formateado"

vet: ## Ejecutar go vet
	@echo "Ejecutando go vet..."
	$(GO) vet ./...
	@echo "✓ Go vet completado"

docker-build: build ## Crear imagen Docker del daemon
	@echo "Creando imagen Docker..."
	docker build -t daemon-so1:$(VERSION) .
	@echo "✓ Imagen creada"

docker-run: docker-build ## Ejecutar daemon en contenedor
	@echo "Ejecutando daemon en contenedor..."
	docker run -d --name daemon-fase4 daemon-so1:$(VERSION)

.DEFAULT_GOAL := help
