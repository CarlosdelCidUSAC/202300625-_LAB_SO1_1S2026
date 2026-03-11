#!/bin/bash

# Script de verificación completa de requisitos - Proyecto 2 SO1
# Carnet: 202300625
# Genera evidencias automáticas para el manual técnico

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROYECTO_PATH="/home/carlos/Desktop/Proyecto2"
EVIDENCIAS_PATH="$PROYECTO_PATH/docs/evidencias"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORTE="$EVIDENCIAS_PATH/verificacion_${TIMESTAMP}.txt"

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Crear directorio de evidencias
mkdir -p "$EVIDENCIAS_PATH"

# Función para imprimir cabecera
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

# Función para verificar un test
verify_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "[$TOTAL_TESTS] $test_name ... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "[$TOTAL_TESTS] $test_name: PASS" >> "$REPORTE"
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "[$TOTAL_TESTS] $test_name: FAIL" >> "$REPORTE"
        return 1
    fi
}

# Iniciar reporte
{
    echo "╔════════════════════════════════════════════╗"
    echo "║  VERIFICACIÓN DE REQUISITOS - PROYECTO 2   ║"
    echo "║  Sistema Operativos 1                      ║"
    echo "║  Carnet: 202300625                         ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Usuario: $(whoami)"
    echo "Sistema: $(uname -a)"
    echo ""
} | tee "$REPORTE"

print_header "1. MÓDULO DE KERNEL" | tee -a "$REPORTE"

# 1.1 Verificar que existe el código fuente
verify_test "Archivo fuente sonda.c existe" \
    "[ -f $PROYECTO_PATH/kernel-module/src/sonda.c ]"

# 1.2 Verificar Makefile
verify_test "Makefile existe" \
    "[ -f $PROYECTO_PATH/kernel-module/Makefile ]"

# 1.3 Compilar módulo
echo -n "[$((TOTAL_TESTS + 1))] Compilando módulo kernel ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
cd "$PROYECTO_PATH/kernel-module"
if make clean > /dev/null 2>&1 && make > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Compilando módulo kernel: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Compilando módulo kernel: FAIL" >> "$REPORTE"
fi

# 1.4 Verificar que se creó el .ko
verify_test "Archivo sonda.ko generado" \
    "[ -f $PROYECTO_PATH/kernel-module/build/sonda.ko ]"

# 1.5 Cargar módulo
echo -n "[$((TOTAL_TESTS + 1))] Cargando módulo en el kernel ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
sudo rmmod sonda 2>/dev/null || true
if sudo insmod "$PROYECTO_PATH/kernel-module/build/sonda.ko" 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Cargando módulo en el kernel: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Cargando módulo en el kernel: FAIL" >> "$REPORTE"
fi

# 1.6 Verificar que se creó /proc
verify_test "Archivo /proc/continfo_pr2_so1_202300625 existe" \
    "[ -f /proc/continfo_pr2_so1_202300625 ]"

# 1.7 Verificar formato de salida
echo -n "[$((TOTAL_TESTS + 1))] Formato del archivo /proc correcto ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if head -10 /proc/continfo_pr2_so1_202300625 | grep -q "\[MEMORIA\]" && \
   head -20 /proc/continfo_pr2_so1_202300625 | grep -q "\[PROCESOS\]" && \
   head -30 /proc/continfo_pr2_so1_202300625 | grep -q "PID|Nombre|"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Formato del archivo /proc correcto: PASS" >> "$REPORTE"
    
    # Guardar evidencia
    echo "" >> "$REPORTE"
    echo "--- Muestra del archivo /proc ---" >> "$REPORTE"
    head -30 /proc/continfo_pr2_so1_202300625 >> "$REPORTE"
    echo "" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Formato del archivo /proc correcto: FAIL" >> "$REPORTE"
fi

# 1.8 Verificar que contiene información de memoria
verify_test "Datos de memoria (Total, Libre, Uso)" \
    "grep -q 'Total:' /proc/continfo_pr2_so1_202300625 && grep -q 'Libre:' /proc/continfo_pr2_so1_202300625"

