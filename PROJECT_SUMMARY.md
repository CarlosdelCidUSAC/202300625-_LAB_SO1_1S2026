# Resumen del Proyecto de Virtualización

## Objetivo Principal
Diseño e implementación de un entorno virtualizado que integre el uso de máquinas virtuales (VMs) y contenedores, empleando tecnologías modernas como Docker, Containerd, Go y Zot.

## Componentes Implementados (Adaptados a Especificaciones)

### 1. Máquinas Virtuales (3 VMs con KVM)
- **VM1 **: Runtime Containerd, ejecuta API1 y API2
- **VM2 **: Runtime Containerd, ejecuta API3
- **VM3 **: Runtime Docker, ejecuta ZOT Registry

### 2. APIs REST con Contenedores Personalizados
- **API1**: Ejecutada en VM1, puerto 8081
- **API2**: Ejecutada en VM1, puerto 8082  
- **API3**: Ejecutada en VM2, puerto 8083
- Implementadas en Go con Gin Framework
- Comunicación REST/HTTP entre APIs
- Formato de datos JSON

### 3. Registro Privado de Imágenes (ZOT)
- ZOT Container Registry en VM3
- Autenticación básica
- Certificados SSL/TLS
- Nombres de imágenes: `API#-202300625` y `zot-202300625`

### 4. Comunicación Cruzada entre APIs
- **Protocolo**: REST/HTTP
- **Formato**: JSON
- **Endpoints requeridos**:
  - `/health` - Verificación de estado
  - `/api#/202300625/call-api#` - Llamadas entre APIs
- **Variables personalizadas**: `#CARNET` = `202300625`

### 5. Documentación Técnica Completa
- Arquitectura del sistema adaptada
- Guías de instalación específicas
- Documentación de endpoints API
- Procedimientos operativos
- Solución de problemas

## Estructura de Carpetas Creada

```
202300625-_LAB_SO1_1S2026/
├── docs/                        # Documentación técnica
│   ├── architecture/            # Arquitectura del sistema
│   ├── installation/            # Guías de instalación
│   ├── api-docs/                # Documentación de APIs
│   ├── operations/              # Procedimientos operativos
│   └── troubleshooting/         # Solución de problemas
├── vm-config/                   # Configuración de 3 VMs
│   ├── vm1-services/            # VM para servicios
│   ├── vm2-registry/            # VM para registro
│   └── vm3-monitoring/          # VM para monitoreo
├── api-services/                # APIs REST con contenedores
│   ├── service-a/               # Servicio API A
│   ├── service-b/               # Servicio API B
│   ├── service-c/               # Servicio API C
│   ├── common/                  # Código común
│   └── dockerfiles/             # Dockerfiles
├── container-registry/          # Registro privado
│   ├── zot-config/              # Configuración Zot
│   ├── images-backup/           # Backup de imágenes
│   └── certificates/            # Certificados SSL
├── scripts/                     # Scripts de automatización
│   ├── vm-setup/                # Configuración VMs
│   ├── container-deployment/    # Despliegue contenedores
│   ├── monitoring/              # Monitoreo
│   └── backup/                  # Backup
├── monitoring/                  # Configuración monitoreo
├── network-config/              # Configuración red
├── deployment/                  # Configuración despliegue
├── images/                      # Imágenes ISO
└── logs/                        # Logs del sistema
```

## Tecnologías Utilizadas

- **Virtualización**: KVM/QEMU
- **Contenedores**: Docker, Containerd
- **Registro**: Zot Container Registry
- **Desarrollo**: Go (Golang), Gin Framework
- **APIs**: REST, HTTP/JSON
- **Base de datos**: PostgreSQL
- **Monitoreo**: Prometheus, Grafana, ELK Stack
- **Red**: Bridge networking, subred privada
- **Seguridad**: SSL/TLS, autenticación básica, JWT

## Próximos Pasos de Implementación

1. **Configuración de VMs**:
   - Instalar KVM y crear las 3 VMs
   - Configurar red bridge
   - Instalar sistemas operativos (Debian Trixie)

2. **Implementación de Registro**:
   - Instalar Zot en vm2-registry
   - Configurar autenticación
   - Generar certificados SSL

3. **Desarrollo de APIs**:
   - Implementar servicios en Go
   - Crear Dockerfiles
   - Configurar comunicación entre servicios

4. **Despliegue**:
   - Construir imágenes de contenedores
   - Subir imágenes al registro privado
   - Desplegar servicios en vm1-services

5. **Monitoreo**:
   - Instalar Prometheus/Grafana en vm3-monitoring
   - Configurar métricas y alertas
   - Implementar ELK Stack para logs

6. **Documentación**:
   - Completar guías de instalación
   - Documentar APIs
   - Crear procedimientos operativos

## Beneficios de la Arquitectura

1. **Aislamiento**: Cada componente en su propia VM
2. **Escalabilidad**: Servicios independientes y contenerizados
3. **Seguridad**: Registro privado, autenticación, red privada
4. **Monitoreo**: Métricas y logs centralizados
5. **Portabilidad**: Contenedores independientes del host
6. **Automatización**: Scripts para despliegue y mantenimiento

## Consideraciones de Seguridad

- Todas las VMs en red privada
- Autenticación en registro Zot
- Certificados SSL para comunicación
- Firewall entre VMs
- Backup regular de imágenes y configuraciones
- Monitoreo de acceso y logs

Esta estructura proporciona una base sólida para implementar el proyecto completo de virtualización con todas las funcionalidades requeridas.