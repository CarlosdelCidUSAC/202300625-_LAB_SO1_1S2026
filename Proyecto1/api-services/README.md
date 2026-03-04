# APIs REST con Contenedores Personalizados

Esta carpeta contiene la implementación de 3 APIs REST (API1, API2, API3) que se comunican entre sí mediante llamadas HTTP.

## Estructura

- `API1/` - API1 ejecutada en VM1 (Containerd)
- `API2/` - API2 ejecutada en VM1 (Containerd)
- `API3/` - API3 ejecutada en VM2 (Containerd)
- `common/` - Código común compartido entre APIs
- `dockerfiles/` - Dockerfiles para construir imágenes

## Especificaciones Técnicas

### Tecnologías
- **Lenguaje**: Go (Golang)
- **Framework**: Gin Web Framework
- **Comunicación**: REST API, HTTP/JSON
- **Contenedores**: Docker/Containerd
- **Formato de datos**: JSON
- **Variables personalizadas**: `#CARNET` = `202300625`

### Características Comunes
- Endpoint `/health` para verificación de estado
- Endpoints de llamada entre APIs
- Logging estructurado
- Manejo de errores
- Configuración mediante variables de entorno

## Endpoints Requeridos

### API1 (VM1 - Containerd)
- `GET /health` - Verificación de estado
- `GET /api1/202300625/call-api2` - Llamar a API2
- `GET /api1/202300625/call-api3` - Llamar a API3

### API2 (VM1 - Containerd)
- `GET /health` - Verificación de estado
- `GET /api2/202300625/call-api1` - Llamar a API1
- `GET /api2/202300625/call-api3` - Llamar a API3

### API3 (VM2 - Containerd)
- `GET /health` - Verificación de estado
- `GET /api3/202300625/call-api1` - Llamar a API1
- `GET /api3/202300625/call-api2` - Llamar a API2

## Formato de Respuestas JSON

### Endpoint `/health`
```json
{
  "status": "UP",
  "message": "API# is Ready",
  "timestamp": "<DATE>",
  "VM": "#vm",
  "carnet": "202300625"
}
```

### Endpoint `/api#/202300625/call-api#`
```json
{
  "apiname": "API#",
  "message": "The API# located on the VM# is working",
  "connection": true,
  "carnet": "202300625"
}
```

### Endpoint con error (cuando no se puede conectar)
```json
{
  "apiname": "API#",
  "message": "ERROR: The API# located on the VM# is not working",
  "connection": false,
  "carnet": "202300625"
}
```

## Comunicación entre APIs

Cada API debe poder realizar llamadas HTTP a las otras APIs para verificar su estado:

```
API1 (VM1:8081) <--> API2 (VM1:8082) <--> API3 (VM2:8083)
```

### Ejemplo de Flujo
1. Usuario llama a `GET /api2/202300625/call-api1`
2. API2 realiza una llamada HTTP a `GET /health` de API1
3. API1 responde con su estado
4. API2 analiza la respuesta y responde al usuario

## Despliegue con Contenedores

Cada servicio tiene su propio Dockerfile y se construye como imagen independiente:

```dockerfile
# Ejemplo de Dockerfile para servicio Go
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o main .

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

## Variables de Entorno

Cada API requiere las siguientes variables:

```bash
# Configuración común
APP_PORT=8081  # 8081 para API1, 8082 para API2, 8083 para API3
APP_ENV=development
LOG_LEVEL=info
CARNET=202300625

# Configuración de otras APIs
API1_URL=http://192.168.100.10:8081
API2_URL=http://192.168.100.10:8082
API3_URL=http://192.168.100.20:8083

# Configuración de VM
VM_NUMBER=1  # 1 para API1/API2, 2 para API3

# Registro de contenedores
REGISTRY_URL=http://192.168.100.30:5000
REGISTRY_USER=admin
REGISTRY_PASSWORD=secret
IMAGE_NAME=API#-202300625  # API1-202300625, API2-202300625, API3-202300625
```

## Nombres de Imágenes

Cada imagen de contenedor debe seguir el formato:
- `API1-202300625:[tag]` para API1
- `API2-202300625:[tag]` para API2  
- `API3-202300625:[tag]` para API3
- `zot-202300625:[tag]` para ZOT Registry

## Despliegue

### Construir y subir imágenes al registro
```bash
# Construir imagen
docker build -t API1-202300625:latest ./API1

# Etiquetar para registro privado
docker tag API1-202300625:latest 192.168.100.30:5000/API1-202300625:latest

# Subir al registro
docker push 192.168.100.30:5000/API1-202300625:latest
```

### Ejecutar en VMs con Containerd
```bash
# En VM1 para API1
ctr images pull 192.168.100.30:5000/API1-202300625:latest
ctr run --rm -d --net-host 192.168.100.30:5000/API1-202300625:latest api1

# En VM1 para API2
ctr images pull 192.168.100.30:5000/API2-202300625:latest
ctr run --rm -d --net-host 192.168.100.30:5000/API2-202300625:latest api2

# En VM2 para API3
ctr images pull 192.168.100.30:5000/API3-202300625:latest
ctr run --rm -d --net-host 192.168.100.30:5000/API3-202300625:latest api3
```

## Próximos Pasos

1. Implementar cada API en Go con los endpoints requeridos
2. Crear Dockerfiles para cada API
3. Configurar comunicación HTTP entre APIs
4. Implementar manejo de errores
5. Crear scripts de despliegue para Containerd
6. Configurar ZOT Registry en VM3
7. Documentar configuración completa
