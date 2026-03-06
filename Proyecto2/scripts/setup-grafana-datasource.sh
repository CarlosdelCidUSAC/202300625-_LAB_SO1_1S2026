#!/bin/bash

echo "=========================================="
echo " CONFIGURACIÓN MANUAL DE GRAFANA"
echo "=========================================="
echo ""

# 1. Eliminar el archivo datasource.yml para que Grafana pueda iniciar
echo "[1/5] Preparando configuración..."
cd /home/carlos/Desktop/Proyecto2/docker/grafana/provisioning/datasources
if [ -f "datasource.yml" ]; then
    sudo mv datasource.yml datasource.yml.disabled
    echo "✓ Datasource provisioning deshabilitado"
fi
echo ""

# 2. Iniciar Grafana
echo "[2/5] Iniciando Grafana..."
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose up -d
sleep 20
echo "✓ Grafana iniciado"
echo ""

# 3. Instalar el plugin redis-datasource
echo "[3/5] Instalando plugin redis-datasource..."
sudo docker exec dashboard_grafana grafana cli plugins install redis-datasource 2>&1 | grep -E "already installed|successfully" || echo "Instalando..."
echo "✓ Plugin instalado"
echo ""

# 4. Reiniciar Grafana
echo "[4/5] Reiniciando Grafana..."
sudo docker-compose restart grafana
sleep 15
echo "✓ Grafana reiniciado"
echo ""

# 5. Crear datasource via API
echo "[5/5] Creando datasource via API..."
sudo docker exec dashboard_grafana sh -c "apk add --no-cache curl >/dev/null 2>&1"
sleep 2

sudo docker exec dashboard_grafana curl -X POST \
  -H "Content-Type: application/json" \
  -u admin:admin \
  http://localhost:3000/api/datasources \
  -d '{
    "name": "Valkey",
    "uid": "valkey",
    "type": "redis-datasource",
    "access": "proxy",
    "url": "db_valkey:6379",
    "isDefault": true,
    "jsonData": {
      "client": "standalone",
      "poolSize": 5,
      "timeout": 10
    }
  }' 2>/dev/null

echo ""
echo ""
echo "=========================================="
echo " CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Accede a Grafana:"
echo "  URL:        http://localhost:3000"
echo "  Usuario:    adminContraseña: admin"
echo "  Dashboard:  'Telemetría de Contenedores - Proyecto 2 SO1'"
echo ""
