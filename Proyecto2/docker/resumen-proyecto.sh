#!/bin/bash

# Script de resumen del estado del proyecto
# Muestra una vista rápida de todos los componentes

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         PROYECTO 2 - SISTEMA OPERATIVOS 1                 ║"
echo "║    Sonda de Kernel + Daemon GO + Dashboard Grafana        ║"
echo "║                  Carnet: 202300625                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Función para check ok/fail
check_status() {
    if [ $1 -eq 0 ]; then
        echo "✅ OK"
    else
        echo "❌ FAIL"
    fi
}

# 1. MÓDULO KERNEL
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 MÓDULO DE KERNEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  Código fuente (sonda.c): "
[ -f /home/carlos/Desktop/Proyecto2/kernel-module/src/sonda.c ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  Makefile: "
[ -f /home/carlos/Desktop/Proyecto2/kernel-module/Makefile ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  Módulo compilado (sonda.ko): "
if [ -f /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko ]; then
    SIZE=$(du -h /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko | cut -f1)
    echo "✅ Existe ($SIZE)"
else
    echo "❌ No compilado"
fi

echo -n "  Estado en kernel: "
if lsmod | grep -q "sonda"; then
    echo "✅ CARGADO"
else
    echo "⚪ no cargado"
fi

echo -n "  Archivo /proc: "
if [ -f /proc/continfo_pr2_so1_202300625 ]; then
    LINES=$(wc -l < /proc/continfo_pr2_so1_202300625)
    echo "✅ Existe ($LINES líneas)"
else
    echo "❌ No existe"
fi
echo ""

# 2. DAEMON GO
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔷 DAEMON DE GO"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  Código fuente (main.go): "
[ -f /home/carlos/Desktop/Proyecto2/daemon-go/cmd/daemon/main.go ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  go.mod: "
[ -f /home/carlos/Desktop/Proyecto2/daemon-go/go.mod ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  Paquetes internos: "
PACKAGES=$(find /home/carlos/Desktop/Proyecto2/daemon-go/internal -name "*.go" | wc -l)
echo "✅ $PACKAGES archivos"

echo -n "  Binario compilado: "
if [ -f /home/carlos/Desktop/Proyecto2/daemon-go/bin/daemon-so1 ]; then
    SIZE=$(du -h /home/carlos/Desktop/Proyecto2/daemon-go/bin/daemon-so1 | cut -f1)
    echo "✅ Existe ($SIZE)"
else
    echo "❌ No compilado"
fi

echo -n "  Estado del daemon: "
if pgrep -f "daemon-so1" > /dev/null; then
    echo "✅ CORRIENDO"
else
    echo "⚪ no está corriendo"
fi
echo ""

# 3. CRONJOB
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏰ CRONJOB"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  Scripts cron: "
[ -f /home/carlos/Desktop/Proyecto2/cron/install-cron.sh ] && echo "✅ Existen" || echo "❌ No encontrados"

echo -n "  Script generador: "
[ -f /home/carlos/Desktop/Proyecto2/docker/generar.sh ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  Estado en crontab: "
if crontab -l 2>/dev/null | grep -q "generar.sh"; then
    echo "✅ INSTALADO"
    crontab -l 2>/dev/null | grep "generar.sh"
else
    echo "⚪ no instalado"
fi
echo ""

# 4. DOCKER
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 INFRAESTRUCTURA DOCKER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  docker-compose.yml: "
[ -f /home/carlos/Desktop/Proyecto2/docker/docker-compose.yml ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  Contenedor Grafana: "
if sudo docker ps 2>/dev/null | grep -q "dashboard_grafana"; then
    echo "✅ CORRIENDO (http://localhost:3000)"
else
    echo "❌ Detenido"
fi

echo -n "  Contenedor Valkey: "
if sudo docker ps 2>/dev/null | grep -q "db_valkey"; then
    echo "✅ CORRIENDO (puerto 6379)"
else
    echo "❌ Detenido"
fi

echo -n "  Contenedores de prueba: "
CONTAINER_COUNT=$(sudo docker ps 2>/dev/null | grep -c -E 'alpine|go-client' || echo 0)
echo "$CONTAINER_COUNT activos"

echo -n "  Dashboard provisionado: "
[ -f /home/carlos/Desktop/Proyecto2/docker/grafana/provisioning/dashboards/contenedores-dashboard.json ] && echo "✅ Existe" || echo "❌ No encontrado"
echo ""

# 5. VALKEY
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💾 ALMACENAMIENTO EN VALKEY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if sudo docker ps 2>/dev/null | grep -q "db_valkey"; then
    echo -n "  Conexión: "
    if sudo docker exec db_valkey valkey-cli PING 2>/dev/null | grep -q "PONG"; then
        echo "✅ Activa"
    else
        echo "❌ Sin conexión"
    fi
    
    echo -n "  Métricas de memoria: "
    MEM_KEYS=$(sudo docker exec db_valkey valkey-cli EXISTS metrics:memory:current 2>/dev/null || echo 0)
    [ "$MEM_KEYS" = "1" ] && echo "✅ Almacenadas" || echo "⚪ sin datos"
    
    echo -n "  Top contenedores RAM: "
    RAM_COUNT=$(sudo docker exec db_valkey valkey-cli ZCARD metrics:containers:ram:top 2>/dev/null || echo 0)
    echo "$RAM_COUNT entradas"
    
    echo -n "  Contenedores eliminados: "
    DELETED=$(sudo docker exec db_valkey valkey-cli GET stats:containers_deleted 2>/dev/null || echo 0)
    echo "$DELETED en total"
else
    echo "  ⚪ Valkey no está corriendo"
fi
echo ""

# 6. SCRIPTS DE VERIFICACIÓN
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 SCRIPTS DE VERIFICACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  verificar-requisitos.sh: "
[ -x /home/carlos/Desktop/Proyecto2/tests/verificar-requisitos.sh ] && echo "✅ Listo" || echo "❌ No ejecutable"

echo -n "  limpiar-entorno.sh: "
[ -x /home/carlos/Desktop/Proyecto2/tests/limpiar-entorno.sh ] && echo "✅ Listo" || echo "❌ No ejecutable"

echo -n "  Reportes generados: "
REPORTS=$(ls -1 /home/carlos/Desktop/Proyecto2/docs/evidencias/verificacion_*.txt 2>/dev/null | wc -l)
echo "$REPORTS encontrados"
echo ""

# 7. DOCUMENTACIÓN
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 DOCUMENTACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "  README_VERIFICACION.md: "
[ -f /home/carlos/Desktop/Proyecto2/tests/README_VERIFICACION.md ] && echo "✅ Existe" || echo "❌ No encontrado"

echo -n "  GUIA_DEMOSTRACION.md: "
[ -f /home/carlos/Desktop/Proyecto2/GUIA_DEMOSTRACION.md ] && echo "✅ Existe" || echo "❌ No encontrado"
echo ""

# RESUMEN FINAL
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 RESUMEN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🎯 Para verificar cumplimiento completo:"
echo "     sudo ./tests/verificar-requisitos.sh"
echo ""
echo "  🚀 Para iniciar demostración:"
echo "     1. cd daemon-go"
echo "     2. sudo ./bin/daemon-so1"
echo "     3. Abrir http://localhost:3000 (daemon-so1/1234)"
echo ""
echo "  📖 Para ver guía completa:"
echo "     cat GUIA_DEMOSTRACION.md"
echo ""
echo "  🧹 Para limpiar entorno:"
echo "     sudo ./tests/limpiar-entorno.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
