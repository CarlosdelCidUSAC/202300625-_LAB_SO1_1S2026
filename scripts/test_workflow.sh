#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== INICIANDO TEST DE INTEGRACIÓN (Puertos Actualizados) ==="

CARNET="202300625"
VM1_IP="192.168.122.10"
VM2_IP="192.168.122.20"

# --- PUERTOS DEFINIDOS EN TU MAIN.GO ---
PORT_API1="8081"
PORT_API2="8082"
PORT_API3="8083"

URL_API1="http://$VM1_IP:$PORT_API1"
URL_API2="http://$VM1_IP:$PORT_API2"
URL_API3="http://$VM2_IP:$PORT_API3"

validate_response() {
    endpoint=$1
    description=$2
    echo -n "Probando: $description... "
    response=$(curl -s --connect-timeout 5 "$endpoint")
    
    if [ -z "$response" ]; then
        echo -e "${RED}[FALLÓ] Sin respuesta${NC} ($endpoint)"
        return 1
    fi

    # Busca éxito en connection (true) o status (UP) ignorando espacios
    if echo "$response" | grep -q '"connection"[[:space:]]*:[[:space:]]*true'; then
        echo -e "${GREEN}[ÉXITO]${NC} Respuesta OK"
    elif echo "$response" | grep -q '"status"[[:space:]]*:[[:space:]]*"UP"'; then
        echo -e "${GREEN}[ÉXITO]${NC} Status UP"
    else
        echo -e "${RED}[ERROR]${NC} Respuesta inesperada: $response"
    fi
}

echo ""
echo "--- 1. Health Checks ---"
validate_response "$URL_API1/health" "API 1 (:8081)"
validate_response "$URL_API2/health" "API 2 (:8082)"
validate_response "$URL_API3/health" "API 3 (:8083)"

echo ""
echo "--- 2. Comunicación Cruzada ---"
validate_response "$URL_API2/api2/$CARNET/call-api1" "API 2 -> API 1"
validate_response "$URL_API1/api1/$CARNET/call-api3" "API 1 -> API 3"
validate_response "$URL_API3/api3/$CARNET/call-api2" "API 3 -> API 2"