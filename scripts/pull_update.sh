#!/bin/bash

# Detener el script si ocurre algún error
set -e

# --- CONFIGURACIÓN ---
USER="carlos"
VM1_IP="192.168.122.10"
VM2_IP="192.168.122.20"
ZOT_IP="192.168.122.30"
ZOT_PORT="5000"
CARNET="202300625"

# Definición de Nombres de Imágenes (Remotas en Zot)
IMG_API1_REMOTE="${ZOT_IP}:${ZOT_PORT}/api1-${CARNET}:latest"
IMG_API2_REMOTE="${ZOT_IP}:${ZOT_PORT}/api2-${CARNET}:latest"
IMG_API3_REMOTE="${ZOT_IP}:${ZOT_PORT}/api3-${CARNET}:latest"

# Definición de Nombres Locales (Para mantener compatibilidad con tus scripts de run)
IMG_API1_LOCAL="docker.io/library/api1-${CARNET}:latest"
IMG_API2_LOCAL="docker.io/library/api2-${CARNET}:latest"
IMG_API3_LOCAL="docker.io/library/api3-${CARNET}:latest"

echo "=== Iniciando Descarga de Imágenes desde Zot Registry ($ZOT_IP) ==="

# --- VM 1 (API 1 y 2) ---
echo ""
echo "--- Actualizando VM 1 ($VM1_IP) ---"
ssh -tt $USER@$VM1_IP << EOF
    # --- API 1 ---
    echo "[VM1] Descargando API 1 desde el registro..."
    # Se usa --plain-http porque Zot no tiene SSL configurado
    sudo ctr images pull --plain-http $IMG_API1_REMOTE
    
    echo "[VM1] Re-etiquetando API 1 para uso local..."
    # Esto permite que tus scripts de 'ctr run' antiguos sigan funcionando sin cambios
    sudo ctr images tag $IMG_API1_REMOTE $IMG_API1_LOCAL
    
    # --- API 2 ---
    echo "[VM1] Descargando API 2 desde el registro..."
    sudo ctr images pull --plain-http $IMG_API2_REMOTE
    
    echo "[VM1] Re-etiquetando API 2 para uso local..."
    sudo ctr images tag $IMG_API2_REMOTE $IMG_API2_LOCAL

    echo "Imágenes en VM1 actualizadas."
    sudo ctr images ls | grep $CARNET
EOF

# --- VM 2 (API 3) ---
echo ""
echo "--- Actualizando VM 2 ($VM2_IP) ---"
ssh -tt $USER@$VM2_IP << EOF
    # --- API 3 ---
    echo "[VM2] Descargando API 3 desde el registro..."
    sudo ctr images pull --plain-http $IMG_API3_REMOTE
    
    echo "[VM2] Re-etiquetando API 3 para uso local..."
    sudo ctr images tag $IMG_API3_REMOTE $IMG_API3_LOCAL

    echo "Imágenes en VM2 actualizadas."
    sudo ctr images ls | grep $CARNET
EOF

echo ""
echo "=== Pull Completado ==="
echo "Ahora puedes reiniciar los contenedores para aplicar los cambios."