#!/bin/bash

echo "=========================================="
echo " TEST RÁPIDO - DASHBOARD GRAFANA"
echo "=========================================="
echo ""

# 1. Verificar que Valkey esté corriendo
echo "[1/5] Verificando Valkey..."
if sudo docker ps | grep -q db_valkey; then
    echo "✓ Valkey está corriendo"
else
    echo "✗ Valkey no está corriendo"
    echo "   Ejecuta: sudo docker-compose up -d"
    exit 1
fi
echo ""

# 2. Verificar que Grafana esté corriendo
echo "[2/5] Verificando Grafana..."
if sudo docker ps | grep -q dashboard_grafana; then
    echo "✓ Grafana está corriendo"
else
    echo "✗ Grafana no está corriendo"
    echo "   Ejecuta: sudo docker-compose up -d"
    exit 1
fi
echo ""

# 3. Insertar datos de prueba en Valkey
echo "[3/5] Insertando datos de prueba en Valkey..."
sudo docker exec db_valkey redis-cli HSET metrics:memory:current total 4096 used 3200 free 896 timestamp $(date +%s) > /dev/null
sudo docker exec db_valkey redis-cli SET stats:containers_deleted 5 > /dev/null
sudo docker exec db_valkey redis-cli ZADD metrics:containers:ram:top 25.5 "12345:grafana:256MB" > /dev/null
sudo docker exec db_valkey redis-cli ZADD metrics:containers:ram:top 15.2 "12346:valkey:128MB" > /dev/null
sudo docker exec db_valkey redis-cli ZADD metrics:containers:cpu:top 85.0 "12345:grafana:85%" > /dev/null
sudo docker exec db_valkey redis-cli ZADD metrics:containers:cpu:top 45.0 "12346:valkey:45%" > /dev/null
echo "✓ Datos de prueba insertados"
echo ""

# 4. Verificar que los datos estén en Valkey
echo "[4/5] Verificando datos en Valkey..."
TOTAL=$(sudo docker exec db_valkey redis-cli HGET metrics:memory:current total)
DELETED=$(sudo docker exec db_valkey redis-cli GET stats:containers_deleted)
echo "  RAM Total: $TOTAL MB"
echo "  Contenedores eliminados: $DELETED"
echo "✓ Datos verificados"
echo ""

# 5. Información de acceso
echo "[5/5] Dashboard de Grafana:"
echo ""
echo "  URL:        http://localhost:3000"
echo "  Usuario:    admin"
echo "  Contraseña: admin"
echo ""
echo "  Dashboard:  'Telemetría de Contenedores - Proyecto 2 SO1'"
echo ""
echo "=========================================="
echo " TEST COMPLETADO"
echo "=========================================="
echo ""
echo "Los datos de prueba están listos."
echo "Abre Grafana y verifica que los paneles muestren información."
echo ""
