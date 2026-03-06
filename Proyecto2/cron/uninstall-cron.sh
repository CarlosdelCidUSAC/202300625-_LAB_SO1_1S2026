#!/bin/bash

# Script para desinstalar el cronjob
# Ubicación: /home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh

PROYECTO_PATH="/home/carlos/Desktop/Proyecto2"
SCRIPT_GENERADOR="$PROYECTO_PATH/docker/generar.sh"

echo "======================================"
echo "Desinstalando Cronjob"
echo "======================================"

# Cargar crontab actual en archivo temporal
crontab -l > /tmp/crontab_temp 2>/dev/null

# Verificar si el cronjob existe
if grep -q "$SCRIPT_GENERADOR" /tmp/crontab_temp; then
    # Eliminar la línea del cronjob
    grep -v "$SCRIPT_GENERADOR" /tmp/crontab_temp > /tmp/crontab_nuevo
    
    # Instalar crontab actualizado
    crontab /tmp/crontab_nuevo
    
    echo "✓ Cronjob desinstalado exitosamente"
else
    echo "AVISO: No se encontró cronjob para este proyecto"
fi

# Limpiar
rm -f /tmp/crontab_temp /tmp/crontab_nuevo

echo "Cronjobs activos restantes:"
crontab -l 2>/dev/null || echo "  (ninguno)"
echo "======================================"
