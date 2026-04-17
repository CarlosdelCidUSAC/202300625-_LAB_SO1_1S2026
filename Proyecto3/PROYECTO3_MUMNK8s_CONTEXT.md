# Proyecto 3 — M.U.M.N.K8s: Contexto completo para IA

> **Curso:** Sistemas Operativos 1 — Universidad San Carlos de Guatemala (USAC), Facultad de Ingeniería, ECYS  
> **Ponderación:** 50 puntos | **Tiempo estimado:** 60 horas  
> **Fecha de asignación:** 19/03/2026 | **Fecha límite de entrega:** 30/04/2026  
> **Calificación:** 02/05/2026 – 04/05/2026  
> **Modalidad:** Individual. **NO HABRÁ PRÓRROGA.**

---

## 1. Resumen del proyecto

El proyecto consiste en diseñar e implementar un **sistema distribuido y escalable** en Google Cloud Platform (GCP) que simula el monitoreo de recursos militares en tiempo real. Se reciben reportes de distintos países (aviones en el aire, barcos en el mar), se procesan a través de una cadena de microservicios y se visualizan en dashboards de Grafana.

El nombre completo es **Monitoreo de Unidades Militares en la Nube con Kubernetes (M.U.M.N.K8s)**.

---

## 2. Tecnologías obligatorias

| Componente | Tecnología | Notas |
|---|---|---|
| Infraestructura cloud | **GCP (Google Cloud Platform)** | Instancias N1 |
| Orquestación | **GKE (Google Kubernetes Engine)** | Penalización -80% si no se usa |
| Generador de carga | **Locust** | Penalización -10% si no se usa |
| API REST de entrada | **Rust** | Con HPA (1–3 réplicas, CPU > 30%) |
| Servicios internos | **Go** | 3 deployments distintos |
| Comunicación interna | **gRPC** | Protocolo proto3 |
| Message broker | **RabbitMQ** | Penalización -30% si no se usa |
| Base de datos | **Valkey** en **KubeVirt** VM | Penalización -15% si no se usa correctamente |
| Visualización | **Grafana** en **KubeVirt** VM | Penalización -60% si no se usa correctamente |
| Container registry | **Zot** en VM de GCP (fuera del clúster) | Penalización -5% si no se usa |
| Exposición de servicios | **Kubernetes Gateway API** | Reemplaza Ingress Controller |
| Virtualización en K8s | **KubeVirt** | Para Valkey y Grafana |
| OCI Artifact | Descarga de archivo de entrada desde Zot como OCI Artifact | Documentar qué archivo y cómo se usa |

---

## 3. Arquitectura general del sistema

```
[Locust] 
    │ POST /grpc-#carnet (JSON)
    ▼
[Kubernetes Gateway API]
    │
    ▼
[API REST - Rust] ◄── HPA (1-3 réplicas, CPU > 30%)
    │ HTTP
    ▼
[Go Deployment 1: API REST + gRPC Client]  (1-3 réplicas)
    │ gRPC
    ▼
[Go Deployment 2/3: gRPC Server + RabbitMQ Writer]  (1 o 2 réplicas)
    │ AMQP (publish)
    ▼
[RabbitMQ]  ◄── broker principal
    │ AMQP (consume)
    ▼
[Go Consumer/RabbitMQ Client]  (1-2 réplicas)
    │
    ▼
[Valkey DB]  ← dentro de KubeVirt VM1 (dentro del clúster GKE)
    │
    ▼
[Grafana]    ← dentro de KubeVirt VM2 (dentro del clúster GKE)

[Zot Registry] ← VM de GCP FUERA del clúster (todas las imágenes Docker pasan por aquí)
```

**Flujo opcional (extra):**

```
[Go Deployment 1] ──DAPR──► [Dapr sidecar] ──► ... (ruta /dapr-#carnet)
```

---

## 4. Estructura de los mensajes JSON

Locust envía reportes militares con la siguiente estructura:

```json
{
  "country": "ESP",
  "warplanes_in_air": 42,
  "warships_in_water": 14,
  "timestamp": "2026-03-12T20:15:30Z"
}
```

### Reglas de generación

- `country`: código de país de 3 letras. Solo se aceptan: `USA`, `RUS`, `CHN`, `ESP`, `GTM`.
- `warplanes_in_air`: entero aleatorio entre **0 y 50**.
- `warships_in_water`: entero aleatorio entre **0 y 30**.
- `timestamp`: fecha y hora en formato ISO 8601.

---

## 5. Definición gRPC (proto3)

```proto
syntax = "proto3";
package wartweets;
option go_package = "./proto";

message WarReportRequest {
  Countries country = 1;
  int32 warplanes_in_air = 2;
  int32 warships_in_water = 3;
  string timestamp = 4;
}

enum Countries {
  countries_unknown = 0;
  usa = 1;
  rus = 2;
  chn = 3;
  esp = 4;
  gtm = 5;
}

message WarReportResponse {
  string status = 1;
}

service WarReportService {
  rpc SendReport (WarReportRequest) returns (WarReportResponse);
}
```

