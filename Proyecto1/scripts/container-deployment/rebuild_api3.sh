#!/bin/bash
set -e

USER="carlos"
VM2_IP="192.168.122.20"
IMAGE_DIR="images"

echo "=== RECONSTRUYENDO API3 CON FIX ==="

# 1. Backup del main.go original
echo "[1/6] Haciendo backup del main.go original..."
cp api-services/API3/main.go api-services/API3/main.go.backup

# 2. Usar el código corregido
echo "[2/6] Aplicando código corregido..."
cat > api-services/API3/main.go << 'GOCODE'
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

const (
	CARNET     = "202300625"
	CURRENT_VM = "VM2"
	API_NAME   = "API3"
	PORT       = ":8083"
	URL_API1   = "http://192.168.122.10:8081/health"
	URL_API2   = "http://192.168.122.10:8082/health"
)

// Cliente HTTP con timeout
var httpClient = &http.Client{
	Timeout: 10 * time.Second,
	Transport: &http.Transport{
		MaxIdleConns:       10,
		IdleConnTimeout:    30 * time.Second,
		DisableCompression: true,
	},
}

type HealthResponse struct {
	Status    string `json:"status"`
	Message   string `json:"message"`
	Timestamp string `json:"timestamp"`
	VM        string `json:"VM"`
	Carnet    string `json:"carnet"`
}

type CallResponse struct {
	ApiName    string `json:"apiname"`
	Message    string `json:"message"`
	Connection bool   `json:"connection"`
	Carnet     string `json:"carnet"`
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc(fmt.Sprintf("/api3/%s/call-api1", CARNET), callApi1Handler)
	http.HandleFunc(fmt.Sprintf("/api3/%s/call-api2", CARNET), callApi2Handler)

	fmt.Printf("[INICIO] %s en %s puerto %s\n", API_NAME, CURRENT_VM, PORT)
	fmt.Printf("[CONFIG] API1=%s\n", URL_API1)
	fmt.Printf("[CONFIG] API2=%s\n", URL_API2)

	if err := http.ListenAndServe(PORT, nil); err != nil {
		fmt.Printf("[ERROR] Servidor falló: %s\n", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := HealthResponse{
		Status:    "UP",
		Message:   "API3 is Ready",
		Timestamp: time.Now().Format("2006-01-02 15:04:05"),
		VM:        CURRENT_VM,
		Carnet:    CARNET,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func callApi1Handler(w http.ResponseWriter, r *http.Request) {
	handleRemoteCall(w, "API1", "VM1", URL_API1)
}

func callApi2Handler(w http.ResponseWriter, r *http.Request) {
	handleRemoteCall(w, "API2", "VM1", URL_API2)
}

func handleRemoteCall(w http.ResponseWriter, targetApiName, targetVM, targetURL string) {
	w.Header().Set("Content-Type", "application/json")

	fmt.Printf("[%s] → Llamando %s en %s\n", time.Now().Format("15:04:05"), targetApiName, targetURL)

	// Crear request
	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		fmt.Printf("[%s] ✗ Error creando request: %v\n", time.Now().Format("15:04:05"), err)
		sendFailResponse(w, targetApiName, targetVM)
		return
	}

	// Ejecutar request
	resp, err := httpClient.Do(req)
	if err != nil {
		fmt.Printf("[%s] ✗ Error de conexión: %v\n", time.Now().Format("15:04:05"), err)
		sendFailResponse(w, targetApiName, targetVM)
		return
	}
	defer resp.Body.Close()

	// Verificar status code
	if resp.StatusCode != http.StatusOK {
		fmt.Printf("[%s] ✗ Status code: %d\n", time.Now().Format("15:04:05"), resp.StatusCode)
		sendFailResponse(w, targetApiName, targetVM)
		return
	}

	// Leer body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("[%s] ✗ Error leyendo body: %v\n", time.Now().Format("15:04:05"), err)
		sendFailResponse(w, targetApiName, targetVM)
		return
	}

	// Parsear JSON
	var healthResp HealthResponse
	if err := json.Unmarshal(body, &healthResp); err != nil {
		fmt.Printf("[%s] ✗ Error parseando JSON: %v (body: %s)\n", time.Now().Format("15:04:05"), err, string(body))
		sendFailResponse(w, targetApiName, targetVM)
		return
	}

	// Verificar status
	if healthResp.Status == "UP" {
		fmt.Printf("[%s] ✓ %s está UP\n", time.Now().Format("15:04:05"), targetApiName)
		successResponse := CallResponse{
			ApiName:    targetApiName,
			Message:    fmt.Sprintf("The %s located on the %s is working", targetApiName, targetVM),
			Connection: true,
			Carnet:     CARNET,
		}
		json.NewEncoder(w).Encode(successResponse)
	} else {
		fmt.Printf("[%s] ✗ Status inesperado: %s\n", time.Now().Format("15:04:05"), healthResp.Status)
		sendFailResponse(w, targetApiName, targetVM)
	}
}

func sendFailResponse(w http.ResponseWriter, targetApiName, targetVM string) {
	failResponse := CallResponse{
		ApiName:    targetApiName,
		Message:    fmt.Sprintf("ERROR: The %s located on the %s is not working", targetApiName, targetVM),
		Connection: false,
		Carnet:     CARNET,
	}
	json.NewEncoder(w).Encode(failResponse)
}
GOCODE

# 3. Recompilar
echo "[3/6] Recompilando API3..."
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o api-services/API3/api3-bin api-services/API3/main.go

# 4. Rebuild Docker
echo "[4/6] Reconstruyendo imagen Docker..."
sudo docker build -t api3-202300625 -f api-services/dockerfiles/Dockerfile --build-arg BIN_PATH=api-services/API3/api3-bin .
sudo docker save api3-202300625 > $IMAGE_DIR/api3.tar

# 5. Transfer y Deploy
echo "[5/6] Transfiriendo a VM2..."
scp $IMAGE_DIR/api3.tar $USER@$VM2_IP:/home/$USER/

echo "[6/6] Desplegando en VM2..."
ssh -tt $USER@$VM2_IP << 'EOF'
    sudo ctr images import api3.tar
    
    echo "Deteniendo contenedor anterior..."
    sudo ctr tasks kill -s SIGKILL api3_service 2>/dev/null || true
    sleep 2
    sudo ctr containers delete api3_service 2>/dev/null || true
    
    echo "Iniciando nuevo contenedor..."
    sudo ctr run -d --net-host docker.io/library/api3-202300625:latest api3_service
    
    sleep 3
    echo ""
    echo "Estado de contenedores:"
    sudo ctr tasks ls
    
    echo ""
    echo "Verificando que API3 responde:"
    nc -zv localhost 8083 2>&1 || echo "Puerto 8083 no responde aún"
EOF

echo ""
echo "=== RECONSTRUCCIÓN COMPLETA ==="
echo ""
echo "Ahora ejecuta: scripts/test_workflow.sh"
