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
	CARNET     = "202300625" // Reemplazar con tu carnet real
	CURRENT_VM = "VM1"
	API_NAME   = "API2"
	PORT       = ":8082"

	// Direcciones de las otras APIs
	URL_API1 = "http://localhost:8081/health"
	URL_API3 = "http://192.168.122.22:8080/health"
)

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
	// Definición de endpoints según tabla
	http.HandleFunc(fmt.Sprintf("/api2/%s/call-api1", CARNET), callApi1Handler)
	http.HandleFunc(fmt.Sprintf("/api2/%s/call-api3", CARNET), callApi3Handler)

	fmt.Printf("Iniciando %s en el puerto %s...\n", API_NAME, PORT)
	if err := http.ListenAndServe(PORT, nil); err != nil {
		fmt.Printf("Error iniciando servidor: %s\n", err)
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := HealthResponse{
		Status:    "UP",
		Message:   "API2 is Ready",
		Timestamp: time.Now().Format("2006-01-02 15:04:05"),
		VM:        CURRENT_VM,
		Carnet:    CARNET,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func callApi1Handler(w http.ResponseWriter, r *http.Request) {
	// Llama a API 1 ubicada en VM1
	handleRemoteCall(w, "API1", "VM1", URL_API1)
}

func callApi3Handler(w http.ResponseWriter, r *http.Request) {
	// Llama a API 3 ubicada en VM2
	handleRemoteCall(w, "API3", "VM2", URL_API3)
}

func handleRemoteCall(w http.ResponseWriter, targetApiName, targetVM, targetURL string) {
	w.Header().Set("Content-Type", "application/json")

	resp, err := http.Get(targetURL)

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

	body, _ := ioutil.ReadAll(resp.Body)
	var healthResp HealthResponse
	json.Unmarshal(body, &healthResp)

	if healthResp.Status == "UP" {
		successResponse := CallResponse{
			ApiName:    targetApiName,
			Message:    fmt.Sprintf("The %s located on the %s is working", targetApiName, targetVM),
			Connection: true,
			Carnet:     CARNET,
		}
		json.NewEncoder(w).Encode(successResponse)
	} else {
		failResponse := CallResponse{
			ApiName:    targetApiName,
			Message:    fmt.Sprintf("ERROR: The %s located on the %s is not working", targetApiName, targetVM),
			Connection: false,
			Carnet:     CARNET,
		}
		json.NewEncoder(w).Encode(failResponse)
	}
}
