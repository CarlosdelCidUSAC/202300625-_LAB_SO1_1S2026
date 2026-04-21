# Implementacion de RabbitMQ Client (Consumer) para Proyecto3

Este documento registra la implementacion realizada para el componente **Consumer** del flujo principal del Proyecto 3, siguiendo el mismo estilo de documentacion tecnica usado en los demas archivos del repositorio.

---

## 1. Objetivo

Implementar el servicio **RabbitMQ Consumer** para:

- consumir mensajes JSON desde la cola `war_reports_queue`,
- validar la estructura y reglas del reporte militar,
- persistir metricas en Valkey para analitica y dashboards de Grafana,
- operar de forma robusta en Kubernetes ante fallas de conectividad.

---

## 2. Componentes Implementados

### 2.1 Servicio Go Consumer

Archivos del modulo:

- `src/consumer/main.go`
- `src/consumer/go.mod`
- `src/consumer/go.sum`
- `src/consumer/Dockerfile`

### 2.2 Manifiesto Kubernetes

Archivo de despliegue:

- `kube/consumer.yaml`

---

## 3. Cambios aplicados al Consumer

### 3.1 Configuracion por variables de entorno

Se habilitaron variables para ajustar comportamiento en runtime sin recompilar:

- `RABBITMQ_URL`
- `RABBITMQ_QUEUE`
- `RABBITMQ_PREFETCH`
- `VALKEY_ADDR`
- `RETRY_SECONDS`
- `TIMESERIES_MAXLEN`

Valores por defecto:

- RabbitMQ URL: `amqp://guest:guest@localhost:5672/`
- Queue: `war_reports_queue`
- Prefetch: `25`
- Retry: `5` segundos
- Time series max len: `2000`

### 3.2 Robustez operativa

Se implemento un ciclo de reconexion para mantener el servicio activo cuando hay fallos temporales:

1. Reintento continuo de conexion a Valkey hasta que responda `PING`.
2. Consumo en bucle con reintento automatico si se cae RabbitMQ o se cierra el canal.

### 3.3 Consumo confiable de mensajes

El consumo se configuro con buenas practicas para procesamiento seguro:

- `auto-ack = false` (confirmacion manual)
- `QoS / prefetch` configurable
- `ACK` solo cuando el mensaje se valida y persiste correctamente
- `NACK + requeue` cuando falla persistencia en Valkey

### 3.4 Validacion del payload

Antes de guardar en Valkey, se valida:

- pais permitido (`USA`, `RUS`, `CHN`, `ESP`, `GTM`)
- `warplanes_in_air` en rango `0..50`
- `warships_in_water` en rango `0..30`

Mensajes invalidos se descartan con log de auditoria.

### 3.5 Persistencia para Grafana

Se almacena la informacion con `TxPipeline` en Valkey para eficiencia y consistencia:

1. Serie temporal por pais: `timeseries:<COUNTRY>`
2. Top paises por aviones: `top_countries_warplanes` (sorted set)
3. Top paises por barcos: `top_countries_warships` (sorted set)
4. Total de reportes por pais: `total_reports:<COUNTRY>`
5. Histogramas para moda:
   - `mode_warplanes`
   - `mode_warships`

Adicionalmente, se limita el tamano de la serie temporal con `LTRIM` para reducir crecimiento indefinido de memoria.

---

## 4. Kubernetes Deployment del Consumer

Se creo/actualizo `kube/consumer.yaml` con:

- `Deployment` `rabbitmq-consumer-deployment`
- `replicas: 1`
- imagen en Zot: `<IP_VM_ZOT>:5000/rabbitmq-consumer:v1`
- `imagePullPolicy: Always`
- variables de entorno para RabbitMQ, Valkey y tuning
- requests/limits de CPU y memoria

Esto permite desplegar el consumer como componente independiente dentro del clúster.

---

## 5. Ajustes de Build y Dependencias

### 5.1 Go module

Se normalizo el modulo del consumer para compatibilidad con toolchain:

- `go 1.22`
- dependencias directas:
  - `github.com/rabbitmq/amqp091-go`
  - `github.com/redis/go-redis/v9`

### 5.2 Formateo y limpieza

Se aplicaron:

- `gofmt -w main.go`
- `go mod tidy`

---

## 6. Validacion Realizada

Se ejecutaron validaciones de compilacion y analisis de errores en archivos clave.

### 6.1 Build local

Comando:

```bash
cd src/consumer
go build .
```

Resultado:

```text
Compilacion exitosa (sin errores)
```

### 6.2 Verificacion de errores

Se verifico que no quedaran errores en:

- `src/consumer/main.go`
- `kube/consumer.yaml`

Resultado:

```text
No errors found
```

---

## 7. Comandos de Build y Despliegue

### 7.1 Construir y publicar imagen en Zot

```bash
cd src/consumer
docker build -t <IP_VM_ZOT>:5000/rabbitmq-consumer:v1 .
docker push <IP_VM_ZOT>:5000/rabbitmq-consumer:v1
```

### 7.2 Aplicar el deployment en Kubernetes

```bash
kubectl apply -f kube/consumer.yaml
kubectl rollout status deployment/rabbitmq-consumer-deployment --timeout=180s
```

### 7.3 Verificar estado y logs

```bash
kubectl get deploy rabbitmq-consumer-deployment
kubectl get pods -l app=rabbitmq-consumer -o wide
kubectl logs deploy/rabbitmq-consumer-deployment --tail=100
```

---

## 8. Estado actual

El componente **RabbitMQ Consumer** queda listo para produccion en el flujo del proyecto:

- consume desde RabbitMQ de forma confiable,
- valida reglas de negocio del reporte,
- persiste metricas optimizadas para analitica en Valkey,
- soporta reconexion automatica ante fallas,
- esta preparado para despliegue en GKE con manifest dedicado.

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*