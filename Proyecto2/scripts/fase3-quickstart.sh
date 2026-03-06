#!/bin/bash

# Script Quick-Start para Fase 3
# Inicializa todos los componentes necesarios

set -e

PROYECTO_PATH="/home/carlos/Desktop/Proyecto2"
DOCKER_PATH="$PROYECTO_PATH/docker"
CRON_PATH="$PROYECTO_PATH/cron"

echo "======================================"
echo "FASE 3 - Quick Start Setup"
echo "======================================"
echo ""

# Función para verificar comando
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "✗ ERROR: $1 no está instalado"
        return 1
    fi
    return 0
}

echo "1. Verificando dependencias..."
echo "---------------------------------"
check_command docker && echo "✓ Docker disponible" || exit 1
check_command docker-compose && echo "✓ Docker Compose disponible" || exit 1
echo ""

echo "2. Iniciando servicios base (Valkey + Grafana)..."
echo "---------------------------------"
cd "$DOCKER_PATH"
docker-compose -f docekr-compose.yml up -d
echo "✓ Servicios iniciados"
echo ""

echo "3. Esperando que servicios estén listos..."
echo "---------------------------------"
sleep 5
docker-compose -f docekr-compose.yml ps
echo ""

echo "4. Verificando conectividad..."
echo "---------------------------------"
if docker exec db_valkey redis-cli ping &> /dev/null; then
    echo "✓ Valkey respondiendo"
else
    echo "⚠ Valkey no respondiendo aún"
fi
echo ""

echo "5. Instalando cronjob..."
echo "---------------------------------"
bash "$CRON_PATH/install-cron.sh"
echo ""

echo "6. Verificando cronjob..."
echo "---------------------------------"
if crontab -l 2>/dev/null | grep -q "generar.sh"; then
    echo "✓ Cronjob verificado"
    crontab -l | grep generar.sh
else
    echo "✗ Error: Cronjob no se instaló"
    exit 1
fi
echo ""

echo "7. Información de acceso:"
echo "---------------------------------"
echo ""
echo "📊 Grafana Dashboard:"
echo "   URL: http://localhost:3000"
echo "   Usuario: admin"
echo "   Contraseña: admin"
echo ""
echo "📦 Valkey Database:"
echo "   Host: localhost"
echo "   Puerto: 6379"
echo ""

echo "📋 Comandos útiles:"
echo "   Ver logs: sudo tail -f /var/log/proyecto2-contenedores.log"
echo "   Ver contenedores: docker ps"
echo "   Ejecutar script manual: bash $DOCKER_PATH/generar.sh"
echo "   Desinstalar cronjob: bash $CRON_PATH/uninstall-cron.sh"
echo ""

echo "======================================"
echo "✓ Setup completado exitosamente"
echo "======================================"
echo ""
echo "El cronjob ejecutará automáticamente cada 2 minutos"
echo "Monitorea los logs en otra terminal:"
echo "  sudo tail -f /var/log/proyecto2-contenedores.log"
