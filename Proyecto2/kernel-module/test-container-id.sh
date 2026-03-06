#!/bin/bash

echo "======================================"
echo "  TEST: Extracción de Container ID"
echo "======================================"
echo ""

# 1. Recargar módulo
echo "[1/4] Recargando módulo kernel..."
sudo rmmod sonda 2>/dev/null || true
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
if [ $? -ne 0 ]; then
    echo "✗ Error cargando módulo"
    exit 1
fi
echo "✓ Módulo cargado"
echo ""

# 2. Crear contenedores de prueba
echo "[2/4] Creando contenedores de prueba..."
docker run -d --name test-alpine-1 alpine sleep 300 > /dev/null 2>&1
docker run -d --name test-alpine-2 alpine sh -c "while true; do echo test; sleep 2; done" > /dev/null 2>&1
echo "✓ Contenedores creados"
echo ""

# 3. Esperar un momento
sleep 2

# 4. Verificar salida del módulo
echo "[3/4] Verificando formato de salida..."
echo ""
echo "--- Primeras 15 líneas del archivo /proc ---"
head -15 /proc/continfo_pr2_so1_202300625
echo ""
echo "--- Procesos con 'container:' en ComandoID ---"
grep "container:" /proc/continfo_pr2_so1_202300625 | head -10
echo ""

# 5. Limpiar
echo "[4/4] Limpiando contenedores de prueba..."
docker stop test-alpine-1 test-alpine-2 > /dev/null 2>&1
docker rm test-alpine-1 test-alpine-2 > /dev/null 2>&1
echo "✓ Contenedores eliminados"
echo ""

echo "======================================"
echo "  TEST COMPLETADO"
echo "======================================"
