# Implementacion de Integracion Dapr (Proyecto3)

Este documento registra la implementacion aplicada para habilitar una nueva ruta publica hacia Dapr a traves de la API Rust, manteniendo compatibilidad con el flujo existente de Gateway API.

---

## 1. Objetivo

Habilitar el flujo de entrada `/dapr-202300625` para pruebas de carga y reenviar el payload desde Rust hacia el endpoint de Go `POST /dapr/reports`.

---

## 2. Problema a Resolver

Antes de este cambio, el flujo publico solo estaba habilitado para:

- `/grpc-202300625`

No existia una ruta dedicada para Dapr en el Gateway ni un endpoint equivalente en la API Rust para reenviar solicitudes al endpoint Dapr del servicio Go.

---

## 3. Cambios Implementados

### 3.1 Nuevo endpoint Dapr en Rust API

Archivo modificado: `src/rust-api/src/main.rs`

Se agrego:

- estado compartido `go_dapr_service_url`
- handler `receive_dapr_report` para `POST /dapr`
- ruta de compatibilidad `POST /dapr-202300625`
- health endpoint para ruta Dapr (respuesta `200`)

Comportamiento del nuevo handler:

1. valida pais (`USA`, `RUS`, `CHN`, `ESP`, `GTM`)
2. reenvia JSON a `GO_DAPR_SERVICE_URL`
3. responde `201` si Go responde exitosamente
4. responde error controlado (`502` o `500`) si falla el destino

### 3.2 Nueva regla de enrutamiento en HTTPRoute

Archivo modificado: `kube/rust-api-httproute.yaml`

Se agrego la regla:

```yaml
- matches:
  - path:
      type: PathPrefix
      value: /dapr-202300625
  backendRefs:
  - name: rust-api-service
    port: 80
```

### 3.3 Consistencia en variante v2 del HTTPRoute

Archivo modificado: `kube/rust-api-httproute-v2.yaml`

Se agrego la misma regla para evitar diferencia funcional entre manifests cuando se aplica el directorio `kube/` completo.

### 3.4 Variable de entorno para forwarding Dapr

Archivo modificado: `kube/rust-api-deploy.yaml`

Se agrego:

```yaml
- name: GO_DAPR_SERVICE_URL
  value: http://go-client-service.default.svc.cluster.local:8081/dapr/reports
```

Esto evita que Rust use el fallback local (`localhost`) dentro de Kubernetes.

---

## 4. Validacion Realizada

### 4.1 Compilacion de Rust API

Comando ejecutado:

```bash
cd src/rust-api
cargo check
```

Salida relevante:

```text
Checking rust-api v0.1.0 (.../src/rust-api)
Finished `dev` profile [unoptimized + debuginfo] target(s) in 1.46s
```

Estado: compilacion correcta.

### 4.2 Aplicacion de manifests en cluster

Comando ejecutado:

```bash
kubectl apply -f kube/rust-api-deploy.yaml
kubectl apply -f kube/rust-api-httproute.yaml
```

Resultado observado: ejecucion sin error (exit code 0 en terminal).

---

## 5. Archivos Modificados

- `src/rust-api/src/main.rs`
- `kube/rust-api-httproute.yaml`
- `kube/rust-api-httproute-v2.yaml`
- `kube/rust-api-deploy.yaml`
- `implementacion_dapr.md` (nuevo)

---

## 6. Comandos Recomendados de Verificacion

```bash
kubectl get httproute rust-api-httproute -o yaml
kubectl get deploy rust-api-deployment -o=jsonpath='{.spec.template.spec.containers[0].env}'
```

Prueba funcional por Gateway:

```bash
curl -i -X POST http://<GATEWAY_IP>/dapr-202300625 \
  -H 'Content-Type: application/json' \
  -d '{"country":"ESP","warplanes_in_air":10,"warships_in_water":5,"timestamp":"2026-04-19T20:00:00Z"}'
```

---

## 7. Uso en Locust

Con este cambio ya se puede generar carga contra ambos endpoints publicos:

- `/grpc-202300625`
- `/dapr-202300625`

Recomendacion:

- ejecutar escenarios separados para comparar latencia, throughput y codigos de respuesta entre flujo gRPC previo y flujo Dapr.
