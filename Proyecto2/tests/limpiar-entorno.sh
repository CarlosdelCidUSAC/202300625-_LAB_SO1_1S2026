#!/bin/bash

# Script para limpiar el entorno de pruebas
# Útil antes de una demostración limpia del proyecto

echo "=========================================="
echo " LIMPIEZA DE ENTORNO - PROYECTO 2 SO1"
echo "=========================================="
echo ""

# 1. Detener y eliminar contenedores de prueba (excepto infraestructura)
echo "[1/5] Eliminando contenedores de prueba..."
ALPINE_COUNT=$(sudo docker ps -a --format '{{.Names}}' | grep -v 'dashboard_grafana\|db_valkey' | wc -l)
if [ "$ALPINE_COUNT" -gt 0 ]; then
    sudo docker ps -a --format '{{.Names}}' | grep -v 'dashboard_grafana\|db_valkey' | xargs -r sudo docker stop 2>/dev/null
    sudo docker ps -a --format '{{.Names}}' | grep -v 'dashboard_grafana\|db_valkey' | xargs -r sudo docker rm 2>/dev/null
    echo "✓ $ALPINE_COUNT contenedores eliminados"
else
    echo "✓ No hay contenedores de prueba para eliminar"
fi
echo ""

# 2. Limpiar imágenes huérfanas (opcional)
echo "[2/5] Limpiando recursos Docker..."
sudo docker system prune -f > /dev/null 2>&1
echo "✓ Sistema Docker limpiado"
echo ""

# 3. Limpiar datos de Valkey
echo "[3/5] Limpiando datos de Valkey..."
if sudo docker ps | grep -q "db_valkey"; then
    sudo docker exec db_valkey valkey-cli FLUSHALL > /dev/null 2>&1
    echo "✓ Datos de Valkey eliminados"
else
    echo "⚠ Valkey no está corriendo"
fi
echo ""

# 4. Descargar módulo kernel (si está cargado)
echo "[4/5] Descargando módulo kernel..."
if lsmod | grep -q "sonda"; then
    sudo rmmod sonda 2>/dev/null
    echo "✓ Módulo kernel descargado"
else
    echo "✓ Módulo no estaba cargado"
fi
echo ""

# 5. Verificar cronjob
echo "[5/5] Verificando cronjob..."
if crontab -l 2>/dev/null | grep -q "generar.sh"; then
    echo "⚠ Cronjob está instalado (usar uninstall-cron.sh para eliminarlo)"
else
    echo "✓ No hay cronjob instalado"
fi
echo ""

echo "=========================================="
echo " LIMPIEZA COMPLETADA"
echo "=========================================="
echo ""
echo "Estado actual del sistema:"
echo "  - Contenedores activos: $(sudo docker ps --format '{{.Names}}' | wc -l)"
echo "  - Grafana: $(sudo docker ps | grep -q 'dashboard_grafana' && echo 'CORRIENDO' || echo 'DETENIDO')"
echo "  - Valkey: $(sudo docker ps | grep -q 'db_valkey' && echo 'CORRIENDO' || echo 'DETENIDO')"
echo "  - Módulo kernel: $(lsmod | grep -q 'sonda' && echo 'CARGADO' || echo 'DESCARGADO')"
echo ""
echo "El sistema está listo para una demostración limpia."
echo ""
