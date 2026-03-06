# 📊 FLUJO DE EJECUCIÓN: PROYECTO 2 SO1

## 🎯 Visión General del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PROYECTO 2: SISTEMA COMPLETO                   │
│                                                                      │
│   FASE 2: Módulo Kernel  →  FASE 3: Cronjob  →  FASE 4: Daemon  →  │
│   FASE 5: Grafana Dashboard                                          │
│                                                                      │
│   Objetivo: Monitorizar y gestionar automáticamente contenedores     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## ⏱️ LÍNEA DE TIEMPO DE EJECUCIÓN

### Paso 0: Pre-requisitos (Manual)
```
1. Compilar módulo kernel (Fase 2): make -C kernel-module
2. Iniciar Docker Compose: docker-compose up -d
3. Ejecutar daemon: make run -C daemon-go (con sudo)
```

### Paso 1: Al Iniciar el Daemon (Initialize)

```
DAEMON INICIA
    ↓
[1] Inicia Docker Compose & Grafana + Valkey
    ├─ Espera a que Valkey esté listo
    └─ Cria contenedor de Grafana
    ↓
[2] Carga módulo kernel: insmod sonda.ko
    └─ Crea archivo: /proc/continfo_pr2_so1_202300625
    ↓
[3] Instala Cronjob cada 2 minutos
    └─ Script: cron/generar.sh
    ↓
[4] Valida conexión a Valkey
    └─ Envía PING y espera respuesta PONG
    ↓
DAEMON LISTO PARA CICLO PRINCIPAL
```

### Paso 2: Loop Principal (Cada 20-60 segundos)

```
INICIO DE CICLO (cada 20-60 segundos)
    ↓
┌─────────────────────────────────────────────────────────┐
│         CICLO PRINCIPAL DEL DAEMON                      │
└─────────────────────────────────────────────────────────┘
    ↓
[A] LECTURA (kernel → /proc)
    ├─ Lee: /proc/continfo_pr2_so1_202300625
    ├─ Obtiene: PID, nombre, VSZ, RSS, CPU, RAM%
    └─ Gestiona: contenedores activos del sistema
    ↓
[B] PARSEO (daemon-go → parser)
    ├─ Deserializa contenido del archivo
    ├─ Crea estructura CapturaTelemetria
    ├─ Ordena por RAM, CPU, VSZ, RSS
    └─ Genera timestamp
    ↓
[C] ANÁLISIS (daemon-go → analyzer)
    ├─ Detecta contenedores de alto/bajo consumo
    ├─ Verifica restricciones:
    │  ├─ Siempre 3 de bajo consumo
    │  ├─ Siempre 2 de alto consumo
    │  └─ Nunca eliminar Grafana
    ├─ Decide cuáles eliminar
    └─ Calcula métricas de salud
    ↓
[D] ACCIÓN (docker → eliminar contenedores)
    ├─ docker kill {container_id}
    ├─ docker rm {container_id}
    └─ Incrementa contador de eliminados
    ↓
[E] ALMACENAMIENTO (daemon-go → Valkey)
    ├─ Guarda: metric:memory:{timestamp}
    ├─ Guarda: metric:container:{timestamp}:{pid}
    ├─ Guarda: stats:containers_deleted
    └─ TTL: 24 horas
    ↓
[F] LOGGING (daemon-go → logger)
    ├─ Escribe: Contenedores eliminados
    ├─ Escribe: Métricas actuales
    └─ Escribe: Decisiones tomadas
    ↓
FIN DE CICLO
    ↓
    └─→ [Espera 20-60 segundos] → INICIO DE CICLO
```

### Paso 3: Cronjob Paralelo (Cada 2 minutos)

```
CRONJOB EJECUTA (cada 2 minutos)
    ↓
Script: cron/generar.sh
    ├─ Elige 5 contenedores aleatorios
    ├─ Tipos:
    │  ├─ Alto RAM (go-client)
    │  ├─ Alto CPU (alpine con while true)
    │  └─ Bajo consumo (alpine sleep 240)
    └─ docker run -d [imagen]
    ↓
CONTENEDORES SE CREAN
    ↓
Daemon detecta en siguiente ciclo
    ↓
CICLO PRINCIPAL ACTÚA
```

### Paso 4: Visualización en Grafana (Cada 30 segundos)

