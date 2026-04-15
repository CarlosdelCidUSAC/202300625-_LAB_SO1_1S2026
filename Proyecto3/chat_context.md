# Contexto del Proyecto #3 M.U.M.N.K8s

Resumen exhaustivo y estructurado del proyecto "Monitoreo de Unidades Militares en la Nube con Kubernetes", extraído del chat DeepSeek. Este documento proporciona el contexto completo que una IA necesita para asistir en el desarrollo, depuración o documentación del proyecto.

---

## 🎯 Objetivo General del Proyecto

Implementar una **arquitectura de sistema distribuido, escalable y resiliente** en **Google Cloud Platform (GCP)** que simule la recepción y procesamiento en tiempo real de reportes militares. El sistema debe integrar **contenedores, orquestación con Kubernetes (GKE), virtualización anidada (KubeVirt), mensajería (RabbitMQ), almacenamiento en memoria (Valkey) y visualización (Grafana)**, con todas las imágenes publicadas en un registro privado **Zot**.

---

## 🧱 Componentes Clave y Flujo de Datos (Obligatorio)

El flujo principal del sistema sigue esta ruta:

```
Locust → Gateway API → Rust API → Go Deployment 1 → Go Deployments 2/3 → RabbitMQ → Consumer → Valkey → Grafana
```

### Detalle de cada componente:

| Componente | Lenguaje / Tecnología | Rol en el Sistema |
|------------|----------------------|-------------------|
| **Locust** | Python (Framework) | Genera tráfico HTTP simulado hacia el endpoint público expuesto por el Gateway API. Envía datos JSON con estructura de reporte militar. |
| **Kubernetes Gateway API** | K8s Resource | Reemplaza al Ingress Controller. Expone las rutas `/grpc-#carnet` y, opcionalmente, `/dapr-#carnet`. |
| **API REST (Rust)** | Rust | Recibe peticiones HTTP de Locust, las valida y las reenvía al **Go Deployment 1** mediante gRPC. Debe escalar automáticamente con **HPA** (1-3 réplicas, CPU > 30%). |
| **Go Deployment 1** | Go | Actúa como **cliente gRPC**. Recibe la solicitud del servicio Rust e invoca el método `SendReport` en los servidores gRPC (Deployments 2 y 3). |
| **Go Deployments 2 y 3** | Go | Son **servidores gRPC** que implementan el servicio `WarReportService`. Al recibir el mensaje, actúan como **escritores (Writers)** y publican el mensaje en **RabbitMQ**. Se requieren pruebas con 1 y 2 réplicas. |
| **RabbitMQ** | Erlang/OTP | **Broker de mensajería principal** (obligatorio). Recibe los mensajes de los escritores Go y los encola para su consumo. |
| **Consumer (Go)** | Go | Se suscribe a la cola de RabbitMQ, consume los mensajes, los procesa (ej. agregaciones) y almacena los resultados en **Valkey**. |
| **Valkey** | Valkey (fork de Redis) | Base de datos en memoria. Debe ejecutarse **obligatoriamente dentro de una máquina virtual (VM) administrada por KubeVirt** dentro del clúster. Almacena los datos procesados para que Grafana los lea. |
| **Grafana** | Grafana | Herramienta de visualización. Debe ejecutarse **obligatoriamente en una VM independiente administrada por KubeVirt**. Debe mostrar dashboards con métricas específicas. |
| **Zot** | Go (Registry) | Registro de contenedores **externo al clúster GKE**. Se despliega en una **VM de GCP**. Todas las imágenes Docker del proyecto deben ser **publicadas y descargadas desde Zot**. |
| **OCI Artifact** | - | Se debe descargar un archivo desde Zot como un **OCI Artifact** (no solo una imagen de contenedor). La documentación debe explicar qué archivo es y cómo se usa. |

---

## 📦 Estructura de Datos y Comunicación

### 1. Mensaje JSON (Enviado por Locust → Recibido por Rust API)

```json
{
  "country": "ESP",
  "warplanes_in_air": 42,
  "warships_in_water": 14,
  "timestamp": "2026-03-12T20:15:30Z"
}
```

**Reglas de generación en Locust:**
- `country`: Código de país de 3 letras (debe coincidir con los valores del enum `Countries` en el archivo `.proto`).
- `warplanes_in_air`: Entero aleatorio entre **0 y 50**.
- `warships_in_water`: Entero aleatorio entre **0 y 30**.
- `timestamp`: Fecha y hora actual en formato ISO 8601.

### 2. Contrato gRPC (`.proto`)

La comunicación entre servicios Go y Rust debe seguir esta definición exacta:

