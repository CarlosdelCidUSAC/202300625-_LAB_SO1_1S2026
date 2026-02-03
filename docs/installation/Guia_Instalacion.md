# Guía de Instalación Completa del Proyecto

**Proyecto:** Desarrollo, Conexión y Gestión de Contenedores en Entornos Virtualizados  
**Carnet:** 202300625  
**Fecha:** Febrero 2026  
**Universidad San Carlos de Guatemala**

---

## Tabla de Contenidos

1. [Prerrequisitos](#prerrequisitos)
2. [Creación de VMs](#creación-de-vms)
3. [Configuración de Red](#configuración-de-red)
4. [Instalación de Runtimes](#instalación-de-runtimes)
5. [Compilación de APIs](#compilación-de-apis)
6. [Construcción de Imágenes](#construcción-de-imágenes)
7. [Configuración de Zot](#configuración-de-zot)
8. [Despliegue de Contenedores](#despliegue-de-contenedores)
9. [Pruebas de Conectividad](#pruebas-de-conectividad)
10. [Solución de Problemas](#solución-de-problemas)

---

## Prerrequisitos

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

## Prerrequisitos

### En el Host (Sistema Principal)

Verificar disponibilidad de herramientas:

```bash
# Verificar KVM
egrep -o 'vmx|svm' /proc/cpuinfo

# Instalar herramientas necesarias
sudo apt-get update
sudo apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    virt-viewer \
    bridge-utils \
    cpu-checker \
    git \
    golang-go \
    docker.io \
    curl \
    wget

# Agregar usuario al grupo libvirt y docker
sudo usermod -aG libvirt $USER
sudo usermod -aG docker $USER
sudo usermod -aG kvm $USER

# Aplicar cambios de grupo
newgrp libvirt
newgrp docker
```

Verificar versiones:

```bash
go version          # go version go1.18+ required
docker --version    # Docker version 20.10+
qemu-system-x86_64 --version  # QEMU version
```

### En las VMs

- **Sistema Operativo:** Ubuntu 22.04 LTS o Debian 12+
- **Recursos Mínimos:**
  - CPU: 2 cores
  - RAM: 2 GB
  - Almacenamiento: 20 GB
- **Acceso:** Usuario con privilegios sudo
- **Red:** Conectividad SSH desde el host

---

## Creación de VMs

### Paso 1: Descargar ISO

```bash
# Ubuntu 22.04 LTS
wget https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso
# O usar el ISO local disponible
```

### Paso 2: Crear Máquinas Virtuales

#### Con virt-manager (GUI)

1. Abre virt-manager: `virt-manager`
2. Clic derecho → "Nueva"
3. Configura:
   - **Nombre:** vm-api1, vm-api2, vm-api3
   - **RAM:** 2048 MB
   - **Discos:** 20 GB
   - **CPUs:** 2
   - **Red:** Red NAT (default libvirt)

#### Con virt-install (CLI)

```bash
# VM1
virt-install \
  --name vm-api1 \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/vm-api1.qcow2,size=20 \
  --cdrom ~/ubuntu-22.04.3-live-server-amd64.iso \
  --network network=default \
  --graphics vnc

# VM2
virt-install \
  --name vm-api2 \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/vm-api2.qcow2,size=20 \
  --cdrom ~/ubuntu-22.04.3-live-server-amd64.iso \
  --network network=default \
  --graphics vnc

# VM3
virt-install \
  --name vm-api3 \
  --memory 2048 \
  --vcpus 2 \
  --disk path=/var/lib/libvirt/images/vm-api3.qcow2,size=20 \
  --cdrom ~/ubuntu-22.04.3-live-server-amd64.iso \
  --network network=default \
  --graphics vnc
```

### Paso 3: Instalación del Sistema Operativo

Durante la instalación en cada VM:

```
Idioma: English
Teclado: Spanish / Español
Red: DHCP (temporal, se fijará después)
Proxy: (dejar en blanco)
Espejo: http://archive.ubuntu.com/ubuntu/
Almacenamiento: Usar disco completo
Nombre usuario: usuario
Hostname: vm-api1, vm-api2, vm-api3
OpenSSH: Seleccionar (importante para acceso remoto)
```

---

## Configuración de Red

### Paso 1: Obtener IPs Dinámicas Iniciales

```bash
# En cada VM
ip a

# Anotar la IP asignada
```

### Paso 2: Configurar IPs Estáticas

Editar `/etc/netplan/00-installer-config.yaml` en cada VM:

**VM1:**

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.122.10/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

**VM2:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.122.20/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

**VM3:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 192.168.122.30/24
      gateway4: 192.168.122.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

Aplicar cambios:

```bash
sudo netplan apply
sudo netplan status  # Verificar
```

Verificar conectividad:

```bash
ping -c 3 8.8.8.8
ip a
```

### Paso 3: Configurar SSH sin Contraseña (Opcional pero Recomendado)

En el host:

```bash
# Generar claves SSH si no existen
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# Copiar clave pública a cada VM
ssh-copy-id usuario@192.168.122.10
ssh-copy-id usuario@192.168.122.20
ssh-copy-id usuario@192.168.122.30

# Verificar
ssh usuario@192.168.122.10 'hostname'
```

---

## Instalación de Runtimes

### En VM1 y VM2: Instalación de Containerd

```bash
# Conectar por SSH
ssh usuario@192.168.122.10

# Actualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar Containerd
sudo apt-get install -y containerd.io

# Habilitar y iniciar servicio
sudo systemctl enable containerd
sudo systemctl start containerd

# Verificar instalación
sudo systemctl status containerd
containerd --version

# Crear directorio de configuración (si no existe)
sudo mkdir -p /etc/containerd

# Generar configuración por defecto
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Reiniciar para aplicar cambios
sudo systemctl restart containerd
```

**Configuración para acceso a Zot Registry:**

Editar `/etc/containerd/config.toml`:

```bash
sudo nano /etc/containerd/config.toml
```

Buscar la sección `[plugins."io.containerd.grpc.v1.cri".registry]` y agregar:

```toml
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.122.30:5000"]
  endpoint = ["http://192.168.122.30:5000"]
```

Reiniciar:

```bash
sudo systemctl restart containerd
```

### En VM3: Instalación de Docker

```bash
# Conectar por SSH
ssh usuario@192.168.122.30

# Actualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar Docker
sudo apt-get install -y docker.io docker-compose

# Habilitar y iniciar servicio
sudo systemctl enable docker
sudo systemctl start docker

# Verificar instalación
sudo systemctl status docker
docker --version

# Agregar usuario al grupo docker (opcional)
sudo usermod -aG docker $USER
```

Configurar Docker para acetar registros inseguros (necesario para Zot sin HTTPS):

```bash
sudo nano /etc/docker/daemon.json
```

```json
{
  "insecure-registries": ["192.168.122.30:5000"]
}
```

Reiniciar Docker:

```bash
sudo systemctl restart docker
```

---

## Compilación de APIs

### Paso 1: Clonar Repositorio

En el host:

```bash
cd ~/Escritorio/Sopes1/SopesDocu
ls -la api-services/
```

### Paso 2: Compilar Binarios Go

```bash
# API1
cd api-services/API1
go build -o api1-bin main.go

# API2
cd ../API2
go build -o api2-bin main.go

# API3
cd ../API3
go build -o api3-bin main.go

# Verificar binarios
ls -lah */\*-bin
```

### Paso 3: Prueba Local (Opcional)

```bash
# Terminal 1
cd api-services/API1
./api1-bin

# Terminal 2 (en otro terminal)
curl http://localhost:8081/health
```

---

## Construcción de Imágenes

### Paso 1: Crear Dockerfiles

Si no existen, crear en cada directorio de API:

**api-services/API1/Dockerfile:**

```dockerfile
FROM golang:1.18-alpine AS builder

WORKDIR /build
COPY main.go .
RUN go build -o api1-bin main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /build/api1-bin .

EXPOSE 8081
CMD ["./api1-bin"]
```

**api-services/API2/Dockerfile:**

```dockerfile
FROM golang:1.18-alpine AS builder

WORKDIR /build
COPY main.go .
RUN go build -o api2-bin main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /build/api2-bin .

EXPOSE 8082
CMD ["./api2-bin"]
```

**api-services/API3/Dockerfile:**

```dockerfile
FROM golang:1.18-alpine AS builder

WORKDIR /build
COPY main.go .
RUN go build -o api3-bin main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /build/api3-bin .

EXPOSE 8083
CMD ["./api3-bin"]
```

### Paso 2: Construir Imágenes

En el host:

```bash
# API1
cd ~/Escritorio/Sopes1/SopesDocu/api-services/API1
docker build -t api1-202300625:latest .

# API2
cd ../API2
docker build -t api2-202300625:latest .

# API3
cd ../API3
docker build -t api3-202300625:latest .

# Verificar imágenes
docker images | grep api
```

---

## Configuración de Zot

### Paso 1: Crear Archivo de Configuración

En `container-registry/zot-config/config.json`:

```json
{
  "distSpecVersion": "1.0.0",
  "storage": {
    "rootDirectory": "/var/lib/zot"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000"
  },
  "log": {
    "level": "info"
  }
}
```

### Paso 2: Crear Dockerfile para Zot

**container-registry/Dockerfile:**

```dockerfile
FROM ghcr.io/project-zot/zot:latest

COPY zot-config/config.json /etc/zot/config.json
RUN mkdir -p /var/lib/zot

EXPOSE 5000
ENTRYPOINT ["/zot"]
CMD ["serve", "/etc/zot/config.json"]
```

---

## Despliegue de Contenedores

### En VM1: Desplegar API1 y API2

```bash
ssh usuario@192.168.122.10

# Crear directorio de trabajo
mkdir -p ~/apis

# Copiar binarios compilados (desde host)
# scp ~/Escritorio/Sopes1/SopesDocu/api-services/API1/api1-bin usuario@192.168.122.10:~/apis/
# scp ~/Escritorio/Sopes1/SopesDocu/api-services/API2/api2-bin usuario@192.168.122.10:~/apis/

# Crear imágenes en VM1 (alternativa: transferir con ctr)
# ... (o usar lo siguiente)

# Descargar y ejecutar imágenes desde Zot (después de estar configurado)
sudo ctr images pull 192.168.122.30:5000/api1-202300625:latest
sudo ctr images pull 192.168.122.30:5000/api2-202300625:latest

# Ejecutar contenedores
sudo ctr run -d --net-host 192.168.122.30:5000/api1-202300625:latest api1-container
sudo ctr run -d --net-host 192.168.122.30:5000/api2-202300625:latest api2-container

# Listar contenedores ejecutándose
sudo ctr containers ls
```

### En VM2: Desplegar API3

```bash
ssh usuario@192.168.122.20

# Descargar imagen
sudo ctr images pull 192.168.122.30:5000/api3-202300625:latest

# Ejecutar contenedor
sudo ctr run -d --net-host 192.168.122.30:5000/api3-202300625:latest api3-container

# Verificar
sudo ctr containers ls
```

### En VM3: Desplegar Zot Registry

```bash
ssh usuario@192.168.122.30

# Crear estructura de directorios
sudo mkdir -p /var/lib/zot

# Descargar imagen Zot
docker pull ghcr.io/project-zot/zot:latest

# Ejecutar contenedor
docker run -d \
  --name zot-registry \
  -p 5000:5000 \
  -v /etc/zot:/etc/zot \
  -v /var/lib/zot:/var/lib/zot \
  ghcr.io/project-zot/zot:latest serve /etc/zot/config.json

# Verificar
docker ps | grep zot
docker logs zot-registry
```

---

## Pruebas de Conectividad

### Prueba 1: Health Endpoints

```bash
# Desde el host o cualquier máquina con acceso a la red

# API1
curl -s http://192.168.122.10:8081/health | jq .

# API2
curl -s http://192.168.122.10:8082/health | jq .

# API3
curl -s http://192.168.122.20:8083/health | jq .
```

### Prueba 2: Comunicación entre APIs

```bash
# API2 llamando a API1
curl -s http://192.168.122.10:8082/api2/202300625/call-api1 | jq .

# API1 llamando a API3
curl -s http://192.168.122.10:8081/api1/202300625/call-api3 | jq .

# API3 llamando a API2
curl -s http://192.168.122.20:8083/api3/202300625/call-api2 | jq .

# API3 llamando a API1
curl -s http://192.168.122.20:8083/api3/202300625/call-api1 | jq .
```

### Prueba 3: Registro Zot

```bash
# Verificar que el registro está activo
curl -s http://192.168.122.30:5000/v2/ | jq .

# Subir imágenes (desde host o VM1)
docker tag api1-202300625:latest 192.168.122.30:5000/api1-202300625:latest
docker push 192.168.122.30:5000/api1-202300625:latest

# Listar imágenes en Zot
curl -s http://192.168.122.30:5000/v2/_catalog | jq .
```

---

## Solución de Problemas

### Problema: No puedo conectar a las VMs

**Solución:**

```bash
# Verificar estado de VMs
virsh list --all

# Iniciar VM
virsh start vm-api1

# Verificar red
virsh net-list
virsh net-info default
```

### Problema: No tengo conectividad de red en la VM

**Solución:**

```bash
# En la VM
sudo netplan apply
sudo systemctl restart networking

# Verificar configuración
ip a
route -n
```

### Problema: Containerd no inicia

**Solución:**

```bash
# Revisar logs
sudo journalctl -u containerd -n 50

# Verificar configuración
sudo containerd config dump
```

### Problema: Los contenedores no pueden comunicarse entre VMs

**Solución:**

```bash
# Verificar DNS
ping -c 3 192.168.122.20

# Verificar rutas
route -n

# Verificar firewalls
sudo ufw status

# Si está activo, permitir puertos
sudo ufw allow 8081:8083/tcp
```

---

**Última actualización:** Febrero 2, 2026  
**Autor:** Carnet 202300625