```
GRAFANA CONSULTA (cada 30 segundos)
    ↓
Redis Datasource
    ├─ Lee: metric:memory:*
    ├─ Lee: metric:container:*
    └─ Lee: stats:containers_deleted
    ↓
DASHBOARD SE ACTUALIZA
    ├─ Tarjetas: RAM Total, Usada, Libre, Eliminados
    ├─ Gráficas: Evolución temporal (últimas 24h)
    └─ Pastel: Top 5 contenedores
    ↓
USUARIO VE DATOS EN TIEMPO REAL
```

---

## 🔄 FLUJO DE DATOS COMPLETO

```
KERNEL (Bajo Nivel)
    │
    ├─ Lee memory / task_struct
    ├─ Calcula: PID, Memoria, CPU
    │
    ╰──→ /proc/continfo_pr2_so1_202300625 (Archivo de texto)
            │
            ├─ [Global Memory]
            │  Total RAM: 16384 MB
            │  Libre RAM: 8192 MB
            │  En Uso RAM: 8192 MB
            │
            ├─ [Procesos]
            │  PID=12345 Nombre=nginx VSZ=204800 RSS=102400 ...
            │  PID=12346 Nombre=postgres VSZ=512000 RSS=256000 ...
            │  ... (más procesos)
            │
            ╰──→ DAEMON GO (Lectura)
                    │
                    ├─ ParseProcFile()
                    ├─ Deserializa JSON
                    │
                    ╰──→ PARSER
                            │
                            ├─ CapturaTelemetria {
                            │   - Timestamp
                            │   - MemoriaGlobal
                            │   - Procesos[]
                            │  }
                            │
                            ╰──→ ANALYZER
                                    │
                                    ├─ Análisis de consumo
                                    ├─ Decisión: ¿Eliminar?
                                    │
                                    ├─ SI: docker rm {id}
                                    │
                                    ╰──→ STORAGE (Valkey)
                                            │
                                            ├─ metric:memory:1709842800000
                                            │  {total: 16384, used: 8192, ...}
                                            │
                                            ├─ metric:container:{ts}:{pid}
                                            │  {pid: 12345, nombre: "nginx", ...}
                                            │
                                            ├─ stats:containers_deleted = 5
                                            │
                                            ├─ telemetry:{ts}
                                            │  {timestamp, memoria, procesos}
                                            │
                                            ╰──→ GRAFANA (Lectura c/30s)
                                                    │
                                                    ├─ Datasource Redis
                                                    ├─ Ejecuta queries
                                                    │
                                                    ╰──→ DASHBOARD
                                                            │
                                                            ├─ Tarjetas (Gauges)
                                                            ├─ Gráficas (Series)
                                                            ├─ Pastel (Top 5)
                                                            │
                                                            ╰──→ USUARIO (Web Browser)
                                                                    http://localhost:3000
```

---

## 🎯 COMPONENTES Y SUS RESPONSABILIDADES

### 1. **Módulo Kernel (sonda.c)** - FASE 2
**Dónde**: `/kernel-module/src/sonda.c`
**Qué hace**:
- Lee estructuras del kernel: `task_struct`, `sysinfo`
- Calcula memoria: Total, Libre, Usado
- Itera procesos: PID, VSZ, RSS, Porcentaje
- Escribe en `/proc/continfo_pr2_so1_202300625`

**Cuándo**: Cada vez que se ejecuta `cat /proc/continfo_pr2_so1_202300625`

**Salida**: Archivo texto estructurado con info global + procesos

```
--- Informacion Global ---
Total RAM: 16384 MB
Libre RAM: 8192 MB
En Uso RAM: 8192 MB
--------------------------
--- Lista de Procesos ---
PID=12345 Cmd=nginx VSZ=204800 RSS=102400 ...
PID=12346 Cmd=postgres VSZ=512000 RSS=256000 ...
```

---

### 2. **Cronjob Script (generar.sh)** - FASE 3
**Dónde**: `/cron/install-cron.sh` - Instala `/cron/generar.sh`
**Qué hace**:
- Elige 5 contenedores aleatorios
- Selecciona imágenes: roldyoran/go-client (RAM), alpine (CPU), alpine (sleep)
- Ejecuta: `docker run -d [imagen]`

**Cuándo**: Cada 2 minutos (por cronjob)

**Efecto**: Crea contenedores para simular carga variable

---

### 3. **Daemon Go (main.go)** - FASE 4
**Dónde**: `/daemon-go/cmd/daemon/main.go`

