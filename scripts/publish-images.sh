#!/bin/bash

# Configuración
USER="carlos"
VM1_IP="192.168.122.10"
VM2_IP="192.168.122.20"
ZOT_IP="192.168.122.30"
ZOT_PORT="5000"
CARNET="202300625"

# Nombres de imágenes locales (creadas en deploy.sh)
IMG_API1_LOCAL="docker.io/library/api1-${CARNET}:latest"
IMG_API2_LOCAL="docker.io/library/api2-${CARNET}:latest"
IMG_API3_LOCAL="docker.io/library/api3-${CARNET}:latest"

# Nombres de imágenes remotas (Etiquetadas para Zot)
# Formato: IP:PORT/NOMBRE:TAG
IMG_API1_REMOTE="${ZOT_IP}:${ZOT_PORT}/api1-${CARNET}:latest"
IMG_API2_REMOTE="${ZOT_IP}:${ZOT_PORT}/api2-${CARNET}:latest"
IMG_API3_REMOTE="${ZOT_IP}:${ZOT_PORT}/api3-${CARNET}:latest"

echo "=== Iniciando Publicación de Imágenes a Zot Registry ($ZOT_IP) ==="

# --- VM 1 (API 1 y 2) ---
echo ""
echo "--- Procesando VM 1 ($VM1_IP) ---"
ssh $USER@$VM1_IP << EOF
    # 1. API 1
    echo "[API 1] Etiquetando para Zot..."
    sudo ctr images tag $IMG_API1_LOCAL $IMG_API1_REMOTE
    
    echo "[API 1] Subiendo a Zot..."
    # --plain-http es CRÍTICO porque Zot está sin SSL
    sudo ctr images push --plain-http $IMG_API1_REMOTE
    
    # 2. API 2
    echo "[API 2] Etiquetando para Zot..."
    sudo ctr images tag $IMG_API2_LOCAL $IMG_API2_REMOTE
    
    echo "[API 2] Subiendo a Zot..."
    sudo ctr images push --plain-http $IMG_API2_REMOTE
    
    echo "Debian Trixie Imágenes de VM1 publicadas."
EOF

# --- VM 2 (API 3) ---
echo ""
echo "--- Procesando VM 2 ($VM2_IP) ---"
ssh $USER@$VM2_IP << EOF
    # 3. API 3
    echo "[API 3] Etiquetando para Zot..."
    sudo ctr images tag $IMG_API3_LOCAL $IMG_API3_REMOTE
    
    echo "[API 3] Subiendo a Zot..."
    sudo ctr images push --plain-http $IMG_API3_REMOTE
    
    echo "Debian Trixie Imagen de VM2 publicada."
EOF

echo ""
echo "=== Proceso Finalizado ==="
echo "Verifica el catálogo con: curl http://${ZOT_IP}:${ZOT_PORT}/v2/_catalog"