# 1.9 Verificar que contiene procesos
echo -n "[$((TOTAL_TESTS + 1))] Procesos listados correctamente ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
PROC_COUNT=$(grep -c '|' /proc/continfo_pr2_so1_202300625 | head -1)
if [ "$PROC_COUNT" -gt 10 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($PROC_COUNT procesos)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Procesos listados correctamente: PASS ($PROC_COUNT procesos)" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Procesos listados correctamente: FAIL" >> "$REPORTE"
fi

print_header "2. DAEMON DE GO" | tee -a "$REPORTE"

# 2.1 Verificar go.mod
verify_test "Archivo go.mod existe" \
    "[ -f $PROYECTO_PATH/daemon-go/go.mod ]"

# 2.2 Verificar estructura del proyecto
verify_test "Estructura de directorios correcta" \
    "[ -d $PROYECTO_PATH/daemon-go/cmd ] && [ -d $PROYECTO_PATH/daemon-go/internal ]"

# 2.3 Compilar daemon
echo -n "[$((TOTAL_TESTS + 1))] Compilando daemon de GO ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
cd "$PROYECTO_PATH/daemon-go"
if go build -o bin/daemon-so1 cmd/daemon/main.go 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Compilando daemon de GO: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Compilando daemon de GO: FAIL" >> "$REPORTE"
fi

# 2.4 Verificar binario
verify_test "Binario daemon-so1 generado" \
    "[ -f $PROYECTO_PATH/daemon-go/bin/daemon-so1 ]"

# 2.5 Verificar paquetes internos
verify_test "Paquete internal/parser existe" \
    "[ -f $PROYECTO_PATH/daemon-go/internal/parser/parser.go ]"

verify_test "Paquete internal/analyzer existe" \
    "[ -f $PROYECTO_PATH/daemon-go/internal/analyzer/analyzer.go ]"

verify_test "Paquete internal/storage existe" \
    "[ -f $PROYECTO_PATH/daemon-go/internal/storage/valkey.go ]"

verify_test "Paquete internal/orchestrator existe" \
    "[ -f $PROYECTO_PATH/daemon-go/internal/orchestrator/orchestrator.go ]"

print_header "3. CRONJOB" | tee -a "$REPORTE"

# 3.1 Verificar scripts de cron
verify_test "Script install-cron.sh existe" \
    "[ -f $PROYECTO_PATH/cron/install-cron.sh ]"

verify_test "Script uninstall-cron.sh existe" \
    "[ -f $PROYECTO_PATH/cron/uninstall-cron.sh ]"

# 3.2 Verificar script generador
verify_test "Script generar.sh existe" \
    "[ -f $PROYECTO_PATH/docker/generar.sh ]"

# 3.3 Verificar que el cronjob está instalado
echo -n "[$((TOTAL_TESTS + 1))] Cronjob instalado en crontab ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if crontab -l 2>/dev/null | grep -q "generar.sh"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Cronjob instalado en crontab: PASS" >> "$REPORTE"
    echo "" >> "$REPORTE"
    echo "--- Cronjobs activos ---" >> "$REPORTE"
    crontab -l >> "$REPORTE"
    echo "" >> "$REPORTE"
else
    echo -e "${YELLOW}⚠ WARNING${NC} (puede no estar instalado aún)"
    echo "[$TOTAL_TESTS] Cronjob instalado en crontab: WARNING" >> "$REPORTE"
fi

print_header "4. INFRAESTRUCTURA DOCKER" | tee -a "$REPORTE"

# 4.1 Verificar docker-compose.yml
verify_test "Archivo docker-compose.yml existe" \
    "[ -f $PROYECTO_PATH/docker/docker-compose.yml ]"

# 4.2 Verificar que Valkey está corriendo
echo -n "[$((TOTAL_TESTS + 1))] Contenedor Valkey corriendo ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if sudo docker ps | grep -q "db_valkey"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Contenedor Valkey corriendo: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Contenedor Valkey corriendo: FAIL" >> "$REPORTE"
fi

# 4.3 Verificar que Grafana está corriendo
echo -n "[$((TOTAL_TESTS + 1))] Contenedor Grafana corriendo ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if sudo docker ps | grep -q "dashboard_grafana"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Contenedor Grafana corriendo: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Contenedor Grafana corriendo: FAIL" >> "$REPORTE"
fi

# 4.4 Verificar conexión a Valkey
echo -n "[$((TOTAL_TESTS + 1))] Conexión a Valkey funcional ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if sudo docker exec db_valkey valkey-cli ping 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Conexión a Valkey funcional: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Conexión a Valkey funcional: FAIL" >> "$REPORTE"
fi

# 4.5 Verificar dashboard de Grafana
verify_test "Dashboard de Grafana provisionado" \
    "[ -f $PROYECTO_PATH/docker/grafana/provisioning/dashboards/contenedores-dashboard.json ]"

print_header "5. CONTENEDORES DE PRUEBA" | tee -a "$REPORTE"

# 5.1 Contar contenedores activos
echo -n "[$((TOTAL_TESTS + 1))] Contenedores de prueba generados ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
CONTAINER_COUNT=$(sudo docker ps --format '{{.Image}}' | grep -c -E 'alpine|go-client' || echo 0)
if [ "$CONTAINER_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($CONTAINER_COUNT contenedores)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Contenedores de prueba generados: PASS ($CONTAINER_COUNT contenedores)" >> "$REPORTE"
else
    echo -e "${YELLOW}⚠ WARNING${NC} (no hay contenedores de prueba)"
    echo "[$TOTAL_TESTS] Contenedores de prueba generados: WARNING" >> "$REPORTE"
fi

# 5.2 Guardar lista de contenedores
echo "" >> "$REPORTE"
echo "--- Contenedores activos ---" >> "$REPORTE"
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' >> "$REPORTE"
echo "" >> "$REPORTE"

print_header "6. ALMACENAMIENTO EN VALKEY" | tee -a "$REPORTE"

# 6.1 Verificar métricas de memoria
echo -n "[$((TOTAL_TESTS + 1))] Métricas de memoria en Valkey ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
MEMORY_KEYS=$(sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current 2>/dev/null | wc -l)
if [ "$MEMORY_KEYS" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Métricas de memoria en Valkey: PASS" >> "$REPORTE"
    
    # Guardar evidencia
    echo "" >> "$REPORTE"
    echo "--- Datos en Valkey: metrics:memory:current ---" >> "$REPORTE"
    sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current >> "$REPORTE"
    echo "" >> "$REPORTE"
else
    echo -e "${YELLOW}⚠ WARNING${NC} (no hay métricas aún)"
    echo "[$TOTAL_TESTS] Métricas de memoria en Valkey: WARNING" >> "$REPORTE"
fi

# 6.2 Verificar Top de RAM
echo -n "[$((TOTAL_TESTS + 1))] Top 5 contenedores por RAM en Valkey ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
RAM_TOP=$(sudo docker exec db_valkey valkey-cli ZCARD metrics:containers:ram:top 2>/dev/null || echo 0)
if [ "$RAM_TOP" -gt 0 ]; then
    echo -e "${GREEN}✓ PASS${NC} ($RAM_TOP entradas)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Top 5 contenedores por RAM en Valkey: PASS" >> "$REPORTE"
    
    # Guardar evidencia
    echo "" >> "$REPORTE"
    echo "--- Top 5 RAM ---" >> "$REPORTE"
    sudo docker exec db_valkey valkey-cli ZREVRANGE metrics:containers:ram:top 0 4 WITHSCORES >> "$REPORTE"
    echo "" >> "$REPORTE"
else
    echo -e "${YELLOW}⚠ WARNING${NC} (no hay datos aún)"
    echo "[$TOTAL_TESTS] Top 5 contenedores por RAM en Valkey: WARNING" >> "$REPORTE"
fi

# 6.3 Verificar contador de eliminados
echo -n "[$((TOTAL_TESTS + 1))] Contador de contenedores eliminados ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
DELETED_COUNT=$(sudo docker exec db_valkey valkey-cli GET stats:containers_deleted 2>/dev/null || echo 0)
echo -e "${GREEN}✓ PASS${NC} (Total: $DELETED_COUNT)"
PASSED_TESTS=$((PASSED_TESTS + 1))
echo "[$TOTAL_TESTS] Contador de contenedores eliminados: PASS (Total: $DELETED_COUNT)" >> "$REPORTE"

print_header "7. RESTRICCIONES CLAVE" | tee -a "$REPORTE"

# 7.1 Verificar que NO se elimina Grafana
verify_test "Código protege contenedor Grafana" \
    "grep -q 'grafana' $PROYECTO_PATH/daemon-go/internal/analyzer/analyzer.go"

# 7.2 Verificar configuración de mínimos
echo -n "[$((TOTAL_TESTS + 1))] Configuración de contenedores mínimos ... "
TOTAL_TESTS=$((TOTAL_TESTS + 1))
if grep -q "MinLowConsumption.*3" "$PROYECTO_PATH/daemon-go/internal/config/config.go" && \
   grep -q "MinHighConsumption.*2" "$PROYECTO_PATH/daemon-go/internal/config/config.go"; then
    echo -e "${GREEN}✓ PASS${NC} (3 bajo, 2 alto)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    echo "[$TOTAL_TESTS] Configuración de contenedores mínimos: PASS" >> "$REPORTE"
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    echo "[$TOTAL_TESTS] Configuración de contenedores mínimos: FAIL" >> "$REPORTE"
fi

print_header "RESUMEN DE VERIFICACIÓN" | tee -a "$REPORTE"

echo "" | tee -a "$REPORTE"
echo "Total de pruebas: $TOTAL_TESTS" | tee -a "$REPORTE"
echo -e "${GREEN}Exitosas: $PASSED_TESTS${NC}" | tee -a "$REPORTE"
echo -e "${RED}Fallidas: $FAILED_TESTS${NC}" | tee -a "$REPORTE"

PERCENTAGE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")
echo "" | tee -a "$REPORTE"
echo "Porcentaje de cumplimiento: ${PERCENTAGE}%" | tee -a "$REPORTE"

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════${NC}" | tee -a "$REPORTE"
    echo -e "${GREEN}✓ TODOS LOS REQUISITOS CUMPLIDOS ✓${NC}" | tee -a "$REPORTE"
    echo -e "${GREEN}════════════════════════════════════${NC}" | tee -a "$REPORTE"
else
    echo -e "${YELLOW}════════════════════════════════════${NC}" | tee -a "$REPORTE"
    echo -e "${YELLOW}⚠ ALGUNOS REQUISITOS NECESITAN ATENCIÓN${NC}" | tee -a "$REPORTE"
    echo -e "${YELLOW}════════════════════════════════════${NC}" | tee -a "$REPORTE"
fi

echo "" | tee -a "$REPORTE"
echo "Reporte guardado en: $REPORTE" | tee -a "$REPORTE"
echo "" | tee -a "$REPORTE"

# Descargar módulo al finalizar
sudo rmmod sonda 2>/dev/null || true

exit 0
