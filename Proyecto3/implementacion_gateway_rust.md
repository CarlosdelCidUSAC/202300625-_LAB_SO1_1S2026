# Implementacion de Ruteo Gateway -> Rust API (Proyecto3)

Este documento registra la implementacion aplicada para corregir el ruteo del `HTTPRoute` hacia la API Rust y fortalecer la compatibilidad de rutas en el servicio.

---

## 1. Objetivo

Alinear el flujo de entrada `/grpc-202300625` con el endpoint real de la API Rust (`/reports`) para evitar respuestas `404` cuando el trafico entra por Gateway API.

---

## 2. Problema Detectado

En la configuracion previa de `kube/rust-api-httproute-v2.yaml`, la regla de reescritura usaba:

```yaml
replacePrefixMatch: /
```

Con esta configuracion, una peticion hacia `/grpc-202300625` podia llegar como `/` al backend, pero la API Rust procesa reportes en `POST /reports`.

Resultado esperado del problema: ruta no encontrada en el backend para solicitudes de carga.

---

## 3. Cambios Implementados

### 3.1 Ajuste de URLRewrite en HTTPRoute

Archivo modificado: `kube/rust-api-httproute-v2.yaml`

Se cambio el prefijo de reescritura para apuntar directamente al endpoint de reportes:

```yaml
replacePrefixMatch: /reports
```

Con esto, el trafico de `/grpc-202300625` se transforma a `/reports` antes de llegar al `Service` de Rust.

### 3.2 Ruta de compatibilidad en Rust API

Archivo modificado: `src/rust-api/src/main.rs`

Se agrego soporte directo para:

- `POST /grpc-202300625`

De esta forma, incluso si en algun ambiente no se aplica el rewrite del Gateway, la API Rust sigue aceptando el mismo payload.

### 3.3 Validacion de paises permitidos

Archivo modificado: `src/rust-api/src/main.rs`

Se agrego validacion explicita para `country` con valores permitidos por el proyecto:

- `USA`
- `RUS`
- `CHN`
- `ESP`
- `GTM`

Si el valor no es valido, la API responde `400 Bad Request` con mensaje descriptivo.

---

## 4. Validacion Realizada

Se ejecuto compilacion de verificacion en el servicio Rust:

```bash
cd src/rust-api
cargo check
```

Resultado:

```text
Finished `dev` profile [unoptimized + debuginfo] target(s) in 34.24s
```

Estado: cambios aplicados y compilacion correcta.

---

## 5. Despliegue en la Nube (GKE)

Se utilizo el cluster existente `gke-kubevirt-cluster` en el proyecto `proyecto3-202300625`.

### 5.1 Aplicacion de manifiestos

```bash
kubectl apply -f kube/gateway.yaml
kubectl apply -f kube/rust-api-deploy.yaml
kubectl apply -f kube/rust-api-service.yaml
kubectl apply -f kube/hpa.yaml
kubectl apply -f kube/rust-api-httproute-v2.yaml
```

Estado observado:

- `Gateway` configurado
- `Deployment` en `Running`
- `Service` activo
- `HPA` creado (`min=1`, `max=3`, objetivo CPU 30%)
- `HTTPRoute` aceptado por el Gateway

### 5.2 Publicacion de nueva imagen y rollout

Para incluir la correccion de salud en rutas publicas, se construyo y publico nueva imagen:

```bash
cd src/rust-api
docker build -t gcr.io/proyecto3-202300625/rust-api:v2 .
docker push gcr.io/proyecto3-202300625/rust-api:v2
kubectl -n default set image deployment/rust-api-deployment rust-api=gcr.io/proyecto3-202300625/rust-api:v2
kubectl rollout status deployment/rust-api-deployment --timeout=240s
```

Resultado del push:

```text
v2: digest: sha256:a57481dc529247e043401f261bfa204387ca540a956af0a7f55578ec50f0a131 size: 1187
```

Resultado del rollout:

```text
deployment "rust-api-deployment" successfully rolled out
```

### 5.3 Pruebas de humo publicas

IP del Gateway obtenida en estado: `34.110.235.118`

Prueba GET de salud por ruta publica:

```bash
curl -i http://34.110.235.118/grpc-202300625
```

Salida:

```text
HTTP/1.1 200 OK
Reports endpoint ready
```

Prueba POST de flujo principal:

```bash
curl -i -X POST http://34.110.235.118/grpc-202300625 \
	-H 'Content-Type: application/json' \
	-d '{"country":"ESP","warplanes_in_air":10,"warships_in_water":5,"timestamp":"2026-04-17T22:20:00Z"}'
```

