# Implementacion de Deployment 2 y Deployment 3 (Go gRPC Writer + RabbitMQ)

Este documento registra la implementacion realizada para los componentes **Deployment 2** y **Deployment 3** del Proyecto 3, manteniendo el mismo estilo de registro tecnico: objetivo, cambios, manifiestos, validaciones, comandos y resultados esperados.

---

## 1. Objetivo

Implementar los servicios internos de escritura del flujo principal:

- **Deployment 2**: servidor gRPC + writer a RabbitMQ con **1 replica**.
- **Deployment 3**: servidor gRPC + writer a RabbitMQ con **2 replicas**.

Ambos deployments exponen el servicio gRPC `WarReportService.SendReport` en el puerto `50051` y publican mensajes JSON a la cola de RabbitMQ `war_reports_queue`.

---

## 2. Componentes tocados

### 2.1 Backend Go writer

Archivos usados para Deployment 2/3:

- `src/go-server/main.go`
- `src/go-server/go.mod`
- `src/go-server/go.sum`
- `src/go-server/proto/military.pb.go`
- `src/go-server/proto/military_grpc.pb.go`
- `src/go-server/Dockerfile`

### 2.2 Kubernetes

Archivo de manifiestos principal:

- `kube/grpc-server.yaml`

Dependencia de mensajeria:

- `kube/rabbitmq.yaml`

---

## 3. Cambios aplicados

### 3.1 Servicio Go (`src/go-server/main.go`)

Se implemento/ajusto el writer para:

1. Levantar servidor gRPC en `GRPC_PORT` (default `50051`).
2. Conectarse a RabbitMQ por `RABBITMQ_URL`.
3. Declarar cola durable por `RABBITMQ_QUEUE` (default `war_reports_queue`).
4. Recibir `WarReportRequest` y publicar JSON en RabbitMQ.

Variables de entorno soportadas:

- `RABBITMQ_URL`
- `RABBITMQ_QUEUE`
- `GRPC_PORT`

### 3.2 Import de proto corregido

Se uso import interno del modulo:

```go
pb "go-server/proto"
```

Con esto se evitan errores de compilacion por rutas de import invalidas.

### 3.3 Proto para go-server

Se agregaron los archivos generados de protobuf y gRPC en:

- `src/go-server/proto/military.pb.go`
- `src/go-server/proto/military_grpc.pb.go`

Esto deja el modulo `go-server` autocontenido para construir la imagen Docker.

---

## 4. Manifiesto de Kubernetes para Deployment 2 y 3

Archivo: `kube/grpc-server.yaml`

Incluye 3 recursos:

1. **Service** `grpc-server-service` (ClusterIP, puerto `50051`).
2. **Deployment 2** `go-server-deployment-2` con `replicas: 1`.
3. **Deployment 3** `go-server-deployment-3` con `replicas: 2`.

### 4.1 Service interno

Selector:

```yaml
selector:
  app: go-server
```

Puerto:

```yaml
port: 50051
targetPort: 50051
```

### 4.2 Deployment 2

- Nombre: `go-server-deployment-2`
- Replicas: `1`
- Label extra: `deployment: writer-2`
- Imagen: `<IP_VM_ZOT>:5000/go-server:v1`

### 4.3 Deployment 3

- Nombre: `go-server-deployment-3`
- Replicas: `2`
- Label extra: `deployment: writer-3`
- Imagen: `<IP_VM_ZOT>:5000/go-server:v1`

### 4.4 Probes y recursos

En ambos deployments:

- `readinessProbe` TCP sobre `50051`
- `livenessProbe` TCP sobre `50051`
- `requests`: 100m CPU / 128Mi RAM
- `limits`: 500m CPU / 256Mi RAM

---

## 5. Integracion con Deployment 1 (Go gRPC Client)

Para que Deployment 1 consuma ambos writers via balanceo interno de Kubernetes:

- El cliente usa `GRPC_SERVER_ADDR=grpc-server-service:50051`.
- El Service `grpc-server-service` distribuye trafico a todos los pods con label `app=go-server`.

Resultado: el cliente gRPC puede enviar reportes a pods de Deployment 2 y Deployment 3 sin cambiar codigo.

---

## 6. Comandos de build y despliegue

### 6.1 Build y push de imagen writer

```bash
cd src/go-server
docker build -t <IP_VM_ZOT>:5000/go-server:v1 .
docker push <IP_VM_ZOT>:5000/go-server:v1
```

### 6.2 Aplicar RabbitMQ y writers

```bash
kubectl apply -f kube/rabbitmq.yaml
kubectl apply -f kube/grpc-server.yaml
```

### 6.3 Verificacion de estado

```bash
kubectl get deploy go-server-deployment-2 go-server-deployment-3
kubectl get pods -l app=go-server -o wide
kubectl get svc grpc-server-service
```

### 6.4 Verificar conectividad a RabbitMQ desde writers

```bash
kubectl logs deploy/go-server-deployment-2 --tail=80
kubectl logs deploy/go-server-deployment-3 --tail=80
```

Salida esperada al inicio:

```text
Servidor gRPC + RabbitMQ Writer escuchando en [::]:50051
```

Salida esperada al recibir trafico:

```text
Reporte publicado en RabbitMQ: esp
```

---

## 7. Validacion local de compilacion

Validacion aplicada al modulo writer:

```bash
cd src/go-server
go build .
```

Resultado observado:

```text
Compilacion sin errores
```

---

## 8. Escenarios de prueba de rendimiento (1 vs 2 replicas)

Para comparativa limpia entre configuraciones:

### 8.1 Escenario A (solo Deployment 2 = 1 replica)

```bash
kubectl scale deployment go-server-deployment-2 --replicas=1
kubectl scale deployment go-server-deployment-3 --replicas=0
kubectl get pods -l app=go-server
```

### 8.2 Escenario B (solo Deployment 3 = 2 replicas)

```bash
kubectl scale deployment go-server-deployment-2 --replicas=0
kubectl scale deployment go-server-deployment-3 --replicas=2
kubectl get pods -l app=go-server
```

Con esto se pueden ejecutar pruebas de carga con Locust y comparar latencia, throughput y errores entre 1 y 2 replicas writer.

---

## 9. Archivos modificados durante la implementacion

- `kube/grpc-server.yaml`
- `src/go-server/main.go`
- `src/go-server/proto/military.pb.go`
- `src/go-server/proto/military_grpc.pb.go`

---

## 10. Estado actual

La implementacion de **Deployment 2 y Deployment 3** queda lista para:

- recibir llamadas gRPC desde Deployment 1,
- publicar reportes en RabbitMQ,
- escalar y comparar desempeno con 1 y 2 replicas,
- operar detras de un Service interno estable (`grpc-server-service`).

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*
