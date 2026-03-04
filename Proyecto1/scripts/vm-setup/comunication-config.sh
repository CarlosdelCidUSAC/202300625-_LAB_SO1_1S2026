#!/bin/bash

# 1. Habilitar el reenvío de paquetes (IP Forwarding) en el kernel
sysctl -w net.ipv4.ip_forward=1

# Limpiar reglas NAT anteriores (Opcional, ten cuidado si tienes Docker u otras reglas)
# iptables -t nat -F PREROUTING

# ==========================================
# VM 1 (192.168.122.10) - API1 y API2
# ==========================================
# Exponer puerto 8081 (API1)
iptables -t nat -A PREROUTING -p tcp --dport 8081 -j DNAT --to-destination 192.168.122.10:8081
# Exponer puerto 8082 (API2)
iptables -t nat -A PREROUTING -p tcp --dport 8082 -j DNAT --to-destination 192.168.122.10:8082

# ==========================================
# VM 2 (192.168.122.20) - API3
# ==========================================
# Exponer puerto 8083 (API3)
iptables -t nat -A PREROUTING -p tcp --dport 8083 -j DNAT --to-destination 192.168.122.20:8083

# ==========================================
# VM 3 (192.168.122.30) - Zot Registry
# ==========================================
# Exponer puerto 5000 (Zot)
iptables -t nat -A PREROUTING -p tcp --dport 5000 -j DNAT --to-destination 192.168.122.30:5000

# ==========================================
# PERMISOS DE FORWARDING
# ==========================================
# Permitir que el tráfico pase del exterior hacia la red virtual 192.168.122.0/24
iptables -I FORWARD -m state -d 192.168.122.0/24 --state NEW,RELATED,ESTABLISHED -j ACCEPT

echo "Reglas de iptables aplicadas correctamente."