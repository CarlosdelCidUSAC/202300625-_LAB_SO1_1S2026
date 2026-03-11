# Manual Tecnico - Proyecto 2 SO1

## 1. Informacion General

- Curso: Sistemas Operativos 1
- Proyecto: Sonda de Kernel en C y Daemon en Go para telemetria de contenedores
- Carnet: 202300625
- Repositorio local: `/home/carlos/Desktop/Proyecto2`

### 1.1 Objetivo del sistema
Implementar una solucion de monitoreo y gestion automatizada de contenedores en Linux, integrada por:

- Un modulo de kernel en C que expone metricas en `/proc/continfo_pr2_so1_202300625`.
- Un daemon en Go que analiza datos, toma decisiones de eliminacion de contenedores y persiste metricas en Valkey.
- Un cronjob que genera carga variable cada 2 minutos.
- Un dashboard en Grafana para visualizacion historica y en tiempo real.

### 1.2 Alcance
Este manual cubre instalacion, configuracion, operacion, verificacion, troubleshooting y evidencias tecnicas del sistema implementado en el proyecto.

## 2. Arquitectura Tecnica

### 2.1 Componentes

1. `kernel-module/`:
   - Archivo clave: `kernel-module/src/sonda.c`.
   - Itera procesos usando `task_struct`.
   - Detecta procesos en contenedores por namespace de PID.
   - Publica memoria global y listado de procesos en `/proc`.

2. `daemon-go/`:
   - Entrypoint: `daemon-go/cmd/daemon/main.go`.
   - Coordinacion: `daemon-go/internal/orchestrator/orchestrator.go`.
   - Parseo: `daemon-go/internal/parser/parser.go`.
   - Analisis/decision: `daemon-go/internal/analyzer/analyzer.go`.
   - Persistencia: `daemon-go/internal/storage/valkey.go`.
   - Configuracion: `daemon-go/internal/config/config.go`.

3. `cron/`:
   - `cron/install-cron.sh`: instala ejecucion cada 2 minutos.
   - `cron/uninstall-cron.sh`: elimina cronjob.

4. `docker/`:
   - `docker/docker-compose.yml`: levanta `db_valkey` y `dashboard_grafana`.
   - `docker/generar.sh`: crea 5 contenedores aleatorios por ciclo.

5. `tests/`:
   - `tests/verificar-requisitos.sh`: validacion integral y generacion de evidencia.

### 2.2 Flujo de datos

1. El modulo kernel genera salida en `/proc/continfo_pr2_so1_202300625`.
2. El daemon parsea secciones `[MEMORIA]` y `[PROCESOS]`.
3. El analizador evalua uso de recursos y umbrales.
4. El daemon elimina contenedores elegibles respetando restricciones.
5. Las metricas se almacenan en Valkey.
6. Grafana consume las metricas y renderiza paneles.
7. En paralelo, cronjob genera contenedores para carga de prueba.

## 3. Requisitos del Entorno

### 3.1 Software requerido

- Linux con soporte de modulos de kernel.
- `gcc`, `make`, headers del kernel (`/lib/modules/$(uname -r)/build`).
- Go (compatible con `go.mod` del proyecto).
- Docker y Docker Compose (`docker-compose`).
- `sudo` con permisos para `insmod`, `rmmod` y operaciones Docker.
- `crontab` habilitado.

### 3.2 Recursos recomendados

- RAM >= 4 GB.
- Almacenamiento >= 10 GB libres.
- CPU con al menos 2 nucleos.

## 4. Estructura del Proyecto

```text
Proyecto2/
  kernel-module/
  daemon-go/
  docker/
  cron/
  tests/
  docs/
```

## 5. Instalacion y Despliegue

### 5.1 Preparacion inicial

```bash
cd /home/carlos/Desktop/Proyecto2
sudo echo "OK"
```

Limpieza opcional:

```bash
sudo ./tests/limpiar-entorno.sh
```

### 5.2 Compilar modulo kernel

```bash
cd /home/carlos/Desktop/Proyecto2/kernel-module
make clean && make
ls -lh build/sonda.ko
```

### 5.3 Cargar modulo kernel

```bash
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
lsmod | grep sonda
```

Verificacion de interfaz `/proc`:

```bash
head -40 /proc/continfo_pr2_so1_202300625
```

### 5.4 Levantar infraestructura (Valkey + Grafana)

