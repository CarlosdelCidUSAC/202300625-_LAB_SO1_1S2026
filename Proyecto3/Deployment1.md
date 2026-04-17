# Deployment 1 - Go REST Client para Proyecto3

Este documento registra lo realizado para implementar el **Deployment 1** del proyecto: un servicio Go que recibe peticiones HTTP desde la API Rust y reenvia los reportes por gRPC al servicio escritor.

---

## 1. Objetivo

Implementar el componente **Go Deployment 1** como:

- API REST de entrada en `POST /api/reports`
- cliente gRPC hacia `WarReportService.SendReport`
- punto de integracion entre la API Rust y el backend Go escritor

El servicio escucha en `8081` y expone una ruta de salud para Kubernetes en `GET /health`.

---

## 2. Contrato y Generacion de Protobuf

Se utilizo la definicion compartida del proyecto en `proto/military.proto`.

### 2.1 Ajuste del paquete Go

Se actualizo el `go_package` para que el cliente Go pueda importar el codigo generado como modulo local:

```proto
option go_package = "go-client/proto";
```

### 2.2 Generacion de stubs

Se genero el cliente y las estructuras gRPC con `protoc`:

```bash
protoc -I proto \
  --go_out=paths=source_relative:src/go-client/proto \
  --go-grpc_out=paths=source_relative:src/go-client/proto \
  proto/military.proto
```

Archivos generados:

- `src/go-client/proto/military.pb.go`
- `src/go-client/proto/military_grpc.pb.go`

---

## 3. Implementacion del Servicio Go

Se creo un modulo independiente en `src/go-client` para aislar este deployment del resto del proyecto.

### 3.1 Modulo Go

Se agrego `src/go-client/go.mod` con las dependencias necesarias para:

- `gin-gonic/gin` para la API REST
- `google.golang.org/grpc` para el cliente gRPC
- `google.golang.org/protobuf` para los tipos generados

### 3.2 Logica principal

Archivo implementado: `src/go-client/main.go`

El flujo de la aplicacion quedó asi:

1. Lee `GRPC_SERVER_ADDR` desde variables de entorno.
2. Conecta el cliente gRPC al servidor configurado.
3. Expone `GET /health` para sondas de Kubernetes.
4. Expone `POST /api/reports` para recibir el JSON enviado por Rust.
5. Normaliza `country` a mayusculas antes de mapearlo al enum `Countries`.
6. Llama a `SendReport` con el payload convertido a `WarReportRequest`.
7. Devuelve al cliente HTTP la respuesta de estado recibida desde gRPC.

### 3.3 Mapeo de paises

Se implemento el siguiente mapeo entre texto y enum:

| JSON | Enum gRPC |
|---|---|
| `USA` | `Countries_usa` |
| `RUS` | `Countries_rus` |
| `CHN` | `Countries_chn` |
| `ESP` | `Countries_esp` |
| `GTM` | `Countries_gtm` |

Si el valor no coincide, se usa `Countries_countries_unknown`.

---

## 4. Contenerizacion

Se agrego un Dockerfile para construir la imagen del cliente Go:

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o go-client main.go

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/go-client .
EXPOSE 8081
CMD ["./go-client"]
```

La imagen debe publicarse en Zot con el nombre correspondiente al proyecto.

---

## 5. Despliegue en Kubernetes

Se prepararon los manifests para correr el servicio en GKE.

### 5.1 Deployment

Archivo: `kube/go-client.yaml`

Configuracion aplicada:

- `replicas: 2`
- `containerPort: 8081`
- `GRPC_SERVER_ADDR=grpc-server-service:50051`
- `readinessProbe` HTTP sobre `/health`
- requests y limits de CPU y memoria

### 5.2 Service

Archivo: `kube/go-client-service.yaml`

Se creo un `Service` ClusterIP para exponer el deployment dentro del cluster:

- nombre: `go-client-service`
- puerto: `8081`
- selector: `app: go-client`

### 5.3 Integracion con Rust

Se actualizo la API Rust para que apunte al nuevo servicio:

```text
http://go-client-service.default.svc.cluster.local:8081/api/reports
```

---

## 6. Validacion Realizada

### 6.1 Compilacion local

Se valido que el modulo Go compila correctamente:

```bash
cd src/go-client
go build ./...
```

Resultado:

```text
sin errores de compilacion
```

### 6.2 Verificacion de errores

Se revisaron los archivos relacionados con el deployment y no quedaron errores de sintaxis en:

- `src/go-client/main.go`
- `kube/go-client.yaml`
- `kube/go-client-service.yaml`
- `proto/military.proto`

---

## 7. Archivos Creados o Modificados

- `src/go-client/main.go`
- `src/go-client/go.mod`
- `src/go-client/go.sum`
- `src/go-client/Dockerfile`
- `src/go-client/proto/military.pb.go`
- `src/go-client/proto/military_grpc.pb.go`
- `proto/military.proto`
- `kube/go-client.yaml`
- `kube/go-client-service.yaml`
- `kube/rust-api-deploy.yaml`

---

## 8. Estado Actual

Deployment 1 quedo listo como componente funcional para:

- recibir trafico HTTP desde Rust
- convertir el payload al contrato protobuf
- invocar el backend gRPC definido por `WarReportService`
- ser desplegado en Kubernetes con su propio Service

La integracion completa depende de que el servicio gRPC destino de `GRPC_SERVER_ADDR` este desplegado y accesible en el cluster.

---

## 9. Comandos Utiles

### 9.1 Construir la imagen

```bash
cd src/go-client
docker build -t <IP_VM_ZOT>:5000/go-client:v1 .
```

### 9.2 Publicar el manifiesto en Kubernetes

```bash
kubectl apply -f kube/go-client.yaml
kubectl apply -f kube/go-client-service.yaml
```

### 9.3 Verificar el estado

```bash
kubectl get deploy go-client-deployment
kubectl get svc go-client-service
kubectl get pods -l app=go-client
```

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*