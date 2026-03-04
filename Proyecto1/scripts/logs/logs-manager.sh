#!/bin/bash

# Script maestro para gestión de logs
# Proporciona un menú interactivo para todas las operaciones de logs

LOGS_DIR="../logs"

show_banner() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║   GESTOR DE LOGS - LAB SO1             ║"
    echo "║   Carnet: 202300625                    ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
}

show_menu() {
    echo "OPCIONES DISPONIBLES:"
    echo ""
    echo "  1) Generar logs de pruebas (APIs funcionando)"
    echo "  2) Generar logs de error (APIs caídas)"
    echo "  3)  Ver logs generados"
    echo "  4)  Ver resumen de logs"
    echo "  5)  Limpiar todos los logs"
    echo "  6)  Ayuda y documentación"
    echo "  7)  Salir"
    echo ""
}

show_help() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║   AYUDA - GESTOR DE LOGS               ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "DESCRIPCIÓN:"
    echo "Este script te ayuda a generar y gestionar logs de pruebas"
    echo "para las APIs del laboratorio de Sistemas Operativos 1."
    echo ""
    echo "FLUJO DE TRABAJO RECOMENDADO:"
    echo ""
    echo "1. Asegúrate que las VMs estén activas:"
    echo "   ping 192.168.122.10  # VM1"
    echo "   ping 192.168.122.20  # VM2"
    echo ""
    echo "2. Verifica que las APIs estén corriendo:"
    echo "   curl http://192.168.122.10:8081/health  # API1"
    echo "   curl http://192.168.122.10:8082/health  # API2"
    echo "   curl http://192.168.122.20:8083/health  # API3"
    echo ""
    echo "3. Genera los logs (opción 1)"
    echo ""
    echo "4. Opcionalmente, genera logs de error (opción 2)"
    echo "   - Requiere detener una API manualmente primero"
    echo ""
    echo "5. Verifica los logs generados (opción 3 o 4)"
    echo ""
    echo "UBICACIÓN DE LOGS:"
    echo "  Directorio: $LOGS_DIR/"
    echo ""
    echo "DOCUMENTACIÓN:"
    echo "  - scripts/README.md - Guía de scripts"
    echo "  - logs/README.md - Info sobre logs"
    echo "  - docs/operations/Evidencia_Pruebas.md - Evidencia"
    echo ""
    read -p "Presiona ENTER para volver al menú..."
}

show_summary() {
    clear
    echo "╔════════════════════════════════════════╗"
    echo "║   RESUMEN DE LOGS                      ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    if [ ! -d "$LOGS_DIR" ] || [ -z "$(ls -A $LOGS_DIR/*.log 2>/dev/null)" ]; then
        echo "No hay logs generados"
        echo ""
        echo "Ejecuta la opción 1 para generar logs"
    else
        echo "Directorio: $LOGS_DIR/"
        echo ""
        echo "Archivos generados:"
        ls -lh "$LOGS_DIR"/*.log 2>/dev/null | awk '{printf "   %-30s %8s\n", $9, $5}'
        echo ""
        echo "Total: $(ls -1 $LOGS_DIR/*.log 2>/dev/null | wc -l) archivos"
        
        if [ -f "$LOGS_DIR/resumen.log" ]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            cat "$LOGS_DIR/resumen.log"
        fi
    fi
    echo ""
    read -p "Presiona ENTER para volver al menú..."
}

# Main loop
while true; do
    show_banner
    show_menu
    read -p "Selecciona una opción (1-7): " option
    echo ""
    
    case $option in
        1)
            echo "Generando logs de pruebas..."
            echo ""
            scripts/logs/generate-logs.sh
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
        2)
            echo "Generando logs de error..."
            echo ""
            echo " IMPORTANTE:"
            echo "Asegúrate de haber detenido al menos una API"
            echo "antes de continuar para obtener logs reales."
            echo ""
            read -p "¿Continuar? (s/N): " confirm
            if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                scripts/logs/generate-error-logs.sh
            else
                echo "Operación cancelada"
            fi
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
        3)
            scripts/logs/view-logs.sh
            ;;
        4)
            show_summary
            ;;
        5)
            scripts/logs/clean-logs.sh
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
        6)
            show_help
            ;;
        7)
            clear
            echo " ¡Hasta luego!"
            echo ""
            exit 0
            ;;
        *)
            echo "Opción inválida. Selecciona un número del 1 al 7."
            echo ""
            read -p "Presiona ENTER para continuar..."
            ;;
    esac
done