```bash
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose up -d
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

Servicios esperados:

- `db_valkey` en puerto `6379`.
- `dashboard_grafana` en puerto `3000`.

### 5.5 Instalar cronjob de carga

```bash
bash /home/carlos/Desktop/Proyecto2/cron/install-cron.sh
crontab -l
```

Entrada esperada:

```cron
*/2 * * * * /home/carlos/Desktop/Proyecto2/docker/generar.sh >> /var/log/proyecto2-contenedores.log 2>&1
```

### 5.6 Compilar daemon Go

```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
go build -o bin/daemon-so1 cmd/daemon/main.go
ls -lh bin/daemon-so1
```

### 5.7 Ejecutar daemon

```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
sudo ./bin/daemon-so1
```

El daemon realiza:

- Inicio de Docker Compose.
- Carga del modulo kernel.
- Instalacion de cronjob.
- Loop de monitoreo cada 30 segundos (por defecto).

## 6. Especificacion Tecnica

### 6.1 Formato de salida del modulo `/proc`

El archivo `/proc/continfo_pr2_so1_202300625` usa este formato:

```text
[MEMORIA]
Total: <MB>
Libre: <MB>
Uso: <MB>

[PROCESOS]
PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID
```

Campos por proceso:

- `PID`: identificador de proceso.
- `Nombre`: `task->comm`.
- `VSZ`: memoria virtual en KB.
- `RSS`: memoria fisica en KB.
- `%RAM`: porcentaje con 2 decimales.
- `CPU`: aproximacion basada en `task->utime`.
- `ComandoID`: ruta ejecutable o etiqueta `container:pid<...>_ns<...>`.

### 6.2 Configuracion relevante del daemon

Valores por defecto (`daemon-go/internal/config/config.go`):

- `PROC_FILE=/proc/continfo_pr2_so1_202300625`
- `DOCKER_COMPOSE_PATH=/home/carlos/Desktop/Proyecto2/docker`
- `VALKEY_HOST=localhost`
- `VALKEY_PORT=6379`
- `CYCLE_DURATION=30` segundos
- `RAM_THRESHOLD=80.0`
- `CPU_THRESHOLD=90.0`
- `MinLowConsumption=3`
- `MinHighConsumption=2`

### 6.3 Reglas de decision y restricciones

Implementadas en `daemon-go/internal/analyzer/analyzer.go`:

1. Solo evaluar eliminacion cuando RAM global supera umbral (`RAM_THRESHOLD`).
2. No eliminar contenedores de infraestructura (`grafana`, `valkey`, `redis`).
3. Mantener minimo:
   - 3 contenedores de bajo consumo.
   - 2 contenedores de alto consumo.
4. Limitar eliminaciones por iteracion (maximo 5).

## 7. Persistencia en Valkey

Claves principales usadas por el daemon:

- `metrics:memory:current` (hash de memoria actual).
- `metrics:memory:history` (sorted set historico).
- `metrics:containers:ram:top` (sorted set top RAM).
- `metrics:containers:cpu:top` (sorted set top CPU).
- `stats:containers_deleted` (contador total eliminados).
- `metrics:containers:deleted:history` (historial de eliminacion).

Consultas de verificacion:

```bash
sudo docker exec db_valkey valkey-cli PING
sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current
sudo docker exec db_valkey valkey-cli ZREVRANGE metrics:containers:ram:top 0 4 WITHSCORES
sudo docker exec db_valkey valkey-cli ZREVRANGE metrics:containers:cpu:top 0 4 WITHSCORES
sudo docker exec db_valkey valkey-cli GET stats:containers_deleted
```

## 8. Integracion con Grafana

### 8.1 Acceso

- URL: `http://localhost:3000`
- Usuario: `admin`
- Password: `1234`

### 8.2 Provisionamiento

Definido en:

- `docker/grafana/provisioning/datasources/`
- `docker/grafana/provisioning/dashboards/`
- `docker/grafana/provisioning/dashboards/contenedores-dashboard.json`

### 8.3 Paneles esperados

- RAM Total.
- RAM Usada.
- RAM Libre.
- Uso de RAM en el tiempo.
- Contenedores eliminados en el tiempo.
- Top 5 por RAM.
- Top 5 por CPU.

## 9. Verificacion Tecnica

Ejecucion recomendada:

```bash
cd /home/carlos/Desktop/Proyecto2
sudo ./tests/verificar-requisitos.sh
```

Resultado:

- Reporte generado en `docs/evidencias/verificacion_YYYYMMDD_HHMMSS.txt`.
- Validaciones de modulo, daemon, cronjob, docker, valkey y restricciones.

## 10. Guia de Evidencias para Entrega

Se recomienda incluir al menos estas evidencias en el informe:

