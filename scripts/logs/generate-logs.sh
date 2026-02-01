#!/bin/bash

# Script para generar logs de pruebas de APIs
# Fecha: $(date +"%Y-%m-%d %H:%M:%S")

LOGS_DIR="../logs"
CARNET="202300625"

# Crear directorio de logs si no existe
mkdir -p "$LOGS_DIR"

echo "======================================"
echo "Generando logs de pruebas..."
echo "======================================"
echo ""

# Función para realizar petición y guardar log
test_endpoint() {
    local name=$1
    local url=$2
    local log_file="$LOGS_DIR/$3"
    
    echo "Probando: $name"
    echo "URL: $url"
    echo "Guardando en: $log_file"
    
    {
        echo "========================================="
        echo "Prueba: $name"
        echo "URL: $url"
        echo "Fecha: $(date +"%Y-%m-%d %H:%M:%S")"
        echo "========================================="
        echo ""
        
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" "$url" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "RESPUESTA:"
            echo "$response" | grep -v "HTTP_STATUS"
            echo ""
            status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
            echo "Código HTTP: $status"
        else
            echo "ERROR: No se pudo conectar al endpoint"
            echo "Connection: false"
        fi
        
        echo ""
        echo "========================================="
    } > "$log_file"
    
    echo "✓ Log guardado"
    echo ""
}

# 1. Pruebas de /health
echo "=== 1. Probando endpoints /health ==="
echo ""

test_endpoint \
    "API1 Health Check" \
    "http://192.168.122.10:8081/health" \
    "api1-health.log"

test_endpoint \
    "API2 Health Check" \
    "http://192.168.122.10:8082/health" \
    "api2-health.log"

test_endpoint \
    "API3 Health Check" \
    "http://192.168.122.20:8083/health" \
    "api3-health.log"

# 2. Pruebas de comunicación entre APIs
echo "=== 2. Probando comunicación entre APIs ==="
echo ""

test_endpoint \
    "API2 llama a API1" \
    "http://192.168.122.10:8082/api2/$CARNET/call-api1" \
    "api2-call-api1-ok.log"

test_endpoint \
    "API1 llama a API3" \
    "http://192.168.122.10:8081/api1/$CARNET/call-api3" \
    "api1-call-api3-ok.log"

test_endpoint \
    "API3 llama a API2" \
    "http://192.168.122.20:8083/api3/$CARNET/call-api2" \
    "api3-call-api2-ok.log"

test_endpoint \
    "API1 llama a API2" \
    "http://192.168.122.10:8081/api1/$CARNET/call-api2" \
    "api1-call-api2-ok.log"

test_endpoint \
    "API2 llama a API3" \
    "http://192.168.122.10:8082/api2/$CARNET/call-api3" \
    "api2-call-api3-ok.log"

test_endpoint \
    "API3 llama a API1" \
    "http://192.168.122.20:8083/api3/$CARNET/call-api1" \
    "api3-call-api1-ok.log"

# 3. Generar resumen
echo "=== 3. Generando resumen ==="
echo ""

{
    echo "========================================="
    echo "RESUMEN DE PRUEBAS - APIs LAB SO1"
    echo "Carnet: $CARNET"
    echo "Fecha: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "========================================="
    echo ""
    echo "LOGS GENERADOS:"
    echo ""
    ls -lh "$LOGS_DIR"/*.log 2>/dev/null
    echo ""
    echo "========================================="
    echo "Total de archivos: $(ls -1 "$LOGS_DIR"/*.log 2>/dev/null | wc -l)"
    echo "========================================="
} > "$LOGS_DIR/resumen.log"

echo "✓ Resumen guardado en $LOGS_DIR/resumen.log"
echo ""
echo "======================================"
echo "¡Logs generados exitosamente!"
echo "Revisa la carpeta: $LOGS_DIR"
echo "======================================"
