# Guía de Instalación

Esta guía permite replicar el proyecto desde cero en un entorno con KVM y 3 VMs.

---

## 1. Prerrequisitos

### En el host (Linux)
- KVM/QEMU + libvirt + virt-manager
- Bridge de red configurado
- Git
- Go (para compilar binarios)
- Docker (para construir imágenes localmente)
- SSH habilitado

### En las VMs
- Debian 13 Trixie
- Usuario con permisos sudo
- Acceso por SSH entre host y VMs

---

## 2. Creación y configuración de VMs

1. Crea 3 VMs con los recursos indicados en [vm-config/README.md](../../vm-config/README.md).
2. Asigna IPs estáticas:
   - VM1: 192.168.122.10
   - VM2: 192.168.122.20
   - VM3: 192.168.122.30
3. En cada VM, ejecuta el script de preparación:
   - [scripts/vm-setup/setup.sh](../../scripts/vm-setup/setup.sh)

---

## 3. Instalación de runtimes

### VM1 y VM2: Containerd
```bash
sudo apt update
sudo apt install -y containerd
sudo systemctl enable containerd
sudo systemctl start containerd
```

### VM3: Docker Engine
```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
```

---

## 4. Despliegue del registro ZOT

En VM3:
```bash
# Copiar configuración
mkdir -p /home/carlos/zot-config
# (el archivo se transfiere desde el host con el script de deploy)

# Ejecutar el contenedor
sudo docker run -d \
  --name zot-registry \
  -p 5000:5000 \
  -v /home/carlos/zot-config:/etc/zot \
  ghcr.io/project-zot/zot-linux-amd64:latest
```

La configuración del registro está en [container-registry/zot-config](../../container-registry/zot-config).

---

## 5. Ejecución del proyecto

En el host:
1. Compilar binarios Go y construir imágenes.
2. Enviar imágenes a VM1 y VM2.
3. Desplegar contenedores en Containerd.
4. Levantar ZOT en VM3.

Todo lo anterior está automatizado en:
- [scripts/container-deployment/deploy.sh](../../scripts/container-deployment/deploy.sh)

> Ajusta `USER` e IPs en el script si tu entorno es diferente.

---

## 6. Validación rápida

Ejecuta pruebas básicas desde el host o cualquier VM con acceso a la red:
```bash
# API1
curl http://192.168.122.10:8081/health

# API2 -> API1
curl http://192.168.122.10:8082/api2/202300625/call-api1

# API1 -> API3
curl http://192.168.122.10:8081/api1/202300625/call-api3

# API3 -> API2
curl http://192.168.122.20:8083/api3/202300625/call-api2
```

---

## 7. Evidencia de pruebas

Registra logs o capturas según lo descrito en:
- [docs/operations/Evidencia_Pruebas.md](../operations/Evidencia_Pruebas.md)
