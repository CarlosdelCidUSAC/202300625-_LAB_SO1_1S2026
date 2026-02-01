#!/bin/bash

# Comprobar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
  echo "Por favor, ejecuta el script como root (su -c './setup.sh')"
  exit 1
fi

# Variables - Modifica según necesites
USUARIO="carlos"
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

echo "=== 1. Comentando repositorio CD-ROM ==="
sed -i '/cdrom/s/^/#/' /etc/apt/sources.list

echo "=== 2. Actualizando sistema e instalando sudo y dependencias ==="
apt update
apt install -y sudo curl openssh-server

echo "=== 3. Configurando usuario y permisos ==="
# Crear usuario si no existe, si ya existe solo lo añade a sudo
if id "$USUARIO" &>/dev/null; then
    echo "El usuario $USUARIO ya existe."
else
    useradd -m -s /bin/bash "$USUARIO"
    echo "Introduce la contraseña para el usuario $USUARIO:"
    passwd "$USUARIO"
fi
usermod -aG sudo "$USUARIO"

echo "=== 4. Configurando SSH ==="
systemctl enable ssh
systemctl start ssh

echo "=== 5. Configuración de IP Estática ==="
echo "Seleccione el número de nodo para esta VM:"
echo "1) 192.168.122.10"
echo "2) 192.168.122.20"
echo "3) 192.168.122.30"
read -p "Opción [1-3]: " OPCION

case $OPCION in
    1) IP="192.168.122.10" ;;
    2) IP="192.168.122.20" ;;
    3) IP="192.168.122.30" ;;
    *) echo "Opción inválida, saltando configuración de red."; IP="" ;;
esac

if [ -n "$IP" ]; then
    cat <<EOF > /etc/network/interfaces
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $INTERFACE
iface $INTERFACE inet static
    address $IP
    netmask 255.255.255.0
    gateway 192.168.122.1
    dns-nameservers 8.8.8.8 8.8.4.4
EOF
    echo "Configuración de red aplicada para $IP en la interfaz $INTERFACE."
fi

echo "=== CONFIGURACIÓN FINALIZADA ==="
echo "Se recomienda reiniciar el sistema para aplicar todos los cambios."