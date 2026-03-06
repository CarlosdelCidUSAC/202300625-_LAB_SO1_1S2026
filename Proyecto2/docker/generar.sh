#!/bin/bash

# Arreglo con los comandos exactos solicitados para cada tipo de contenedor
# 0: Alto consumo de RAM (go-client)
# 1: Alto consumo de CPU (alpine con calculo matematico)
# 2: Bajo consumo (alpine con sleep)
comandos=(
    "docker run -d roldyoran/go-client"
    "docker run -d alpine sh -c \"while true; do echo '2^20' | bc > /dev/null; sleep 2; done\""
    "docker run -d alpine sleep 240"
)

descripcion=(
    "Alto consumo RAM"
    "Alto consumo CPU"
    "Bajo consumo"
)

echo "======================================"
echo "Iniciando creacion de 5 contenedores aleatorios..."
echo "======================================"

contador_exito=0
contador_error=0

# Bucle para crear 5 contenedores
for i in {1..5}
do
    # Generar un indice aleatorio entre 0 y 2
    indice=$((RANDOM % 3))
    
    # Obtener el comando correspondiente
    comando_a_ejecutar=${comandos[$indice]}
    tipo=${descripcion[$indice]}
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Contenedor $i/$5: $tipo (indice $indice)"
    
    # Ejecutar el comando
    if eval $comando_a_ejecutar > /dev/null 2>&1; then
        contador_exito=$((contador_exito + 1))
        echo "  ✓ Contenedor creado exitosamente"
    else
        contador_error=$((contador_error + 1))
        echo "  ✗ Error al crear contenedor"
    fi
done

echo "======================================"
echo "Despliegue finalizado."
echo "Contenedores creados: $contador_exito"
echo "Errores: $contador_error"
echo "======================================"