#### 3.1 Inicialización (Initialize)
```
1. StartInfrastructure()
   ├─ docker-compose up -d (Grafana + Valkey)
   └─ Espera puerto 3000 + 6379

2. LoadKernelModule()
   ├─ insmod sonda.ko
   └─ Crea /proc/continfo_pr2_so1_202300625

3. InstallCronjob()
   ├─ Ejecuta: bash cron/install-cron.sh
   └─ Configura en crontab

4. Valkey Ping
   ├─ Envía PING
   └─ Espera PONG
```

#### 3.2 Loop Principal (Run) - Cada 20-60 segundos
```
CICLO INFINITO (hasta recibir SIGINT/SIGTERM)

A. LEER /proc (Parser)
   parsedData := ParseProcFile("/proc/continfo_pr2_so1_202300625")
   
B. ANALIZAR (Analyzer)
   decisions := AnalyzeAndDecide(parsedData)
   
C. EJECUTAR DECISIONES (Docker CLI)
   for _, container := range decisions.ToDelete {
       docker.Kill(container.ID)
       docker.Remove(container.ID)
   }
   
D. GUARDAR EN VALKEY (Storage)
   valkey.StoreTelemetry(parsedData)
   valkey.StoreContainerMetric(...)
   valkey.IncrementContainersDeleted(count)
   
E. LOGGING (Logger)
   log.Info("Ciclo completado", "containers_deleted", count)
   
F. DORMIR (Sleep)
   time.Sleep(config.CycleDuration)
   
[REPETIR]
```

#### 3.3 Limpieza (Cleanup)
```
1. Uninstall Cronjob
   crontab -r (o elimina línea específica)

2. Unload Kernel Module
   rmmod sonda

3. Close Valkey Connection
   valkey.Close()

4. Close Logger
   logger.Close()
```

---

### 4. **Grafana Dashboard** - FASE 5
**Dónde**: `/docker/grafana/provisioning/dashboards/contenedores-dashboard.json`
**Qué hace**:
- Provisiona datasource Redis automáticamente
- Crea dashboard con 8 paneles
- Existe queries a Valkey

**Actualización**: Cada 30 segundos automáticamente

**Visualizaciones**:
```
Fila 1: Indicadores (Gauges)
├─ RAM Total
├─ RAM Usada
├─ RAM Libre
└─ Contenedores Eliminados

Fila 2: Series Temporales
├─ Evolución RAM (últimas 24h)
└─ Contenedores Eliminados (barras)

Fila 3: Comparativas
├─ Top 5 por RAM (Pie Chart)
└─ Top 5 por CPU (Pie Chart)
```

---

## 🔄 CICLO DE VIDA COMPLETO

### Minuto 0
```
Usuario ejecuta: make run -C daemon-go
    ↓
├─ INITIALIZE
│  ├─ Docker Compose up (Grafana + Valkey)
│  ├─ insmod sonda.ko
│  ├─ Cronjob install
│  └─ Valkey ping test
│
├─ DAEMON LISTO
│  └─ Awaiting commands...
```

### Minuto 0-2 (Primer ciclo del daemon)
```
CICLO 1
├─ Lee /proc
├─ Parse datos
├─ Análisis (sin datos históricos aún)
├─ Guarda en Valkey
└─ Sleep 20-60s
```

### Minuto 2 (Cronjob #1)
```
CRONJOB
├─ Elige 5 contenedores aleatorios
├─ docker run tipo1, tipo2, tipo3, tipo4, tipo5
└─ Contenedores CREADOS
    ↓
    └─ Visible en siguiente ciclo del daemon
```

### Minuto 2-4 (Ciclo 2 del daemon)
```
CICLO 2
├─ Lee /proc (contadores incluyen nuevos)
├─ Parse
├─ Analiza: "Hay más de lo permitido"
├─ Decide: Eliminar algunos
├─ docker kill + docker rm
├─ Incrementa contador
├─ Guarda en Valkey
└─ Grafana verá actualización en 30s
```

### Minuto 4 (Cronjob #2)
```
CRONJOB
└─ Crea 5 MÁS contenedores
    ↓
    └─ Daemon verá en siguiente ciclo
```

### Minuto 5 (User abre Grafana)
```
User: http://localhost:3000
    ↓
Grafana Dashboard
    ├─ Muestra RAM (desde Valkey)
    ├─ Muestra Top 5 (desde Valkey)
    ├─ Muestra Eliminados (contador)
    └─ TODO EN TIEMPO REAL
```

