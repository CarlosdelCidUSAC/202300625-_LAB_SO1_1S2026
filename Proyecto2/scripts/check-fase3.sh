#!/bin/bash

# Script para verificar el estado de la Fase 3

echo "======================================"
echo "STATUS FASE 3 - Verificación"
echo "======================================"
echo ""

echo "1. DOCKERFILES:"
echo "-----------------"
for dir in high-memory high-cpu low-consumption; do
    if [ -f "/home/carlos/Desktop/Proyecto2/docker/$dir/Dockerfile" ]; then
        echo "✓ $dir/Dockerfile existe"
    else
        echo "✗ $dir/Dockerfile NO existe"
    fi
done
echo ""

echo "2. SCRIPTS:"
echo "-----------------"
SCRIPT="/home/carlos/Desktop/Proyecto2/docker/generar.sh"
if [ -x "$SCRIPT" ]; then
    echo "✓ generar.sh es ejecutable"
else
    echo "✗ generar.sh NO es ejecutable"
fi

echo ""

echo "3. CRONJOB SCRIPTS:"
echo "-----------------"
for script in install-cron.sh uninstall-cron.sh; do
    CRON_SCRIPT="/home/carlos/Desktop/Proyecto2/cron/$script"
    if [ -x "$CRON_SCRIPT" ]; then
        echo "✓ $script es ejecutable"
    else
        echo "✗ $script NO es ejecutable"
    fi
done
echo ""

echo "4. DOCKER COMPOSE:"
echo "-----------------"
COMPOSE="/home/carlos/Desktop/Proyecto2/docker/docekr-compose.yml"
if [ -f "$COMPOSE" ]; then
    echo "✓ docker-compose.yml existe"
    echo "  Servicios definidos:"
    grep "container_name:" "$COMPOSE" | sed 's/^/    - /'
else
    echo "✗ docker-compose.yml NO existe"
fi
echo ""

echo "5. ESTADO CRONJOB ACTUAL:"
echo "-----------------"
if crontab -l 2>/dev/null | grep -q "generar.sh"; then
    echo "✓ Cronjob instalado"
    echo "  $(crontab -l | grep generar.sh)"
else
    echo "✗ Cronjob NO instalado"
fi
echo ""

echo "6. SERVICIOS DOCKER:"
echo "-----------------"
if command -v docker &> /dev/null; then
    echo "Docker está disponible"
    RUNNING=$(docker ps --format "table {{.Names}}" 2>/dev/null | wc -l)
    TOTAL=$(docker ps -a --format "table {{.Names}}" 2>/dev/null | wc -l)
    echo "  Contenedores ejecutándose: $((RUNNING-1))"
    echo "  Contenedores totales: $((TOTAL-1))"
else
    echo "✗ Docker NO está disponible"
fi
echo ""

echo "7. DOCUMENTACIÓN:"
echo "-----------------"
if [ -f "/home/carlos/Desktop/Proyecto2/docs/FASE3_README.md" ]; then
    echo "✓ FASE3_README.md existe"
else
    echo "✗ FASE3_README.md NO existe"
fi
echo ""

echo "======================================"
echo "Verificación completada"
echo "======================================"
