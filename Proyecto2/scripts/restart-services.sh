#!/bin/bash

echo "=========================================="
echo " REINICIANDO SERVICIOS - PROYECTO 2 SO1"
echo "=========================================="
echo ""

# 1. Detener servicios actuales
echo "[1/6] Deteniendo servicios actuales..."
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose down
echo "✓ Servicios detenidos"
echo ""

# 2. Recompilar daemon de GO
echo "[2/6] Recompilando daemon de GO..."
cd /home/carlos/Desktop/Proyecto2/daemon-go
go build -o bin/daemon-so1-fase4 cmd/daemon/main.go
if [ $? -eq 0 ]; then
    echo "✓ Daemon compilado correctamente"
else
    echo "✗ Error al compilar el daemon"
    exit 1
fi
echo ""

# 3. Recargar módulo kernel
echo "[3/6] Recargando módulo kernel..."
sudo rmmod sonda 2>/dev/null || true
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
if [ $? -eq 0 ]; then
    echo "✓ Módulo kernel cargado"
else
    echo "✗ Error al cargar módulo"
    exit 1
fi
echo ""

# 4. Iniciar docker-compose
echo "[4/6] Iniciando servicios con Docker Compose..."
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose up -d
if [ $? -eq 0 ]; then
    echo "✓ Servicios iniciados"
else
    echo "✗ Error al iniciar servicios"
    exit 1
fi
echo ""

# 5. Esperar a que Grafana esté listo
echo "[5/6] Esperando a que Grafana esté listo..."
sleep 15
echo "✓ Servicios deberían estar listos"
echo ""

# 6. Mostrar información
echo "[6/6] Información del sistema:"
echo ""
echo "  Grafana:       http://localhost:3000"
echo "  Usuario:       admin"
echo "  Contraseña:    admin"
echo ""
echo "  Valkey:        localhost:6379"
echo ""
echo "  Contenedores activos:"
sudo docker ps --format "    - {{.Names}} ({{.Image}})"
echo ""
echo "=========================================="
echo " SISTEMA LISTO"
echo "=========================================="
echo ""
echo "Próximos pasos:"
echo "  1. Abrir Grafana en http://localhost:3000"
echo "  2. Ir a Dashboards y buscar 'Telemetría de Contenedores'"
echo "  3. Ejecutar el daemon de GO en otra terminal:"
echo "     cd /home/carlos/Desktop/Proyecto2/daemon-go"
echo "     sudo ./bin/daemon-so1-fase4"
echo ""
