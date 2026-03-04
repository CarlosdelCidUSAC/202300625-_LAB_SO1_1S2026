#!/bin/bash
# Script para solucionar el problema de conectividad API3 -> API2

USER="carlos"
VM1_IP="192.168.122.10"
VM2_IP="192.168.122.20"

echo "=== SOLUCIONANDO PROBLEMA DE CONECTIVIDAD ==="

echo ""
echo "[1/3] Configurando Firewall en VM1..."
ssh $USER@$VM1_IP << 'EOF'
    echo "-> Permitiendo tráfico desde VM2 (192.168.122.20) a puertos 8081-8082"
    
    # Opción 1: Si usa firewalld
    sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.20" port protocol="tcp" port="8081-8082" accept' 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    
    # Opción 2: Si usa iptables
    sudo iptables -I INPUT -s 192.168.122.20 -p tcp --dport 8081:8082 -j ACCEPT 2>/dev/null || true
    
    # Opción 3: Si usa ufw
    sudo ufw allow from 192.168.122.20 to any port 8081:8082 proto tcp 2>/dev/null || true
    
    echo "-> Estado del firewall:"
    sudo firewall-cmd --list-all 2>/dev/null || sudo iptables -L INPUT -n -v | grep 8081 || sudo ufw status | grep 8081 || echo "No se pudo verificar firewall"
EOF

echo ""
echo "[2/3] Configurando Firewall en VM2..."
ssh $USER@$VM2_IP << 'EOF'
    echo "-> Permitiendo tráfico desde VM1 (192.168.122.10) a puerto 8083"
    
    # Opción 1: firewalld
    sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.122.10" port protocol="tcp" port="8083" accept' 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    
    # Opción 2: iptables
    sudo iptables -I INPUT -s 192.168.122.10 -p tcp --dport 8083 -j ACCEPT 2>/dev/null || true
    
    # Opción 3: ufw
    sudo ufw allow from 192.168.122.10 to any port 8083 proto tcp 2>/dev/null || true
EOF

echo ""
echo "[3/3] Verificando Conectividad..."

echo ""
echo "-> Desde VM2 hacia API2 en VM1:"
ssh $USER@$VM2_IP "curl -s --connect-timeout 3 http://192.168.122.10:8082/health || echo 'FALLO: No se puede conectar'"

echo ""
echo "-> Desde VM2 hacia API1 en VM1:"
ssh $USER@$VM2_IP "curl -s --connect-timeout 3 http://192.168.122.10:8081/health || echo 'FALLO: No se puede conectar'"

echo ""
echo "-> Desde VM1 hacia API3 en VM2:"
ssh $USER@$VM1_IP "curl -s --connect-timeout 3 http://192.168.122.20:8083/health || echo 'FALLO: No se puede conectar'"

echo ""
echo "=== DIAGNÓSTICO COMPLETO ==="
echo ""
echo "Si aún hay fallos, ejecuta manualmente en cada VM:"
echo ""
echo "# En VM1:"
echo "  sudo systemctl status firewalld"
echo "  sudo firewall-cmd --list-all"
echo "  sudo netstat -tlnp | grep ':808'"
echo ""
echo "# En VM2:"
echo "  telnet 192.168.122.10 8082"
echo "  curl -v http://192.168.122.10:8082/health"