# 📊 GUÍA VISUAL: FLUJO DE EJECUCIÓN PROYECTO 2

## 🎯 Simplificado en 3 Niveles

### Nivel 1: ¿QUÉ HACE EL PROYECTO?

```
┌─────────────────────────────────────────────────────┐
│  MONITOREAR Y GESTIONAR CONTENEDORES AUTOMÁTICAMENTE │
│                                                      │
│  1. Lee procesos del kernel                         │
│  2. Analiza consumo (RAM, CPU)                      │
│  3. Decide qué eliminar                             │
│  4. Ejecuta eliminación                             │
│  5. Guarda datos para visualizar                    │
│  6. Muestra todo en dashboard                       │
└─────────────────────────────────────────────────────┘
```

---

## Nivel 2: ¿CÓMO FUNCIONA?

### Los 6 Pasos del Ciclo Principal

```
CADA 20-60 SEGUNDOS:

┌──────────────┐
│ 1️⃣  LECTURA   │  Lee: /proc/continfo_pr2_so1_202300625
├──────────────┤  Obtiene: PID, Memoria, CPU de cada proceso
│              │
├──────────────┐
│ 2️⃣  PARSEO    │  Convierte texto a estructura JSON
├──────────────┤  Agrupa: Datos globales + procesos[]
│              │
├──────────────┐
│ 3️⃣  ANÁLISIS  │  ¿Cuántos procesos hay?
├──────────────┤  ¿Cuánta memoria/CPU usan?
│              │  ¿Hay que eliminar algunos?
│
├──────────────┐
│ 4️⃣  ACCIÓN    │  docker kill {id}; docker rm {id}
├──────────────┤  Mantiene restricciones:
│              │  - Siempre 3 bajo consumo
│              │  - Siempre 2 alto consumo
│              │
├──────────────┐
│ 5️⃣  GUARDADO  │  Valkey almacena:
├──────────────┤  - Timestamp
│              │  - Memoria RAM total/usada/libre
│              │  - Cada contenedor (PID, RAM%, CPU%)
│              │  - Contador de eliminados
│              │
├──────────────┐
│ 6️⃣  LOGGING   │  Imprime resultados en logs
└──────────────┘  Muestra: cuántos eliminados, métricas
```

---

## Nivel 3: LA LÍNEA DE TIEMPO

```
MINUTO 0:00
├─ Usuario ejecuta: make run -C daemon-go
├─ Daemon inicia infraestructura
├─ Docker Compose levanta Grafana + Valkey
├─ Carga módulo kernel: insmod sonda.ko
├─ Instala cronjob en sistema
└─ Daemon LISTO ✓

MINUTO 0:00-0:30 (Ciclo Daemon #1)
├─ Lee /proc
├─ Parsea datos
├─ Analiza contenedores
├─ Guarda en Valkey
└─ Espera siguiente ciclo ⏳

MINUTO 0:30 (Grafana)
├─ Grafana lee de Valkey
├─ Actualiza dashboard
└─ Usuario VE datos actualizados ✓

MINUTO 1:00 (Ciclo Daemon #2)
├─ Lee, parsea, analiza
├─ Puede eliminar contenedores
└─ Guarda en Valkey

MINUTO 2:00 (Cronjob #1)
├─ Script cron/generar.sh ejecuta
├─ Crea 5 contenedores aleatorios
└─ Próximo ciclo daemon los detectará

MINUTO 2:00 (Ciclo Daemon #3)
├─ Lee procesos (incluye los 5 nuevos)
├─ Analiza (hay overlap)
├─ Decide: elimina algunos para mantener límites
└─ Guarda cambios en Valkey

[... Continúa indefinidamente ...]

MIENTRAS TANTO (EN PARALELO):
├─ Cronjob: Cada 2 minutos crea 5 más
├─ Daemon: Cada 20-60s analiza y ajusta
└─ Grafana: Cada 30s actualiza display
```

---

## 🔄 VISTA SIMPLIFICADA

### Lo que CADA componente hace:

```
┌──────────────────────────────────────────────────────────────┐

│ 🔧 KERNEL (sonda.c)
│ └─ Responsabilidad: LEER
│    ├─ Lee task_struct (procesos)
│    ├─ Lee sysinfo (memoria)
│    └─ Escribe en /proc/continfo_pr2_so1_202300625

│ 💼 DAEMON GO (main.go)
│ └─ Responsabilidad: PROCESAR + DECIDIR
│    ├─ Lee del kernel
│    ├─ Parsea datos
│    ├─ Analiza consumo
│    ├─ Toma decisiones (eliminar sí/no)
│    ├─ Ejecuta comando docker
│    └─ Guarda resultados en Valkey

│ ⏰ CRONJOB (cron/generar.sh)
│ └─ Responsabilidad: CREAR CARGA
│    ├─ Cada 2 minutos
│    ├─ Elige 5 tipos aleatorios
│    └─ Crea contenedores con docker run

│ 💾 VALKEY (Redis)
│ └─ Responsabilidad: ALMACENAR
│    ├─ Recibe datos del daemon
│    ├─ Persiste 24 horas automáticamente
│    └─ Comparte con Grafana

│ 📊 GRAFANA (Dashboard)
│ └─ Responsabilidad: VISUALIZAR
│    ├─ Lee de Valkey cada 30s
│    ├─ Ejecuta queries Redis
│    └─ Renderiza 8 paneles en HTML

│ 👤 USUARIO (Browser)
│ └─ Responsabilidad: OBSERVAR
│    ├─ Ve http://localhost:3000
│    ├─ Actualización en tiempo real
│    └─ Comprende qué ocurre en sistema

└──────────────────────────────────────────────────────────────┘
```

