package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

// CONSTANTES A CONFIGURAR POR EL ESTUDIANTE
const (
	CARNET     = "202300625"
	CURRENT_VM = "VM1"
	API_NAME   = "API1"
	PORT       = ":8081"

	// Direcciones de las otras APIs
	URL_API2 = "http://localhost:8082/health"
	URL_API3 = "http://192.168.122.22:8080/health"
)

// Estructura para respuesta /health
type HealthResponse struct {
	Status    string `json:"status"`
	Message   string `json:"message"`
	Timestamp string `json:"timestamp"`
	VM        string `json:"VM"`
	Carnet    string `json:"carnet"`
}

// Estructura para respuesta de llamadas
type CallResponse struct {
	ApiName    string `json:"apiname"`
	Message    string `json:"message"`
	Connection bool   `json:"connection"`
	Carnet     string `json:"carnet"`
}

func main() {
	http.HandleFunc("/health", healthHandler)
	// Definición de endpoints dinámicos
	http.HandleFunc(fmt.Sprintf("/api1/%s/call-api2", CARNET), callApi2Handler)
	http.HandleFunc(fmt.Sprintf("/api1/%s/call-api3", CARNET), callApi3Handler)

	fmt.Printf("Iniciando %s en el puerto %s...\n", API_NAME, PORT)
	if err := http.ListenAndServe(PORT, nil); err != nil {
		fmt.Printf("Error iniciando servidor: %s\n", err)
	}
}

// Handler para GET /health
func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := HealthResponse{
		Status:    "UP",
		Message:   "API1 is Ready",
		Timestamp: time.Now().Format("2006-01-02 15:04:05"),
		VM:        CURRENT_VM,
		Carnet:    CARNET,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Handler para llamar a API 2
func callApi2Handler(w http.ResponseWriter, r *http.Request) {
	handleRemoteCall(w, "API2", "VM1", URL_API2)
}

// Handler para llamar a API 3
func callApi3Handler(w http.ResponseWriter, r *http.Request) {
	handleRemoteCall(w, "API3", "VM2", URL_API3)
}

// Función auxiliar para realizar la petición HTTP a la otra API
func handleRemoteCall(w http.ResponseWriter, targetApiName, targetVM, targetURL string) {
	w.Header().Set("Content-Type", "application/json")

	// Realizar la petición GET al endpoint /health de la API destino
	resp, err := http.Get(targetURL)

	// Caso de Error o Falla de Conexión
	if err != nil || resp.StatusCode != http.StatusOK {
		failResponse := CallResponse{
			ApiName:    targetApiName,
			Message:    fmt.Sprintf("ERROR: The %s located on the %s is not working", targetApiName, targetVM),
			Connection: false,
			Carnet:     CARNET,
		}
		json.NewEncoder(w).Encode(failResponse)
		return
	}
	defer resp.Body.Close()

	// Leer respuesta para asegurar que el status sea UP
	body, _ := ioutil.ReadAll(resp.Body)
	var healthResp HealthResponse
	json.Unmarshal(body, &healthResp)

	if healthResp.Status == "UP" {
		// Caso de Éxito
		successResponse := CallResponse{
			ApiName:    targetApiName,
			Message:    fmt.Sprintf("The %s located on the %s is working", targetApiName, targetVM),
			Connection: true,
			Carnet:     CARNET,
		}
		json.NewEncoder(w).Encode(successResponse)
	} else {
		// Si responde pero el status no es UP
		failResponse := CallResponse{
			ApiName:    targetApiName,
			Message:    fmt.Sprintf("ERROR: The %s located on the %s is not working", targetApiName, targetVM),
			Connection: false,
			Carnet:     CARNET,
		}
		json.NewEncoder(w).Encode(failResponse)
	}
}