---

## 6. Rutas del Gateway API

| Ruta | Descripción |
|---|---|
| `/grpc-#carnet` | Flujo principal (obligatorio) |
| `/dapr-#carnet` | Flujo alternativo con Dapr (opcional, punteo extra) |

> Reemplazar `#carnet` con el número de carnet del estudiante.

---

## 7. Deployments de Go (detalle)

| Deployment | Rol | Notas |
|---|---|---|
| **Deployment 1** | API REST + gRPC Client | Recibe de Rust, invoca funciones para publicar en RabbitMQ vía gRPC |
| **Deployment 2** | gRPC Server + RabbitMQ Writer | Recibe llamadas gRPC y publica mensajes en RabbitMQ |
| **Deployment 3** | (variante del 2 para pruebas) | Se prueban con 1 y 2 réplicas para análisis de rendimiento |
| **Consumer** | RabbitMQ Consumer | Consume mensajes de RabbitMQ y almacena en Valkey |

---

## 8. KubeVirt (máquinas virtuales dentro de GKE)

- **VM1:** Valkey (base de datos key-value). Debe asegurar persistencia y conectividad con los consumers.
- **VM2:** Grafana (visualización). Debe conectarse a la fuente de datos (Valkey) para los dashboards.
- Ambas VMs son **independientes** y administradas por KubeVirt **dentro del clúster GKE**.

---

## 9. Zot (Container Registry)

- Desplegado en una **VM de GCP fuera del clúster Kubernetes**.
- **Todas** las imágenes Docker de los componentes se publican y se consumen desde Zot.
- También se usa para almacenar y descargar un archivo de entrada como **OCI Artifact** (especificar en documentación qué archivo y cómo se usa).

---

## 10. HPA (Horizontal Pod Autoscaler)

- Se aplica al deployment de **Rust (API REST)**.
- Configuración: mínimo 1 réplica, máximo 3 réplicas, umbral CPU > 30%.
- Se deben realizar pruebas comparativas con **1 y 2 réplicas** en los deployments de Go Writers para análisis de rendimiento.

---

## 11. Dashboard de Grafana requerido

### Asignación de país según último dígito del carnet

| Dígito | País |
|---|---|
| 0, 1 | USA |
| 2, 3 | RUS |
| 4, 5 | CHN |
| 6, 7 | ESP |
| 8, 9 | GTM |

### Visualizaciones obligatorias

1. Valor máximo general de aviones en aire
2. Valor mínimo general de aviones en aire
3. Valor máximo general de barcos en mar
4. Valor mínimo general de barcos en mar
5. Top de países con más aviones en aire
6. Top de países con más barcos en mar
7. Moda de aviones en aire
8. Moda de barcos en mar
9. Serie temporal del país asignado: evolución de aviones en aire y barcos en mar
10. Nombre del país asignado (stat panel)
11. Cantidad total de reportes recibidos del país asignado

---

## 12. Entregables

1. **Código fuente** en repositorio privado de GitHub.
   - Usar el **mismo repositorio** del Proyecto 1.
   - Carpeta: `proyecto3`.
   - Agregar como colaboradores: `@roldyoran`, `@JoseLorenzana272`, `@KINGR0X`.
2. **Manual técnico** en formato **Markdown** (obligatorio, dentro del repositorio GitHub).
   - Penalización de 0 puntos en el proyecto si no se entrega en Markdown.
3. **Capturas de prueba y evidencia funcional**.
4. **Entrega en UEDI** (plataforma de la universidad, independientemente del auxiliar asignado).
   - Si no se entrega en UEDI: nota automática de **0 puntos**.

---

## 13. Contenido del Manual Técnico (Markdown)

El manual debe incluir:

- Arquitectura general del sistema
- Flujo completo de datos
- Configuración de Gateway API
- Comunicación REST y gRPC
- Uso de RabbitMQ
- Despliegue de Valkey y Grafana sobre KubeVirt
- Configuración de HPA
- Publicación/consumo de imágenes desde Zot
- Descripción del OCI Artifact usado
- Pruebas realizadas y conclusiones
- Análisis comparativo de rendimiento (1 vs 2 réplicas para Go Writers)

---

## 14. Restricciones y penalizaciones

### Requisitos que anulan la nota (nota = 0 automáticamente)

- No entregar en UEDI
- No entregar el manual técnico en formato Markdown en el repositorio GitHub

### Penalizaciones por elemento faltante