---

## ⏱️ FRECUENCIAS CLAVE

```
┌─────────────────────────────────────────────────┐
│ Kernel → Lee estructuras internas:              │
│ CONTINUO (siempre corriendo)                    │
│                                                  │
│ Daemon → Ciclo principal:                       │
│ CADA 20-60 SEGUNDOS                             │
│                                                  │
│ Cronjob → Crea contenedores:                    │
│ CADA 2 MINUTOS                                  │
│                                                  │
│ Grafana → Lee de Valkey:                        │
│ CADA 30 SEGUNDOS                                │
│                                                  │
│ Usuario → Ve dashboard:                         │
│ EN TIEMPO REAL (actualiza c/30s)                │
└─────────────────────────────────────────────────┘
```

---

## 🎬 ESCENARIO REAL: LO QUE OCURRE EN 10 MINUTOS

```
T=0:00 ┌─ Daemon inicia
       │  - Docker up
       │  - Kernel module loaded
       │  - Cronjob installed
       └─ Daemon ready ✓

T=0:20 ├─ [Daemon ciclo 1] Lee, parsea, guarda
T=0:30 ├─ [Grafana] Actualiza (1️⃣ dato)
T=0:40 ├─ [Daemon ciclo 2] Lee, parsea, guarda
T=1:00 ├─ [Daemon ciclo 3] Lee, parsea, guarda
T=1:00 ├─ [Grafana] Actualiza (2️⃣ dato)
T=1:20 ├─ [Daemon ciclo 4]
T=1:30 ├─ [Grafana] Actualiza (3️⃣ dato)
T=1:40 ├─ [Daemon ciclo 5]
T=2:00 ├─ [CRONJOB #1] Crea 5 contenedores 🆕
       ├─ [Daemon ciclo 6] Detecta nuevos
T=2:00 ├─ [Grafana] Actualiza (4️⃣ dato)
       ├─ Ver: +5 procesos en Top 5
T=2:20 ├─ [Daemon ciclo 7] Analiza, ELIMINA algunos ❌
T=2:30 ├─ [Grafana] Actualiza (5️⃣ dato)
       ├─ Ver: Contador de eliminados ++
T=3:00 ├─ [Grafana] Actualiza (6️⃣ dato)
T=4:00 ├─ [CRONJOB #2] Crea 5 MÁS 🆕
       ├─ [Daemon ciclo] Detecta + Analiza + Elimina
T=4:00 ├─ [Grafana] Actualiza (7️⃣ dato)
       ├─ Ver: Tendencias en gráficas
T=6:00 ├─ [CRONJOB #3] Crea 5 MÁS 🆕
T=8:00 ├─ [CRONJOB #4] Crea 5 MÁS 🆕
T=10:00├─ [CRONJOB #5] Crea 5 MÁS 🆕
       │
       └─ Dashboard muestra:
          - Gráfica de RAM (zigzag ascendente)
          - Top 5 en tiempo real
          - Contador de eliminados (incrementando)
          - Evolución en últimas 24h
```

---

## 🧠 CONCEPTO CLAVE: EQUILIBRIO DINÁMICO

```
El objetivo es MANTENER EQUILIBRIO CONSTANTE:

Cronjob agrega contenedores → RAM sube 📈
Daemon detecta exceso → Elimina algunos 🗑️
RAM baja → Equilibrio alcanzado ⚖️
Cronjob agrega MÁS → RAM sube 📈
Daemon actúa → Equilibrio de nuevo ⚖️

TODO OCURRE EN TIEMPO REAL:
┌────────────────────────────────────────┐
│ Usuario ve en Grafana:                 │
│ - RAM oscilando alrededor de un límite │
│ - Top 5 cambiando dinámicamente        │
│ - Contador incrementando gradualmente  │
│ - Gráficas subiendo y bajando          │
└────────────────────────────────────────┘
```

---

## 🚀 PARA ENTENDERLO MEJOR

### 1. Lee FLUJO_EJECUCION.md
Explicación detallada con diagramas

### 2. Ejecuta el sistema
```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
make run
```

### 3. Abre Grafana
http://localhost:3000 (admin/admin)

### 4. Observa en TIEMPO REAL
- Dashboard se actualiza cada 30s
- Cronjob crea contenedores cada 2 min
- Daemon actúa cada 20-60s
- TODO ocurre simultáneamente

---

## ✨ RESUMEN EN UNA FRASE

```
Kernel provee datos → Daemon analiza → Valkey guarda → 
Grafana visualiza → Usuario ve todo en tiempo real
```

---

**Proyecto 2 - SO1 - Carnet: 202300625**
**Guía Visual Simplificada**
