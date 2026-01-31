# Estructura del Proyecto de Virtualización

Este documento describe la estructura de carpetas creada para el proyecto de virtualización que integra VMs con KVM, contenedores Docker, APIs REST y registros privados.

## Estructura Principal

```
202300625-_LAB_SO1_1S2026/
├── README.md                    # Descripción general del proyecto
├── STRUCTURE.md                 # Este documento
├── docs/                        # Documentación técnica completa
│   ├── architecture/            # Documentación de arquitectura
│   ├── installation/            # Guías de instalación
│   ├── api-docs/                # Documentación de APIs
│   ├── operations/              # Procedimientos operativos
│   └── troubleshooting/         # Solución de problemas
├── vm-config/                   # Configuración de máquinas virtuales (3 VMs)
│   ├── vm1-services/            # VM 1: Servicios principales
│   ├── vm2-registry/            # VM 2: Registro de contenedores
│   └── vm3-monitoring/          # VM 3: Monitoreo y logs
├── api-services/                # APIs REST con contenedores personalizados
│   ├── service-a/               # Servicio API A
│   ├── service-b/               # Servicio API B
│   ├── service-c/               # Servicio API C
│   ├── common/                  # Código común entre servicios
│   └── dockerfiles/             # Dockerfiles para los servicios
├── container-registry/          # Registro privado de imágenes
│   ├── zot-config/              # Configuración de Zot registry
│   ├── images-backup/           # Backup de imágenes
│   └── certificates/            # Certificados SSL/TLS
├── scripts/                     # Scripts de automatización
│   ├── vm-setup/                # Scripts para configuración de VMs
│   ├── container-deployment/    # Scripts para despliegue de contenedores
│   ├── monitoring/              # Scripts de monitoreo
│   └── backup/                  # Scripts de backup
├── monitoring/                  # Configuración de monitoreo
├── network-config/              # Configuración de red
├── deployment/                  # Configuración de despliegue
├── images/                      # Imágenes ISO y otros recursos
├── logs/                        # Logs del sistema
└── .git/                        # Repositorio Git
```

## Configuración de VMs según especificaciones

### VM1: Containerd Runtime
- **Runtime**: Containerd
- **Contenedores ejecutados**: API1, API2
- **Imágenes**: `API1-202300625`, `API2-202300625`
- **Endpoints**:
  - API1: `/health`, `/api1/202300625/call-api2`, `/api1/202300625/call-api3`
  - API2: `/health`, `/api2/202300625/call-api1`, `/api2/202300625/call-api3`

### VM2: Containerd Runtime
- **Runtime**: Containerd
- **Contenedores ejecutados**: API3
- **Imágenes**: `API3-202300625`
- **Endpoints**:
  - API3: `/health`, `/api3/202300625/call-api1`, `/api3/202300625/call-api2`

### VM3: Docker Runtime
- **Runtime**: Docker
- **Contenedores ejecutados**: ZOT Registry
- **Imágenes**: `zot-202300625`
- **Propósito**: Registro privado de imágenes de contenedores

## Comunicación entre Componentes

- **API Services**: Comunicación REST entre servicios contenerizados
- **Container Registry**: Distribución de imágenes a todas las VMs
- **Network**: Configuración de red para comunicación cruzada
- **Monitoring**: Recopilación de métricas y logs de todos los componentes

## Tecnologías Utilizadas

- **Virtualización**: KVM/QEMU
- **Contenedores**: Docker, Containerd
- **Registro**: Zot
- **APIs**: Go (Golang), REST
- **Monitoreo**: Prometheus, Grafana, ELK Stack
- **Orquestación**: Scripts Bash, Ansible (opcional)

## Próximos Pasos

1. Configurar las 3 VMs con KVM
2. Implementar Zot registry en vm2-registry
3. Desarrollar APIs REST en Go
4. Crear Dockerfiles para los servicios
5. Configurar comunicación entre servicios
6. Implementar monitoreo y logging
7. Documentar procedimientos operativos