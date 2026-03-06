# Arquitectura Fase 3

## Flujo de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                     FASE 3: CONTENEDORES                     │
└─────────────────────────────────────────────────────────────┘

                       ┌─────────────────┐
                       │   CRONJOB       │
                       │ (cada 2 min)    │
                       └────────┬────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │  generar.sh Script     │
                    │ Crea 5 contenedores    │
                    │   (aleatorio)          │
                    └──────┬─────┬───┬───┬───┘
                           │     │   │   │
            ┌──────────────┴─┐   │   │   │
            │                │   │   │   │
            ▼                ▼   ▼   ▼   ▼
       ┌─────────┐  ┌────────────┐  ┌────────┐
       │go-client│  │Alpine (CPU)│  │Alpine  │
       │ RAM     │  │ CPU Loop   │  │(Sleep) │
       │ High    │  │ High       │  │Low     │
       │ Consume │  │ Consume    │  │Consume │
       └──────┬──┘  └─────┬──────┘  └──┬─────┘
              │           │            │
              └───────────┼────────────┘
                          │
                          ▼
              ┌──────────────────────┐
              │   Docker Bridge      │
              │   Network            │
              └────────┬─────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
    ┌────────┐  ┌──────────┐  ┌──────────┐
    │ Valkey │  │ Grafana  │  │  Kernel  │
    │ DB     │  │ Dashboard│  │  Module  │
    │ 6379   │  │ 3000     │  │  /proc   │
    └────────┘  └──────────┘  └──────────┘
```

## Timeline de Ejecución

```
Minuto 0:  ===============================================
           Cronjob dispara generar.sh
           └─> Crea 5 contenedores (mix random)
           └─> 1-2 segundos

Minuto 2:  ===============================================
           Cronjob dispara de nuevo
           └─> Crea 5 nuevos contenedores
           └─> (Si Daemon GO está corriendo, puede eliminar algunos)

Minuto 4:  ===============================================
           Cronjob dispara de nuevo
           └─> Crea 5 nuevos contenedores
           ...

```

## Estructura de Archivos

```
Proyecto2/
│
├── docker/                               # Componentes Docker
│   ├── high-memory/
│   │   └── Dockerfile                   # go-client RAM alta
│   ├── high-cpu/
│   │   └── Dockerfile                   # Alpine CPU alta
│   ├── low-consumption/
│   │   └── Dockerfile                   # Alpine bajo consumo
│   ├── generar.sh                       # 🔑 Script principal
│   ├── docekr-compose.yml               # Compose (Valkey + Grafana)
│   ├── grafana/                         # Config de Grafana
│   │   ├── dashboards/
│   │   └── provisioning/
│   └── valkey/
│       └── main.go
│
├── cron/                                # Control de Cronjob
│   ├── install-cron.sh                  # 🔑 Instalar cronjob
│   └── uninstall-cron.sh                # Desinstalar cronjob
│
├── scripts/                             # Utilidades
│   ├── check-fase3.sh                   # Verificar estado
│   ├── fase3-quickstart.sh              # Setup automático
│   └── ...
│
└── docs/
    └── FASE3_README.md                  # 📖 Documentación
```

## Flujo de Instalación

```
┌─ START ─────────────────┐
│                         │
│  1. Ver requirements    │
│     (docker, compose)   │
│         │               │
│         ▼               │
│  2. Iniciar servicios   │
│     (Valkey + Grafana)  │
│         │               │
│         ▼               │
│  3. Instalar cronjob    │
│     (cada 2 minutos)    │
│         │               │
│         ▼               │
│  4. Verificar todo      │
│         │               │
│         ▼               │
│  5. Monitorear logs     │
│         │               │
│         ▼               │
│  RUNNING ───────────►  │
│         │               │
│         ▼               │
│  Cada 2 min:            │
│  - Crea 5 contenedores  │
│  - Logs en /var/log/    │
│         │               │
└────────────────────────┘
```

## Tipos de Consumo

```
MEMORIA:           CPU:               TIPO:
┌──────┐          ┌──────┐          ┌────────┐
│ RAM  │          │ CPU  │          │ TIMING │
│ High ├─►        │ Low  │          │        │
│      │          │      │          │ Bajo   │
└──────┘          └──────┘          └────────┘
     go-client           alpine (sleep)

┌──────┐          ┌──────┐          ┌────────┐
│ RAM  │          │ CPU  │          │ TIMING │
│ Low  ├─►        │ High │          │        │
│      │          │      │          │ 2 loop │
└──────┘          └──────┘          └────────┘
     alpine              alpine (bc loop)

┌──────┐          ┌──────┐          ┌────────┐
│ RAM  │          │ CPU  │          │ TIMING │
│ Low  ├─►        │ Low  │          │        │
│      │          │      │          │ 240s   │
└──────┘          └──────┘          └────────┘
     alpine              alpine (sleep 240)
```

## Secuencia Cronológica Esperada

```
00:00 - Cronjob #1: Genera 5 contenedores
        C1 (RAM), C2 (CPU), C3 (Low), C4 (RAM), C5 (CPU)
        └─ Log: "Contenedores creados: 5"

02:00 - Cronjob #2: Genera 5 nuevos contenedores
        C6 (Low), C7 (CPU), C8 (RAM), C9 (Low), C10 (CPU)
        └─ Log: "Contenedores creados: 5"
        Total en sistema: 10 contenedores

04:00 - Cronjob #3: Genera 5 nuevos contenedores
        C11 (RAM), C12 (Low), C13 (CPU), C14 (RAM), C15 (Low)
        └─ Log: "Contenedores creados: 5"
        Total en sistema: 15 contenedores
        
        ⚠  Si Daemon GO estuviera ejecutándose:
           - Analizaría consumo total
           - Eliminaría contenedores que excedan límites
           - Mantendría restricciones: 3 Low + 2 RAM/CPU

...
```

## Estado del Sistema

```
ANTES DE FASE 3:          DESPUÉS DE FASE 3:
┌─────────────────┐       ┌─────────────────┐
│ - Kernel Module │       │ ✓ Kernel Module │
│ - Daemon GO (?) │       │ ✓ Daemon GO (?) │
│ - Sin Docker    │       │ ✓ Valkey        │
│ - Sin Grafana   │       │ ✓ Grafana       │
│ - Sin cronjob   │       │ ✓ Cronjob ✓     │
│ - Sin contenedores       │ ✓ Contenedores  │
│   dinámicos     │       │   dinámicos     │
└─────────────────┘       └─────────────────┘
```

## Próximos Pasos (Fase 4)

El Daemon en GO necesitará:

```
┌──────────────────────────┐
│    DAEMON GO (Fase 4)    │
├──────────────────────────┤
│ 1. Lee /proc/continfo... │ ◄─ Escribido por Kernel (Fase 2)
│ 2. Parsea datos          │
│ 3. Conecta a Valkey      │ ◄── Base de datos (iniciado)
│ 4. Almacena métricas     │
│ 5. Analiza consumo       │
│ 6. Toma decisiones       │
│ 7. Elimina contenedores  │ ◄── Creados por cronjob (Fase 3)
│    (respetando límites)  │
└──────────────────────────┘
```
