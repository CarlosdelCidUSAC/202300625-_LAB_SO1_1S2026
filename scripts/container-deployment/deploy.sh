#!/bin/bash

# Detener el script si ocurre algún error
set -e

# --- VARIABLES DE ENTORNO ---
USER="carlos"
VM1_IP="192.168.122.10" # Aloja API1 (8081) y API2 (8082)
VM2_IP="192.168.122.20" # Aloja API3 (8083)
VM3_IP="192.168.122.30" # Aloja Zot Registry
IMAGE_DIR="images"

echo "=== [1/6] Iniciando Compilación de Binarios Go ==="

# API 1
echo "-> Compilando API 1..."
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o api-services/API1/api1-bin api-services/API1/main.go

# API 2
echo "-> Compilando API 2..."
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o api-services/API2/api2-bin api-services/API2/main.go

# API 3
echo "-> Compilando API 3..."
env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o api-services/API3/api3-bin api-services/API3/main.go

echo "=== [2/6] Construyendo Imágenes Docker ==="
mkdir -p $IMAGE_DIR

# API 1
echo "-> Docker Build API 1..."
sudo docker build -t api1-202300625 -f api-services/dockerfiles/Dockerfile --build-arg BIN_PATH=api-services/API1/api1-bin .
sudo docker save api1-202300625 > $IMAGE_DIR/api1.tar

# API 2
echo "-> Docker Build API 2..."
sudo docker build -t api2-202300625 -f api-services/dockerfiles/Dockerfile --build-arg BIN_PATH=api-services/API2/api2-bin .
sudo docker save api2-202300625 > $IMAGE_DIR/api2.tar

# API 3
echo "-> Docker Build API 3..."
sudo docker build -t api3-202300625 -f api-services/dockerfiles/Dockerfile --build-arg BIN_PATH=api-services/API3/api3-bin .
sudo docker save api3-202300625 > $IMAGE_DIR/api3.tar

echo "=== [3/6] Transfiriendo Archivos (SCP) ==="
echo "-> Enviando API 1 y 2 a VM1 ($VM1_IP)..."
scp $IMAGE_DIR/api1.tar $IMAGE_DIR/api2.tar $USER@$VM1_IP:/home/$USER/

echo "-> Enviando API 3 a VM2 ($VM2_IP)..."
scp $IMAGE_DIR/api3.tar $USER@$VM2_IP:/home/$USER/

echo "-> Enviando Configuración Zot a VM3 ($VM3_IP)..."
scp -r container-registry/zot-config $USER@$VM3_IP:/home/$USER/zot-config

echo "=== [4/6] Desplegando en VM 1 (API 1 :8081 & API 2 :8082) ==="
ssh -tt $USER@$VM1_IP << 'EOF'
    # Importar imágenes a containerd
    sudo ctr images import api1.tar
    sudo ctr images import api2.tar

    # --- API 1 ---
    echo "Reiniciando api1_service..."
    sudo ctr tasks kill -s SIGKILL api1_service >/dev/null 2>&1 || true
    sudo ctr containers delete api1_service >/dev/null 2>&1 || true
    # Ejecutar en modo net-host para usar puerto 8081 definido en main.go
    sudo ctr run -d --net-host docker.io/library/api1-202300625:latest api1_service

    # --- API 2 ---
    echo "Reiniciando api2_service..."
    sudo ctr tasks kill -s SIGKILL api2_service >/dev/null 2>&1 || true
    sudo ctr containers delete api2_service >/dev/null 2>&1 || true
    # Ejecutar en modo net-host para usar puerto 8082 definido en main.go
    sudo ctr run -d --net-host docker.io/library/api2-202300625:latest api2_service
    
    echo "Estado VM1:"
    sudo ctr tasks ls
EOF

echo "=== [5/6] Desplegando en VM 2 (API 3 :8083) ==="
ssh -tt $USER@$VM2_IP << 'EOF'
    sudo ctr images import api3.tar

    # --- API 3 ---
    echo "Reiniciando api3_service..."
    sudo ctr tasks kill -s SIGKILL api3_service >/dev/null 2>&1 || true
    sudo ctr containers delete api3_service >/dev/null 2>&1 || true
    # Ejecutar en modo net-host para usar puerto 8083 definido en main.go
    sudo ctr run -d --net-host docker.io/library/api3-202300625:latest api3_service
    
    echo "Estado VM2:"
    sudo ctr tasks ls
EOF

echo "=== [6/6] Desplegando Zot en VM 3 ==="
ssh -tt $USER@$VM3_IP << 'EOF'
    if [ "$(sudo docker ps -aq -f name=zot-registry)" ]; then
        sudo docker stop zot-registry
        sudo docker rm zot-registry
    fi
    
    sudo docker run -d \
      --name zot-registry \
      -p 5000:5000 \
      -v /home/carlos/zot-config:/etc/zot \
      ghcr.io/project-zot/zot-linux-amd64:latest
EOF

echo "=== DESPLIEGUE COMPLETADO ==="