### ...continúa...
```
Cada 2 min: Cronjob crea contenedores
Cada 20-60s: Daemon analiza y decide
Cada 30s: Grafana actualiza display
    ↓
Simula CARGA VARIABLE CONTINUA
```

### Al finalizar (Ctrl+C en terminal del Daemon)
```
CLEANUP
├─ Crontab remove
├─ rmmod sonda.ko
├─ Valkey close
├─ Logger close
└─ DAEMON TERMINA
```

---

## 📊 DIAGRAMA DE ESTADOS

```
    [PARADO]
        │
        ├─ make run -C daemon-go
        │
        ▼
    [INICIALIZANDO]
        │
        ├─ Docker Compose ✓
        ├─ Kernel Module ✓
        ├─ Cronjob ✓
        ├─ Valkey Ping ✓
        │
        ▼
    [LISTO - Esperando...]
        │
        ├─ Espera 20-60 segundos
        │
        ▼
    [LEYENDO /proc]
        │
        ├─ ParseProcFile()
        │
        ▼
    [ANALIZANDO]
        │
        ├─ AnalyzeAndDecide()
        ├─ Calcula qué eliminar
        │
        ▼
    [EJECUTANDO]
        │
        ├─ docker rm [ids]
        ├─ IncrementCounter()
        │
        ▼
    [GUARDANDO]
        │
        ├─ Valkey StoreTelemetry()
        ├─ Valkey StoreMetrics()
        │
        ▼
    [LOGGING]
        │
        ├─ Log resultados
        │
        ▼
    [DURMIENDO]
        │
        ├─ time.Sleep(20-60s)
        │
        ├─ [CRONJOB PARALELO cada 2min]
        │ │  ├─ Crea contenedores
        │ │  └─ Vuelve a esperar
        │ │
        │ └─ [GRAFANA paralelo cada 30s]
        │    ├─ Lee de Valkey
        │    ├─ Actualiza dashboard
        │    └─ Vuelve a esperar
        │
        └──→ Vuelve a [LISTO - Esperando]
             (Loop infinito)
    
    [Ctrl+C RECIBIDO]
        │
        ├─ Crontab uninstall
        ├─ rmmod sonda.ko
        ├─ Valkey close
        │
        ▼
    [TERMINADO]
```

---

## 🔗 COMUNICACIÓN ENTRE COMPONENTES

```
┌───────────────┐
│   KERNEL      │
│ (sonda.c)     │ **Escribe**
└───────────────┘
        │
        ├─ /proc/continfo_pr2_so1_202300625
        │
        ▼
┌───────────────────┐
│   DAEMON GO       │ **Lee + Parsea**
│ (main.go)         │
└───────────────────┘
        │
        ├─ PARSER ──→ (Estructura)
        ├─ ANALYZER ──→ (Decisiones)
        ├─ DOCKER CLI ──→ (Elimina)
        │
        ▼
┌───────────────────┐
│   VALKEY/REDIS    │ **Almacena**
│ (6379)            │
└───────────────────┘
        │
        ├─ metric:memory:*
        ├─ metric:container:*
        ├─ stats:containers_deleted
        │
        ▼
┌───────────────────┐
│   GRAFANA         │ **Lee + Visualiza**
│ (3000)            │
└───────────────────┘
        │
        ├─ Dashboard provisioned
        ├─ Datasource Redis
        ├─ Queries automáticas
        │
        ▼
    [USUARIO - Web Browser]
```

---

## ⚡ FLUJOS PARALELOS

```
DAEMON (Principal)
├─ Ciclo principal (cada 20-60s)
│  ├─ Lectura
│  ├─ Análisis
│  ├─ Acción
│  └─ Almacenamiento

CRONJOB (Paralelo - Sistema OS)
├─ Ejecución cada 2 minutos
└─ Crea contenedores

GRAFANA (Paralelo - Docker Container)
├─ Actualización cada 30 segundos
├─ Lee de Valkey
└─ Actualiza visualizaciones
```

**Todo ocurre simultáneamente.**

---

## 📝 RESUMEN EN UNA LÍNEA

```
Kernel lee procesos → Daemon parsea/analiza/decide → Valkey almacena → 
Grafana visualiza → Usuario ve todo en tiempo real
```

**Cada componente hace su trabajo, y los datos fluyen de arriba a abajo continua­mente.**

---

**Proyecto 2 - SO1 - Carnet: 202300625**
**Flujo de Ejecución Completo**
