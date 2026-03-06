#!/bin/bash
# Script para recargar el módulo kernel

echo "Descargando módulo anterior..."
sudo rmmod sonda 2>/dev/null || echo "Módulo no estaba cargado"

echo "Cargando nuevo módulo..."
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/sonda.ko

if [ $? -eq 0 ]; then
    echo "✓ Módulo recargado exitosamente"
    echo ""
    echo "Verificando formato del archivo /proc:"
    head -20 /proc/continfo_pr2_so1_202300625
else
    echo "✗ Error al cargar el módulo"
    exit 1
fi
