# Proyecto: Desarrollo, Conexión y Gestión de Contenedores en Entornos Virtualizados

**Asignatura:** Sistemas Operativos 1  
**Carnet:** 202300625  
**Universidad:** San Carlos de Guatemala  
**Período:** Febrero 2026  
**Puntuación:** 15 pts

---

## Resumen del Proyecto

Este proyecto implementa un entorno virtualizado completo que simula infraestructura moderna de desarrollo, integrando:

- **3 Máquinas Virtuales** con KVM/QEMU
- **3 APIs REST** desarrolladas en Go
- **Dos runtimes de contenedores:** Containerd (VM1, VM2) y Docker (VM3)
- **Registro privado Zot** para almacenamiento de imágenes
- **Comunicación inter-API** mediante REST/HTTP

### Objetivos Alcanzados

 **Virtualización:** Instalación y configuración de KVM con 3 VMs  
 **Contenerización:** Uso de Containerd y Docker  
 **APIs REST:** Implementación en Go con comunicación bidireccional  
 **Registros privados:** Configuración de Zot para distribución de imágenes  
 **Documentación completa:** Manual técnico, guía de instalación y evidencia

---

## Estructura del Proyecto

```
├── api-services/                    # Código fuente de APIs
│   ├── API1/
│   │   ├── main.go                 # Código API1
│   │   ├── api1-bin                # Binario compilado
│   │   └── Dockerfile              # Imagen Docker
│   ├── API2/
│   │   ├── main.go
│   │   ├── api2-bin
│   │   └── Dockerfile
│   ├── API3/
│   │   ├── main.go
│   │   ├── api3-bin
│   │   └── Dockerfile
│   └── common/                      # Código compartido
│
├── container-registry/              # Configuración Zot
│   ├── certificates/                # Certificados (si aplica)
│   ├── images-backup/              # Copias de seguridad
│   ├── zot-config/
│   │   └── config.json             # Configuración de Zot
│   └── Dockerfile
│
├── deployment/                      # Scripts de despliegue
│   └── (archivos de configuración)
│
├── docs/                            # Documentación
│   ├── api-docs/
│   │   └── COMUNICACION_APIS.md    # Especificaciones de API
│   ├── architecture/
│   │   └── Manual_Tecnico.md       # Arquitectura y diseño
│   ├── installation/
│   │   └── Guia_Instalacion.md     # Guía paso a paso
│   ├── operations/
│   │   ├── Evidencia_Pruebas.md    # Resultados de pruebas
│   │   └── assets/                 # Capturas de pantalla
│   └── troubleshooting/            # Solución de problemas
│
├── logs/                            # Logs de ejecución
│   ├── api1-health.log
│   ├── api2-call-api1-ok.log
│   ├── api1-call-api3-error.log
│   └── (otros logs)
│
├── scripts/                         # Scripts auxiliares
│   ├── publish-images.sh            # Publicar imágenes a Zot
│   ├── pull_update.sh               # Actualizar imágenes
│   ├── container-deployment/
│   │   ├── deploy.sh                # Despliegue automático
│   │   └── rebuild_api3.sh          # Reconstruir API3
│   ├── logs/
│   │   ├── generate-logs.sh         # Generar logs
│   │   ├── view-logs.sh             # Ver logs
│   │   └── clean-logs.sh            # Limpiar logs
│   └── vm-setup/
│       └── setup.sh                 # Configuración de VMs
│
├── network-config/                  # Configuración de red
│   ├── fix-firewall.sh
│   └── logs/
│
├── monitoring/                      # Monitoreo
│
└── README.md                        # Este archivo
```

---

## Arquitectura

### Topología de VMs