1. Compilacion de modulo kernel (`make clean && make` + `build/sonda.ko`).
2. Carga de modulo (`insmod`, `lsmod | grep sonda`).
3. Lectura de `/proc/continfo_pr2_so1_202300625` mostrando `[MEMORIA]` y `[PROCESOS]`.
4. Compilacion de daemon Go (`go build` + binario).
5. Cronjob instalado (`crontab -l`).
6. Contenedores activos (`docker ps` con `db_valkey` y `dashboard_grafana`).
7. Datos en Valkey (`HGETALL`, `ZREVRANGE`, `GET stats:containers_deleted`).
8. Dashboard Grafana con paneles funcionales.
9. Resumen de `tests/verificar-requisitos.sh` con porcentaje de cumplimiento.

Plantilla sugerida para tabla de evidencias:

| ID | Evidencia | Comando/Fuente | Resultado esperado |
|----|-----------|----------------|--------------------|
| E1 | Compilacion modulo | `make clean && make` | `sonda.ko` generado |
| E2 | Interfaz /proc | `head -40 /proc/continfo_pr2_so1_202300625` | Secciones y encabezado |
| E3 | Valkey activo | `valkey-cli PING` | `PONG` |
| E4 | Dashboard | Grafana Web | Paneles actualizados |

## 11. Troubleshooting

### 11.1 Error al cargar modulo kernel

Sintoma:

- `insmod: ERROR`.

Acciones:

1. Validar compilacion y existencia de `build/sonda.ko`.
2. Verificar version de headers (`/lib/modules/$(uname -r)/build`).
3. Revisar logs de kernel:

```bash
dmesg | tail -50
```

### 11.2 No existe archivo `/proc/continfo_pr2_so1_202300625`

Acciones:

1. Confirmar modulo cargado (`lsmod | grep sonda`).
2. Reintentar carga:

```bash
sudo rmmod sonda 2>/dev/null || true
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
```

### 11.3 Daemon no conecta a Valkey

Acciones:

1. Verificar contenedor:

```bash
sudo docker ps | grep db_valkey
```

2. Probar conectividad:

```bash
sudo docker exec db_valkey valkey-cli PING
```

3. Revisar puertos `6379` y configuracion de host/port.

### 11.4 Cronjob no ejecuta `generar.sh`

Acciones:

1. Verificar instalacion:

```bash
crontab -l
```

2. Ver permisos del script:

```bash
ls -l /home/carlos/Desktop/Proyecto2/docker/generar.sh
```

3. Revisar log:

```bash
tail -50 /var/log/proyecto2-contenedores.log
```

### 11.5 Grafana sin datos

Acciones:

1. Confirmar que daemon este ejecutandose.
2. Validar claves en Valkey (`metrics:*`).
3. Revisar provisionamiento del dashboard y datasource.
4. Refrescar paneles y rango de tiempo.

## 12. Operacion de Apagado y Mantenimiento

### 12.1 Finalizacion controlada

Al detener el daemon (SIGINT/SIGTERM), se ejecuta limpieza:

1. Desinstala cronjob (`cron/uninstall-cron.sh`).
2. Descarga modulo (`rmmod sonda`).
3. Baja servicios (`docker-compose down`).
4. Cierra conexion Valkey.

### 12.2 Comandos utiles de mantenimiento

```bash
# Eliminar cronjob manualmente
bash /home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh

# Descargar modulo
sudo rmmod sonda

# Detener infraestructura
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose down

# Levantar nuevamente infraestructura
sudo docker-compose up -d
```

## 13. Checklist de Cumplimiento (Rúbrica)

- [ ] Modulo kernel compila sin errores.
- [ ] Modulo se carga y descarga correctamente.
- [ ] Archivo `/proc` creado, legible y con formato correcto.
- [ ] Daemon Go compila y ejecuta.
- [ ] Daemon parsea `/proc` y almacena en Valkey.
- [ ] Cronjob de carga funcionando cada 2 minutos.
- [ ] Restricciones clave respetadas (3 bajo, 2 alto, no eliminar Grafana/Valkey).
- [ ] Grafana visualiza metricas solicitadas.
- [ ] Evidencias tecnicas almacenadas en `docs/evidencias`.

---

## 14. Referencias Internas

- `GUIA_DEMOSTRACION.md`
- `kernel-module/src/sonda.c`
- `kernel-module/Makefile`
- `daemon-go/cmd/daemon/main.go`
- `daemon-go/internal/orchestrator/orchestrator.go`
- `daemon-go/internal/analyzer/analyzer.go`
- `daemon-go/internal/parser/parser.go`
- `daemon-go/internal/storage/valkey.go`
- `daemon-go/internal/config/config.go`
- `docker/docker-compose.yml`
- `docker/generar.sh`
- `cron/install-cron.sh`
- `cron/uninstall-cron.sh`
- `tests/verificar-requisitos.sh`