Salida actual:

```text
HTTP/1.1 500 Internal Server Error
{"message":"Failed to connect to Go service: error sending request for url (http://localhost:8081/api/reports)","status":"error"}
```

Interpretacion: la API Rust ya esta expuesta y recibiendo trafico correctamente; falta configurar/desplegar el servicio Go destino y ajustar `GO_SERVICE_URL` del Deployment para completar el flujo end-to-end.

---

## 6. Archivos Modificados

- `kube/rust-api-httproute-v2.yaml`
- `kube/rust-api-deploy.yaml`
- `kube/go-receiver-deploy.yaml` (nuevo)
- `kube/go-receiver-service.yaml` (nuevo)
- `src/rust-api/src/main.rs`
- `src/go-server/main.go` (nuevo)
- `src/go-server/go.mod` (nuevo)
- `src/go-server/Dockerfile` (nuevo)
- `implementacion_gateway_rust.md` (nuevo)

---

## 7. Comandos Recomendados para Despliegue

```bash
kubectl apply -f kube/rust-api-httproute-v2.yaml
kubectl apply -f kube/rust-api-deploy.yaml
kubectl apply -f kube/rust-api-service.yaml
```

Para revisar que la ruta este aplicada:

```bash
kubectl get httproute rust-api-httproute -o yaml
```

---

## 8. Registro de Ejecucion (Comandos y Salidas)

### 8.1 Verificacion de contexto cloud

Comando:

```bash
gcloud config get-value project
gcloud auth list --filter=status:ACTIVE --format='value(account)'
gcloud container clusters list --region=us-east1
kubectl config current-context
kubectl get nodes -o wide
```

Salida relevante:

```text
proyecto3-202300625
carlosdelcid222@gmail.com
gke-kubevirt-cluster  us-east1  ...  STATUS RUNNING
gke_proyecto3-202300625_us-east1_gke-kubevirt-cluster
3 nodos Ready
```

### 8.2 Estado previo de ruta publica

Comando:

```bash
curl -i -X POST http://34.110.235.118/grpc-202300625 \
	-H 'Content-Type: application/json' \
	-d '{"country":"ESP","warplanes_in_air":10,"warships_in_water":5,"timestamp":"2026-04-17T22:20:00Z"}'
```

Salida:

```text
HTTP/1.1 500 Internal Server Error
{"message":"Failed to connect to Go service: error sending request for url (http://localhost:8081/api/reports)","status":"error"}
```

### 8.3 Build y push de Go receptor

Comando:

```bash
cd src/go-server
docker build -t gcr.io/proyecto3-202300625/go-receiver:v1 .
docker push gcr.io/proyecto3-202300625/go-receiver:v1
```

Salida relevante:

```text
Successfully tagged gcr.io/proyecto3-202300625/go-receiver:v1
v1: digest: sha256:bbb79b4d36f95ec102dd003d3558ccb9d1dfc93e97907a671dec2a7975a68794 size: 968
```

### 8.4 Despliegue en Kubernetes (Go + Rust)

Comando:

```bash
kubectl apply -f kube/go-receiver-deploy.yaml
kubectl apply -f kube/go-receiver-service.yaml
kubectl apply -f kube/rust-api-deploy.yaml
kubectl rollout status deployment/go-receiver-deployment --timeout=240s
kubectl rollout status deployment/rust-api-deployment --timeout=240s
```

Salida relevante:

```text
deployment.apps/go-receiver-deployment created
service/go-receiver-service created
deployment.apps/rust-api-deployment configured
deployment "go-receiver-deployment" successfully rolled out
deployment "rust-api-deployment" successfully rolled out
```

### 8.5 Validacion de GO_SERVICE_URL aplicado

Comando:

```bash
kubectl get deploy rust-api-deployment -o=jsonpath='{.spec.template.spec.containers[0].env}'
```

Salida:

```text
[{"name":"GO_SERVICE_URL","value":"http://go-receiver-service.default.svc.cluster.local:8081/api/reports"}]
```

### 8.6 Prueba final desde Gateway publico

Comando:

```bash
curl -i -X POST http://34.110.235.118/grpc-202300625 \
	-H 'Content-Type: application/json' \
	-d '{"country":"ESP","warplanes_in_air":10,"warships_in_water":5,"timestamp":"2026-04-17T22:40:00Z"}'
```

Salida final:

```text
HTTP/1.1 201 Created
{"message":"Report forwarded to Go service successfully","status":"success"}
```

Resultado: flujo validado con respuesta exitosa `201` desde el Gateway publico.

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*
