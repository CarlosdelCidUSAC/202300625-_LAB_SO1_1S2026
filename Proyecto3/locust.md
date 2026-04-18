# Implementacion de Locust para Proyecto3

Este documento registra la implementacion realizada para el generador de carga **Locust** del Proyecto 3, siguiendo el mismo estilo tecnico de los demas componentes documentados en el repositorio.

---

## 1. Objetivo

Implementar un generador de carga que permita:

- simular trafico concurrente hacia el Gateway API,
- enviar reportes militares con la estructura definida por el proyecto,
- medir latencia, throughput y tasa de errores del flujo completo,
- probar el escalado del backend y del camino de mensajeria.

---

## 2. Arquitectura aplicada

Componentes usados:

1. `Locust` como cliente HTTP de carga.
2. `Gateway API` como punto de entrada al sistema.
3. `Rust API` como primer servicio del flujo.
4. `Go services`, `RabbitMQ`, `Consumer`, `Valkey` y `Grafana` como backend.

Flujo principal:

`Locust -> Gateway API -> Rust API -> Go -> RabbitMQ -> Consumer -> Valkey -> Grafana`

---

## 3. Script implementado

Archivo principal:

- `locust/locustfile.py`

### 3.1 Comportamiento del usuario simulado

La clase implementada es:

- `MilitaryTrafficSimulator`

Configuracion aplicada:

- hereda de `HttpUser`,
- usa `wait_time = between(1, 3)`,
- genera reportes con paises validos del sistema,
- envia peticiones `POST` al Gateway API.

### 3.2 Generacion del payload

Cada solicitud genera datos aleatorios siguiendo las reglas del proyecto:

- `country`: uno de `USA`, `RUS`, `CHN`, `ESP`, `GTM`
- `warplanes_in_air`: entero entre `0` y `50`
- `warships_in_water`: entero entre `0` y `30`
- `timestamp`: formato ISO 8601 UTC

### 3.3 Parametrizacion para el entorno

El script ya no depende de valores fijos. Se configuraron dos variables de entorno:

- `LOCUST_HOST`: host base del Gateway API
- `LOCUST_PATH`: ruta del endpoint a probar

Valores por defecto:

- `LOCUST_PATH = /grpc-202300625`

Con esto, el mismo script sirve para distintos entornos sin tocar el codigo.

### 3.4 Manejo de respuestas

Se considera exitoso si el backend responde:

- `200 OK`
- `201 Created`

Cualquier otro codigo queda marcado como fallo en Locust.

---

## 4. Comandos de ejecucion

### 4.1 Ejecutar Locust

```bash
cd locust
locust -f locustfile.py --host=http://34.54.104.14
```

Si el Gateway esta expuesto por HTTPS:

```bash
locust -f locustfile.py --host=https://34.54.104.14
```

### 4.2 Cambiar la ruta del Gateway

```bash
LOCUST_PATH=/grpc-202300625 locust -f locustfile.py --host=http://34.54.104.14
```

---

## 5. Validacion realizada

### 5.1 Verificacion de sintaxis

Se valido el script con compilacion de Python:

```bash
python -m py_compile locustfile.py
```

Resultado:

```text
Sin errores de sintaxis
```

### 5.2 Verificacion de errores en editor

Se reviso el archivo y no quedaron errores de lint o sintaxis en:

- `locust/locustfile.py`

---

## 6. Uso en pruebas de carga

Locust se utiliza para:

1. generar trafico sostenido hacia el Gateway API,
2. evaluar el rendimiento de la API Rust,
3. provocar carga para observar escalado con HPA,
4. comparar comportamiento del sistema bajo diferentes niveles de concurrencia.

La configuracion actual permite medir la ruta del flujo principal sin hardcodear el host o la ruta dentro del script.

---

## 7. Troubleshooting rapido

### 7.1 Locust no conecta al Gateway

Verificar que `LOCUST_HOST` apunte a la IP correcta y que el Gateway este disponible:

```bash
kubectl get gateway military-gateway
```

### 7.2 El endpoint responde 404

Verificar que `LOCUST_PATH` coincida con la ruta expuesta por el Gateway y que la reescritura hacia Rust este activa.

### 7.3 El backend devuelve 500

Revisar logs de la API Rust y de los servicios Go:

```bash
kubectl logs -l app=rust-api
kubectl logs -l app=go-client
kubectl logs -l app=go-server
```

### 7.4 No se observan metricas o carga

Aumentar usuarios o spawn rate desde la interfaz de Locust y confirmar que la prueba esta en estado `running`.

---

## 8. Estado actual

La implementacion de Locust queda lista para el flujo del Proyecto 3:

- genera trafico consistente,
- envia payloads validos,
- permite cambiar host y ruta por entorno,
- sirve para pruebas de carga y comparacion de rendimiento.

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*
