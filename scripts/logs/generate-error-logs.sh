#!/bin/bash

# Script para generar logs de pruebas de error
# Simula cuando una API está caída

LOGS_DIR="../logs"
CARNET="202300625"

mkdir -p "$LOGS_DIR"

echo "======================================"
echo "Generando logs de pruebas de ERROR"
echo "======================================"
echo ""

# Función para simular error cuando API está caída
test_error_endpoint() {
    local name=$1
    local url=$2
    local log_file="$LOGS_DIR/$3"
    
    echo "Probando: $name (API caída)"
    echo "URL: $url"
    echo "Guardando en: $log_file"
    
    {
        echo "========================================="
        echo "Prueba: $name (Escenario de Error)"
        echo "URL: $url"
        echo "Fecha: $(date +"%Y-%m-%d %H:%M:%S")"
        echo "Descripción: API destino detenida/inaccesible"
        echo "========================================="
        echo ""
        
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" --connect-timeout 5 "$url" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "RESPUESTA:"
            echo "$response" | grep -v "HTTP_STATUS"
            echo ""
            status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
            echo "Código HTTP: $status"
        else
            echo "ERROR: No se pudo conectar - API caída"
            echo ""
            echo "RESPUESTA ESPERADA:"
            echo '{'
            echo '  "apiname": "API destino",'
            echo '  "message": "Error al conectar con la API",'
            echo '  "connection": false,'
            echo '  "carnet": "'$CARNET'"'
            echo '}'
        fi
        
        echo ""
        echo "========================================="
    } > "$log_file"
    
    echo "✓ Log de error guardado"
    echo ""
}

echo "=== Pruebas de Manejo de Errores ==="
echo ""
echo "INSTRUCCIONES:"
echo "1. Detén una API en su VM correspondiente"
echo "2. Ejecuta este script para documentar el error"
echo ""
echo "Ejemplos de escenarios:"
echo ""

# Ejemplo 1: API3 caída
test_error_endpoint \
    "API1 -> API3 (API3 detenida)" \
    "http://192.168.122.10:8081/api1/$CARNET/call-api3" \
    "api1-call-api3-error.log"

# Ejemplo 2: API1 caída
test_error_endpoint \
    "API2 -> API1 (API1 detenida)" \
    "http://192.168.122.10:8082/api2/$CARNET/call-api1" \
    "api2-call-api1-error.log"

# Ejemplo 3: API2 caída
test_error_endpoint \
    "API3 -> API2 (API2 detenida)" \
    "http://192.168.122.20:8083/api3/$CARNET/call-api2" \
    "api3-call-api2-error.log"

echo "======================================"
echo "Logs de error generados"
echo "======================================"
echo ""
echo "NOTA: Para obtener logs reales con connection:false,"
echo "ejecuta las pruebas con las APIs realmente detenidas."
echo ""
echo "Pasos sugeridos:"
echo "1. SSH a la VM correspondiente"
echo "2. Detén el contenedor/servicio de la API"
echo "3. Ejecuta el endpoint desde otra API"
echo "4. Guarda la respuesta JSON con connection:false"
echo ""