```protobuf
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

## 📊 Dashboards Requeridos en Grafana

Grafana debe mostrar **obligatoriamente** los siguientes paneles, basados en los datos almacenados en Valkey. La asignación del país a monitorear en la "Serie temporal" depende del **último dígito del carnet** del estudiante:

| Último dígito carnet | País asignado |
|---------------------|---------------|
| 0, 1 | USA |
| 2, 3 | RUS |
| 4, 5 | CHN |
| 6, 7 | ESP |
| 8, 9 | GTM |

**Visualizaciones obligatorias:**

1. Valor máximo general de aviones en aire.
2. Valor mínimo general de aviones en aire.
3. Valor máximo general de barcos en mar.
4. Valor mínimo general de barcos en mar.
5. **Top de países** con más aviones en aire.
6. **Top de países** con más barcos en mar.
7. **Moda** de aviones en aire.
8. **Moda** de barcos en mar.
9. **Serie temporal** del **país asignado**, mostrando la evolución de:
   - Aviones en aire.
   - Barcos en mar.
10. **Nombre** del país asignado.
11. **Cantidad total de reportes recibidos** del país asignado.

---

## 🗓️ Metodología y Cronograma (4 Semanas)

| Fase | Semana | Actividades Principales |
|------|--------|-------------------------|
| **1. Infraestructura Base** | 1 | Configurar GCP, GKE, VM Zot, Gateway API. Crear API Rust y Go Deployment 1. Probar flujo inicial Locust → Gateway → Rust → Go1. |
| **2. Mensajería y Publicación** | 2 | Desplegar RabbitMQ. Crear Go Deployments 2 y 3 (gRPC Server/Writer). Integrar gRPC y probar publicación en RabbitMQ. |
| **3. Consumo y KubeVirt** | 2 | Crear Consumer Go. Instalar **KubeVirt** en GKE. Crear VM para **Valkey**, configurar persistencia y probar almacenamiento. |
| **4. Visualización y Pruebas** | 3 | Crear VM para **Grafana**, configurar dashboards. Implementar **HPA** en Rust. Realizar pruebas de carga con Locust y analizar rendimiento con 1 vs 2 réplicas en Go Writers. |
| **5. Documentación y Entrega** | 4 | Redactar **Manual Técnico en Markdown**. Validar todo el sistema y preparar entrega en repositorio GitHub y plataforma UEDI. |

---

## ⭐ Puntos Extra (Opcional): Implementación con Dapr

- **Ruta adicional**: `/dapr-#carnet`
- **Requisito**: Integrar **Dapr Sidecar** en los servicios Go que usan gRPC para habilitar un flujo alternativo de envío/recepción de mensajes.
- **Condición**: Solo se otorga puntuación extra si la nota del proyecto base es **≥ 90 puntos**.
- **Documentación requerida**: Comparativa de arquitectura y rendimiento entre el flujo gRPC estándar y el flujo con Dapr.

---

## 📋 Entregables Obligatorios

1. **Repositorio Privado en GitHub**:
   - Mismo repositorio del Proyecto 1, pero en una carpeta **`proyecto3/`**.
   - Agregar como colaboradores a los auxiliares: `@roldyoran`, `@JoseLorenzana272`, `@KINGROX`.

2. **Manual Técnico** en **formato Markdown**.

3. **Evidencia funcional**: Capturas de pantalla y pruebas.

---

## 🚫 Restricciones y Penalizaciones Críticas

El incumplimiento de **cualquiera** de estos dos puntos conlleva una **nota automática de 0**:

- ❌ **No entregar en la plataforma UEDI**.
- ❌ **No entregar el Manual Técnico en Markdown dentro de GitHub**.

Además, omitir los siguientes componentes técnicos **penaliza la nota final** con un porcentaje de reducción:

| Componente Faltante o Incorrecto | Penalización sobre Nota Final |
|----------------------------------|-------------------------------|
| **No usar GKE** | -80% |
| **No usar Grafana con KubeVirt** | -60% |
| **No usar RabbitMQ** | -30% |
| **No usar Valkey con KubeVirt** | -15% |
| **No usar Locust** | -10% |
| **No usar Zot** | -5% |

> **Ejemplo**: Si un proyecto tiene una calificación inicial de 85 puntos pero no implementó Grafana en KubeVirt, la nota final será: `85 - (85 * 0.60) = 34 puntos`.

---

## 💻 Infraestructura y Configuración Técnica

- **Cloud Provider**: Google Cloud Platform (GCP).
- **Tipo de instancia para GKE**: `N1` (se requiere virtualización anidada para KubeVirt).
- **Container Registry**: **Zot** desplegado en una **VM de GCP** independiente (fuera del clúster GKE).
- **Namespace**: Se recomienda usar namespaces en Kubernetes para organizar los componentes.
- **Gateway API**: Uso obligatorio de **HTTPRoute** y recursos de Gateway API, no Ingress.
- **HPA**: Configurado en el **Deployment de Rust** con métrica de CPU > 30% (mín 1 réplica, máx 3 réplicas).
- **Requests y Limits**: Recomendado para mejorar la estabilidad.

---

## 📝 Estructura Sugerida del Manual Técnico (Markdown)

1. **Arquitectura General**: Diagrama y explicación de cada componente.
2. **Configuración de GCP y GKE**: Pasos para crear el clúster y la VM de Zot.
3. **Gateway API**: Configuración de rutas y exposición de servicios.
4. **Despliegue de Componentes**:
   - Rust API (Dockerfile, HPA).
   - Go Services (Client, Server/Writer, Consumer).
   - RabbitMQ.
5. **KubeVirt**: Instalación y creación de VMs para Valkey y Grafana.
6. **Publicación en Zot**: Proceso de subida y descarga de imágenes, incluyendo OCI Artifact.
7. **Pruebas Realizadas**:
   - Carga con Locust.
   - Análisis comparativo de 1 vs 2 réplicas en Go Writers.
   - Capturas de los dashboards de Grafana.
8. **Conclusiones** y hallazgos.

---

## 🤖 Contexto Adicional para la IA

- **Rol del estudiante**: Desarrollador y Arquitecto Cloud único. El proyecto es **individual**.
- **Duración total estimada**: 60 horas.
- **Valor del proyecto**: 50 puntos del curso.
- **Enfoque del curso**: Sistemas Operativos 1, con énfasis en virtualización, contenedores y orquestación.
- **Material de apoyo oficial**: Repositorio de ejemplos del auxiliar [JoseLorenzana272](https://github.com/JoseLorenzana272/LAB-SO1-1S2026/tree/main/ejemplos).

---

*Este resumen cubre todos los aspectos técnicos y normativos que una IA necesita conocer para asistir en el desarrollo, depuración o documentación del Proyecto #3 M.U.M.N.K8s.*

*Última actualización: 15/04/2026*  
*Proyecto: Proyecto3_202300625*