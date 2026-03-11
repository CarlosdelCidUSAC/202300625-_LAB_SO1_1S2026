#!/bin/bash

set -euo pipefail

echo "=========================================="
echo " CONFIGURACION DE GRAFANA"
echo "=========================================="
echo ""

# Credenciales para validacion final (sobrescribir por variable de entorno si aplica)
GRAFANA_USER="${GRAFANA_USER:-daemon-so1}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-1234}"

# 1. Asegurar archivo de provisioning del datasource
echo "[1/4] Preparando provisioning..."
cd /home/carlos/Desktop/Proyecto2/docker/grafana/provisioning/datasources
if [ -f "datasource.yml.disabled" ] && [ ! -f "datasource.yml" ]; then
    mv datasource.yml.disabled datasource.yml
fi

if [ ! -f "datasource.yml" ]; then
    echo "✗ No existe datasource.yml en provisioning"
    exit 1
fi

echo "✓ Datasource provisioning habilitado"
echo ""

# 2. Iniciar Grafana
echo "[2/4] Iniciando stack Docker..."
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose up -d
sleep 20
echo "✓ Stack iniciado"
echo ""

# 3. Instalar el plugin redis-datasource
echo "[3/4] Reiniciando Grafana para reprovisionar..."
sudo docker-compose restart grafana
sleep 15
echo "✓ Grafana reiniciado"
echo ""

# 4. Validar datasource provisionado
echo "[4/4] Validando datasource en Grafana..."
if sudo docker exec dashboard_grafana sh -lc "curl -fsS -u ${GRAFANA_USER}:${GRAFANA_PASSWORD} http://localhost:3000/api/datasources/uid/valkey >/dev/null"; then
    echo "✓ Datasource 'valkey' disponible"
else
    echo "⚠ No se pudo validar via API (credenciales distintas o Grafana aun inicializando)."
    echo "  El provisioning queda activo y se aplicara en el arranque."
fi

echo ""
echo ""
echo "=========================================="
echo " CONFIGURACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "Accede a Grafana:"
echo "  URL:        http://localhost:3000"
echo "  Usuario:    ${GRAFANA_USER}"
echo "  Contraseña: ${GRAFANA_PASSWORD}"
echo "  Dashboard:  'Telemetría de Contenedores - Proyecto 2 SO1'"
echo ""
