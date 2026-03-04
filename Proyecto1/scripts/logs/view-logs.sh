#!/bin/bash

# Script para visualizar logs generados
# Muestra el contenido de todos los logs de forma organizada

LOGS_DIR="../logs"

echo "======================================"
echo "VISUALIZACIÓN DE LOGS GENERADOS"
echo "======================================"
echo ""

# Verificar que existan logs
if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A $LOGS_DIR 2>/dev/null)" ]; then
    echo "No se encontraron logs en $LOGS_DIR"
    echo "Ejecuta primero: ./generate-logs.sh"
    exit 1
fi

# Función para mostrar un log
show_log() {
    local log_file=$1
    if [ -f "$log_file" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo " $(basename $log_file)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        cat "$log_file"
        echo ""
    fi
}

# Mostrar resumen primero
if [ -f "$LOGS_DIR/resumen.log" ]; then
    show_log "$LOGS_DIR/resumen.log"
fi

# Opción interactiva
echo "¿Qué logs deseas ver?"
echo ""
echo "1) Health Checks"
echo "2) Comunicación Exitosa"
echo "3) Logs de Error"
echo "4) Todos los logs"
echo "5) Buscar log específico"
echo "6) Salir"
echo ""
read -p "Selecciona una opción (1-6): " option

case $option in
    1)
        echo ""
        echo "=== HEALTH CHECKS ==="
        show_log "$LOGS_DIR/api1-health.log"
        show_log "$LOGS_DIR/api2-health.log"
        show_log "$LOGS_DIR/api3-health.log"
        ;;
    2)
        echo ""
        echo "=== COMUNICACIÓN EXITOSA ==="
        show_log "$LOGS_DIR/api1-call-api2-ok.log"
        show_log "$LOGS_DIR/api1-call-api3-ok.log"
        show_log "$LOGS_DIR/api2-call-api1-ok.log"
        show_log "$LOGS_DIR/api2-call-api3-ok.log"
        show_log "$LOGS_DIR/api3-call-api1-ok.log"
        show_log "$LOGS_DIR/api3-call-api2-ok.log"
        ;;
    3)
        echo ""
        echo "=== LOGS DE ERROR ==="
        for log in "$LOGS_DIR"/*-error.log; do
            if [ -f "$log" ]; then
                show_log "$log"
            fi
        done
        ;;
    4)
        echo ""
        echo "=== TODOS LOS LOGS ==="
        for log in "$LOGS_DIR"/*.log; do
            if [ "$(basename $log)" != "resumen.log" ]; then
                show_log "$log"
            fi
        done
        ;;
    5)
        echo ""
        echo "Logs disponibles:"
        ls -1 "$LOGS_DIR"/*.log 2>/dev/null | nl
        echo ""
        read -p "Ingresa el nombre del archivo (ej: api1-health.log): " filename
        show_log "$LOGS_DIR/$filename"
        ;;
    6)
        echo " Saliendo..."
        exit 0
        ;;
    *)
        echo "Opción inválida"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo " Visualización completada"
echo "======================================"
