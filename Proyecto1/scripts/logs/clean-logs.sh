#!/bin/bash

# Script para limpiar logs antiguos

LOGS_DIR="../logs"

echo "======================================"
echo "LIMPIEZA DE LOGS"
echo "======================================"
echo ""

# Verificar que existan logs
if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A $LOGS_DIR 2>/dev/null)" ]; then
    echo "  No hay logs para limpiar en $LOGS_DIR"
    exit 0
fi

# Mostrar logs actuales
echo "Logs actuales:"
ls -lh "$LOGS_DIR"/*.log 2>/dev/null | awk '{print $9, "(" $5 ")"}'
echo ""

# Contar archivos
total_logs=$(ls -1 "$LOGS_DIR"/*.log 2>/dev/null | wc -l)
echo "Total de archivos: $total_logs"
echo ""

# Confirmar
read -p "¿Deseas eliminar TODOS los logs? (s/N): " confirm

if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
    rm -f "$LOGS_DIR"/*.log
    echo ""
    echo " Logs eliminados exitosamente"
    echo ""
    echo "Para generar nuevos logs ejecuta:"
    echo "  ./generate-logs.sh"
else
    echo ""
    echo "Operación cancelada - Los logs se mantienen"
fi

echo ""
echo "======================================"
