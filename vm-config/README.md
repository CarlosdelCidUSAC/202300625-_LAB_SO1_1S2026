# Configuración de Máquinas Virtuales (VMs)

Esta carpeta contiene la configuración para las 3 máquinas virtuales requeridas en el proyecto.

## Estructura

- `vm1-services/` - VM para servicios principales
- `vm2-registry/` - VM para registro de contenedores
- `vm3-monitoring/` - VM para monitoreo y logs

## Especificaciones de cada VM según requerimientos

### VM1: Containerd Runtime (vm1-containerd)
- **Propósito**: Host para API1 y API2
- **Runtime**: Containerd
- **Sistema Operativo**: Ubuntu Server 22.04 LTS
- **Recursos**:
  - CPU: 2 cores
  - RAM: 4GB
  - Disco: 40GB
  - Red: Bridge network (192.168.100.10)
- **Contenedores a ejecutar**:
  - API1-202300625 (puerto 8081)
  - API2-202300625 (puerto 8082)
- **Configuración específica**:
  - Instalar Containerd
  - Configurar red para comunicación con otras VMs
  - Habilitar comunicación entre contenedores

### VM2: Containerd Runtime (vm2-containerd)
- **Propósito**: Host para API3
- **Runtime**: Containerd
- **Sistema Operativo**: Ubuntu Server 22.04 LTS
- **Recursos**:
  - CPU: 2 cores
  - RAM: 4GB
  - Disco: 40GB
  - Red: Bridge network (192.168.100.20)
- **Contenedores a ejecutar**:
  - API3-202300625 (puerto 8083)
- **Configuración específica**:
  - Instalar Containerd
  - Configurar red para comunicación con otras VMs

### VM3: Docker Runtime (vm3-docker)
- **Propósito**: Host para ZOT Registry
- **Runtime**: Docker
- **Sistema Operativo**: Ubuntu Server 22.04 LTS
- **Recursos**:
  - CPU: 2 cores
  - RAM: 4GB
  - Disco: 60GB (50GB para almacenamiento de imágenes)
  - Red: Bridge network (192.168.100.30)
- **Contenedores a ejecutar**:
  - zot-202300625 (puerto 5000)
- **Configuración específica**:
  - Instalar Docker Engine
  - Configurar ZOT Registry
  - Configurar autenticación básica
  - Generar certificados SSL/TLS

## Configuración de Red

Todas las VMs estarán en la misma red bridge para permitir comunicación:
- Subnet: 192.168.100.0/24
- VM1: 192.168.100.10
- VM2: 192.168.100.20
- VM3: 192.168.100.30
- Gateway: 192.168.100.1

## Scripts de Creación

Los scripts para crear y configurar las VMs se encuentran en `../scripts/vm-setup/`