| Elemento técnico | Penalización |
|---|---|
| GKE (Google Kubernetes Engine) | -80% de la nota final |
| Grafana con KubeVirt | -60% de la nota final |
| RabbitMQ | -30% de la nota final |
| Valkey con KubeVirt | -15% de la nota final |
| Locust | -10% de la nota final |
| Zot | -5% de la nota final |

---

## 15. Rúbrica de calificación

| Criterio | Puntos |
|---|---|
| Arquitectura General / Kubernetes Gateway API | 5 |
| API REST en Rust (funcional y escalable) | 5 |
| Servicios Go (gRPC Client, Server, Writer, concurrencia) | 10 |
| Despliegue en GCP + Zot correctamente configurado | 10 |
| RabbitMQ + Consumer (publicación y consumo correcto) | 15 |
| Valkey con KubeVirt (almacenamiento funcional) | 20 |
| Grafana con KubeVirt (dashboards completos) | 25 |
| **Sub-total conocimiento** | **90** |
| Pruebas de carga, HPA, análisis de réplicas (Locust) | 5 |
| Manual técnico (Markdown, completo) | 2 |
| Respuestas a preguntas durante la calificación | 3 |
| **Sub-total habilidades** | **10** |
| **TOTAL** | **100** |

---

## 16. Alcance opcional (punteo extra en Clase Magistral)

- Implementar un flujo alternativo de mensajería usando **Dapr** (SDK integrado en los servicios Go).
- Expuesto en la ruta `/dapr-#carnet`.
- Solo se otorga el punteo extra si la nota del proyecto es **≥ 90 puntos**.
- El punteo es **neto sobre la clase magistral**, no sobre el proyecto.
- Debe estar completamente documentado en el manual técnico.

---

## 17. Metodología por fases

### Fase 1 — Infraestructura base (Semana 1)
- Crear clúster GKE con instancias N1
- Verificar soporte para KubeVirt y virtualización anidada
- Instalar Zot en VM de GCP fuera del clúster
- Desarrollar y dockerizar API REST en Rust → publicar en Zot
- Desarrollar Go Deployment 1 (gRPC Client) → publicar en Zot
- Configurar Locust
- Configurar Kubernetes Gateway API
- Prueba inicial: `Locust → Gateway API → API Rust → Go Deployment 1`

### Fase 2 — Comunicación interna y mensajería (Semana 2)
- Desplegar RabbitMQ en GKE
- Desarrollar Go Deployment 2 (gRPC Server + RabbitMQ Writer) → publicar en Zot
- Integrar Deployment 1 con Deployment 2 vía gRPC
- Configurar ruta `/grpc-#carnet`
- Probar publicación de mensajes en RabbitMQ

### Fase 3 — Consumo y persistencia (Semana 2)
- Desarrollar Go Consumer → publicar en Zot
- Desplegar KubeVirt en el clúster
- Crear VM1 para Valkey en KubeVirt
- Instalar y configurar Valkey en VM1
- Integrar Consumer con Valkey
- Probar consumo y persistencia

### Fase 4 — Visualización y pruebas de carga (Semana 3)
- Crear VM2 para Grafana en KubeVirt
- Configurar dashboards en Grafana
- Implementar ruta `/dapr-#carnet` (opcional)
- Pruebas de carga con Locust
- Probar y ajustar HPA en Rust
- Análisis comparativo con 1 y 2 réplicas en Go Writers

### Fase 5 — Documentación, validación y entrega (Semana 4)
- Redactar manual técnico en Markdown
- Verificar todos los componentes en el repositorio
- Validar imágenes en Zot
- Entrega final en UEDI y GitHub

---

## 18. Material de apoyo oficial

- Ejemplos del curso: https://github.com/JoseLorenzana272/LAB-SO1-1S2026/tree/main/ejemplos
- Dapr sidecar: https://docs.dapr.io/concepts/dapr-services/sidecar/
- KubeVirt: https://kubevirt.io/
- Diagrama de arquitectura HD: https://drive.google.com/file/d/1xd_uKJ_6Q9pJ66fJwinSK-5CKvBwni_q/view?usp=sharing

---

## 19. Consideraciones técnicas recomendadas

- Usar **namespaces** de Kubernetes para organizar los componentes.
- Definir `requests` y `limits` en los deployments para mejorar estabilidad.
- Configurar **TTL o políticas de expiración en Valkey** para evitar saturación de memoria.
- Crear imágenes Docker propias para todos los componentes.
- Asegurar conectividad entre el Consumer (pod dentro del clúster) y la VM de Valkey (dentro de KubeVirt).
- Asegurar conectividad entre Grafana (VM KubeVirt) y la fuente de datos Valkey.

---

## 20. Países válidos del sistema

| Código | País |
|---|---|
| `USA` | Estados Unidos |
| `RUS` | Rusia |
| `CHN` | China |
| `ESP` | España |
| `GTM` | Guatemala |