```
┌─────────────────────────────────────────────┐
│         Host (KVM/QEMU Hypervisor)          │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────┐  ┌──────────────┐         │
│  │    VM1       │  │    VM2       │         │
│  │ Containerd   │  │ Containerd   │         │
│  ├──────────────┤  ├──────────────┤         │
│  │ API1:8081    │  │ API3:8083    │         │
│  │ API2:8082    │  │              │         │
│  │              │  │              │         │
│  │ 192.168.122. │  │ 192.168.122. │         │
│  │ 10           │  │ 20           │         │
│  └──────────────┘  └──────────────┘         │
│                                             │
│        ┌──────────────────────┐             │
│        │       VM3            │             │
│        │  Docker + Zot:5000   │             │
│        │  192.168.122.30      │             │
│        └──────────────────────┘             │
│                                             │
│     ┌──────────────────────────────┐        │
│     │  Red NAT (192.168.122.0/24)  │        │
│     └──────────────────────────────┘        │
└─────────────────────────────────────────────┘
```

### Matriz de Comunicación

| Origen | Destino | Puerto | Protocolo | Estado |
|--------|---------|--------|-----------|--------|
| API1 | API2 | 8082 | HTTP/JSON | localhost |
| API1 | API3 | 8083 | HTTP/JSON | red (192.168.122.20) |
| API2 | API1 | 8081 | HTTP/JSON | localhost |
| API2 | API3 | 8083 | HTTP/JSON | red (192.168.122.20) |
| API3 | API1 | 8081 | HTTP/JSON | red (192.168.122.10) |
| API3 | API2 | 8082 | HTTP/JSON | red (192.168.122.10) |

---

## Especificaciones Técnicas

### APIs REST

Cada API implementa 3 endpoints:

#### 1. Health Endpoint
```
GET /health
Respuesta: {"status": "UP", "message": "API# is Ready", ...}
```

#### 2. Call to API2/API3
```
GET /api#/{CARNET}/call-api#
Respuesta: {"apiname": "API#", "message": "...", "connection": true/false}
```

### Formatos de Respuesta

**Health (200 OK):**
```json
{
  "status": "UP",
  "message": "API1 is Ready",
  "timestamp": "2026-02-02T10:30:00Z",
  "VM": "VM1",
  "carnet": "202300625"
}
```

**Call Exitosa (200 OK):**
```json
{
  "apiname": "API2",
  "message": "The API2 located on the VM1 is working",
  "connection": true,
  "carnet": "202300625"
}
```

**Call Fallida (200 OK con error):**
```json
{
  "apiname": "API3",
  "message": "ERROR: The API3 located on the VM2 is not working",
  "connection": false,
  "carnet": "202300625"
}
```

---

## Instalación Rápida

### Prerrequisitos

- KVM/QEMU instalado
- 6 GB RAM disponibles (2GB x 3 VMs)
- 60 GB almacenamiento disponible (20GB x 3 VMs)
- Go 1.18+, Docker 20.10+

### Pasos Principales

```bash
# 1. Crear VMs con las IPs estáticas
# Ver docs/installation/Guia_Instalacion.md

# 2. Instalar runtimes en VMs
# VM1 y VM2: Containerd
# VM3: Docker

# 3. Compilar APIs
cd api-services/API1 && go build -o api1-bin main.go
cd api-services/API2 && go build -o api2-bin main.go
cd api-services/API3 && go build -o api3-bin main.go

# 4. Construir imágenes
docker build -t api1-202300625 api-services/API1
docker build -t api2-202300625 api-services/API2
docker build -t api3-202300625 api-services/API3

# 5. Subir a Zot
docker push 192.168.122.30:5000/api1-202300625:latest
docker push 192.168.122.30:5000/api2-202300625:latest
docker push 192.168.122.30:5000/api3-202300625:latest

# 6. Desplegar contenedores en VMs
# Ver docs/installation/Guia_Instalacion.md
```

---

## Pruebas

### Health Checks

```bash
curl http://192.168.122.10:8081/health
curl http://192.168.122.10:8082/health
curl http://192.168.122.20:8083/health
```

### Comunicación entre APIs

```bash
# API2 llamando a API1
curl http://192.168.122.10:8082/api2/202300625/call-api1

# API1 llamando a API3
curl http://192.168.122.10:8081/api1/202300625/call-api3

# API3 llamando a API2
curl http://192.168.122.20:8083/api3/202300625/call-api2
```

