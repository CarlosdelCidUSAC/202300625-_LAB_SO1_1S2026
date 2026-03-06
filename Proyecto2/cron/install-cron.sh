#!/bin/bash

# Script para instalar el cronjob que ejecuta generar.sh cada 2 minutos
# Ubicación: /home/carlos/Desktop/Proyecto2/cron/install-cron.sh

PROYECTO_PATH="/home/carlos/Desktop/Proyecto2"
SCRIPT_GENERADOR="$PROYECTO_PATH/docker/generar.sh"
LOG_FILE="/var/log/proyecto2-contenedores.log"

echo "======================================"
echo "Instalando Cronjob"
echo "======================================"

# Verificar si el script existe
if [ ! -f "$SCRIPT_GENERADOR" ]; then
    echo "ERROR: Script $SCRIPT_GENERADOR no encontrado"
    exit 1
fi

# Verificar permisos de ejecución
if [ ! -x "$SCRIPT_GENERADOR" ]; then
    echo "ERROR: Script no tiene permisos de ejecución"
    exit 1
fi

echo "Script identificado: $SCRIPT_GENERADOR"

# Crear cronjob entry (ejecutar cada 2 minutos)
# Formato: minuto hora dia mes dia_semana comando
CRON_ENTRY="*/2 * * * * $SCRIPT_GENERADOR >> $LOG_FILE 2>&1"

# Cargar crontab actual en archivo temporal
crontab -l > /tmp/crontab_temp 2>/dev/null || true

# Verificar si el cronjob ya existe
if grep -q "$SCRIPT_GENERADOR" /tmp/crontab_temp; then
    echo "AVISO: Cronjob ya está instalado"
    rm /tmp/crontab_temp
    exit 0
fi

# Agregar el nuevo cronjob
echo "$CRON_ENTRY" >> /tmp/crontab_temp

# Instalar crontab actualizado
crontab /tmp/crontab_temp

# Limpiar
rm /tmp/crontab_temp

echo "✓ Cronjob instalado exitosamente"
echo "  Ejecutará el script: $SCRIPT_GENERADOR"
echo "  Cada 2 minutos"
echo "  Log output: $LOG_FILE"
echo "======================================"

# Mostrar cronjobs activos
echo "Cronjobs activos:"
crontab -l