### Verificar Zot

```bash
# Catálogo de imágenes
curl http://192.168.122.30:5000/v2/_catalog

# Información de imagen
curl http://192.168.122.30:5000/v2/api1-202300625/manifests/latest
```

---

## Documentación Completa

| Documento | Ubicación | Descripción |
|-----------|-----------|-------------|
| **Manual Técnico** | `docs/architecture/Manual_Tecnico.md` | Arquitectura, configuración, APIs |
| **Guía de Instalación** | `docs/installation/Guia_Instalacion.md` | Pasos detallados de instalación |
| **Evidencia de Pruebas** | `docs/operations/Evidencia_Pruebas.md` | Resultados y validación |
| **Especificación de APIs** | `docs/api-docs/COMUNICACION_APIS.md` | Endpoints y formatos |

---

## Herramientas Utilizadas

| Herramienta | Versión | Propósito |
|------------|---------|----------|
| Go | 1.18+ | Lenguaje de APIs |
| KVM/QEMU | 6.0+ | Hipervisor |
| Containerd | 1.6+ | Runtime (VM1, VM2) |
| Docker | 20.10+ | Runtime (VM3) |
| Zot | latest | Registro privado |
| curl | - | Pruebas HTTP |
| jq | - | Parseo JSON |

---

## Scripts Disponibles

### Despliegue Automatizado

```bash
# Desplegar todo (build, push, run)
scripts/container-deployment/deploy.sh

# Reconstruir API3
scripts/container-deployment/rebuild_api3.sh
```

### Gestión de Logs

```bash
# Generar logs de pruebas exitosas
scripts/logs/generate-logs.sh

# Generar logs de errores
scripts/logs/generate-error-logs.sh

# Ver todos los logs
scripts/logs/view-logs.sh

# Limpiar logs antiguos
scripts/logs/clean-logs.sh
```

### Configuración de VMs

```bash
# Preparar entorno en VM
scripts/vm-setup/setup.sh

# Configurar firewall
scripts/network-config/fix-firewall.sh
```

---

## Solución de Problemas Comunes

### Las VMs no tienen conectividad

```bash
# En la VM
sudo netplan apply
sudo netplan status
ping 8.8.8.8
```

### Containerd no inicia

```bash
# Verificar logs
sudo journalctl -u containerd -n 50

# Reiniciar
sudo systemctl restart containerd
```

### Los contenedores no se comunican

```bash
# Verificar firewall
sudo ufw status

# Permitir puertos
sudo ufw allow 8081:8083/tcp

# Verificar DNS en container
docker exec <container> nslookup 192.168.122.20
```

### Zot no acepta imágenes

```bash
# Verificar que Zot está activo
curl http://192.168.122.30:5000/v2/

# Revisar logs de Docker en VM3
docker logs zot-registry

# Verificar espacio en disco
df -h /var/lib/zot
```

---

## Requisitos de Calificación

- [x] Código fuente en Go compilado correctamente
- [x] Imágenes Docker construidas y operativas
- [x] 3 VMs con runtimes apropiados (Containerd/Docker)
- [x] Comunicación exitosa entre APIs
- [x] Manejo de errores cuando nodos no están disponibles
- [x] Registro Zot configurado y funcional
- [x] Documentación técnica completa
- [x] Evidencia de pruebas funcionales
- [x] Código en repositorio GitHub privado

---

## Contacto y Referencias

**Carnet:** 202300625  
**Asignatura:** Sistemas Operativos 1  
**Período:** I Semestre 2026  

**Referencias útiles:**
- Documentación KVM: https://www.linux-kvm.org/
- Documentación Containerd: https://containerd.io/
- Documentación Zot: https://zotregistry.io/
- Go Documentation: https://golang.org/doc/

---

**Última actualización:** 2 de Febrero, 2026  
**Versión:** 1.0
