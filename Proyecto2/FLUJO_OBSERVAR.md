# 🎬 CÓMO VER EL FLUJO EN ACCIÓN

## 📋 Requisitos

- ✅ Virtual Machine Linux
- ✅ Docker instalado
- ✅ Docker Compose
- ✅ Módulo kernel compilado
- ✅ Daemon GO compilado
- ✅ Terminal y navegador

---

## 🚀 Paso 1: Iniciar el Sistema

### Opción A: Con Script Automatizado (Recomendado)

```bash
cd /home/carlos/Desktop/Proyecto2/docker
docker-compose up -d
```

Espera 30 segundos a que Grafana y Valkey estén listos.

### Opción B: Manual

```bash
# Terminal 1: Docker Compose
cd /home/carlos/Desktop/Proyecto2/docker
docker-compose up -d
# Espera mensajes: "✓ Valkey listo" y "✓ Grafana listo"

# Terminal 2: Daemon
cd /home/carlos/Desktop/Proyecto2/daemon-go
sudo make run
# Deberías ver:
# ╔═════════════════════════════════════════╗
# ║  DAEMON GESTOR DE CONTENEDORES - FASE 4  ║
# ║  Carnet: 202300625                       ║
# ║  Versión: 1.0.0                         ║
# ╚═════════════════════════════════════════╝
```

---

## 🖥️ Paso 2: Abrir Grafana

En tu navegador, ve a:
```
http://localhost:3000
```

Credenciales:
- Usuario: `admin`
- Contraseña: `admin`

---

## 👀 Paso 3: VER EL FLUJO EN ACCIÓN

### Lo que verás en Grafana:

**En tiempo real (cada 30 segundos se actualiza):**

1. **Tarjetas (superior)**
   - RAM Total: Número fijo
   - RAM Usada: Cambia según carga
   - RAM Libre: Inverso de usada
   - Contenedores Eliminados: Incrementa

2. **Gráfica de línea (centro)**
   - RAM Usada a lo largo del tiempo
   - Verás un patrón zigzag:
     ```
                    ╱╲╱╲╱╲╱╲╱
     RAM Sube → Daemon actúa → Baja → Cronjob añade
     ```

3. **Gráficos de pastel (inferior)**
   - Top 5 contenedores cambian dinámicamente
   - PIDs y nombres varían

---

### Lo que verás en Terminal (Daemon):

Verás logs como:

```
╔═════════════════════════════════════════╗
║  DAEMON GESTOR DE CONTENEDORES         ║
╚═════════════════════════════════════════╝

[INFO] Conectando a Valkey...
[INFO] ✓ Conexión a Valkey establecida
[INFO] === INICIALIZANDO DAEMON ===
[INFO] Carnet: 202300625

[INFO] === INICIANDO LOOP PRINCIPAL ===

[INFO] Ciclo 1 completado
├─ Procesos detectados: 45
├─ RAM Usada: 8192 MB
├─ Top Consumidor: nginx (2048 MB)
└─ Acción: Sin cambios (está dentro de límites)

[INFO] Ciclo 2 completado (t=30s)
├─ Procesos detectados: 50
├─ RAM Usada: 9216 MB
├─ Contenedores nuevos: +5 (from cronjob)
└─ Acción: Eliminó 2 contenedores

[INFO] Ciclo 3 completado (t=60s)
├─ Procesos detectados: 48
├─ RAM Usada: 8500 MB
└─ Acción: Sin cambios

[INFO] Contenedores eliminados hoy: 2
[INFO] Almacenado en Valkey: metric:container:*
```

---

## 🔍 Paso 4: OBSERVAR PATRONES

### Cada 2 minutos (Cronjob)
```
Terminal mostrará:
├─ Procesos detectados: ↑↑↑ (suben a 50+)
├─ RAM Usada: ↑↑↑
└─ Acción: Eliminó N contenedores
```

### Cada 30 segundos (Grafana)
```
Dashboard verá:
├─ RAM Usada actualiza
├─ Spike en gráfica
├─ Top 5 cambia
└─ Contador incrementa
```

---

## 📊 INTERPRETACIÓN DE DATOS

### Gráfica de RAM

```
Si ves esto:        Significa:
─────────────────────────────────────
Línea plana         Sin contenedores nuevos
Sube gradualmente   Cronjob agregando
Baja rápido         Daemon eliminando
Zigzag constante    Sistema en equilibrio dinámico
```

### Contador de Eliminados

```
Si incrementa constantemente:
└─ Daemon está funcionando
   ├─ Detecta exceso
   ├─ Toma decisiones
   └─ Elimina según reglas

Si se queda en 0:
└─ Puede ser normal
   ├─ Contenedores dentro de límites
   └─ No hay nada que eliminar
```

### Top 5 Contenedores

```
Si ve cambios:
└─ Daemon está leyendo datos nuevos
   ├─ Cada ciclo es diferente
   ├─ Procesos se crean/eliminan
   └─ Datos fluyen correctamente
```

---

## 🐛 DEBUGGING EN VIVO

### Terminal 1: Ver logs del daemon en tiempo real
```bash
# Terminal ya debe tener output del daemon
# Si necesitas limpiar:
clear

# Para ver solo esos logs:
sudo make run -C /home/carlos/Desktop/Proyecto2/daemon-go 2>&1 | tee daemon.log
```

### Terminal 2: Ver datos en Valkey
```bash
docker exec db_valkey valkey-cli

# En la shell de valkey-cli:
KEYS *                           # Ver todas las claves
KEYS "metric:*"                  # Solo métricas
GET metric:memory:*              # Última métrica de memoria
DBSIZE                           # Total de datos
FLUSHDB                          # Limpiar (CUIDADO)
```

### Terminal 3: Ver contenedores en vivo
```bash
watch -n 1 "docker ps -a | grep -E 'alpine|go-client|grafana'"
# Se actualiza cada segundo
# Verás contenedores aparecer y desaparecer
```

---

## ⏱️ LÍNEA DE TIEMPO DE OBSERVACIÓN

### Primeros 5 minutos

```
T=0:00
├─ Daemon inicia
├─ Docker Compose arranca
└─ Daemon ready ✓

T=0:30
├─ Abre Grafana en navegador
├─ Dashboard está VACÍO (sin datos aún)
└─ Espera siguiente actualización

T=1:00
├─ Grafana actualiza 🔄
├─ Verás primera tarjeta con "RAM Total"
├─ Gráfica tiene primer punto
└─ Top 5 muestra primeros contenedores

T=2:00
├─ 🎯 CRONJOB #1 Ejecuta
├─ Crea 5 nuevos contenedores
└─ Terminal muestra: "Procesos detectados: ↑↑↑"

T=2:30
├─ Daemon analiza los 5 nuevos
├─ Decide eliminar algunos
├─ Terminal muestra: "Acción: Eliminó N contenedores"
└─ Grafana actualiza 🔄

T=3:00
├─ Grafana actualiza
├─ Ves patrón zigzag en gráfica
├─ Contador incrementó
└─ Top 5 cambió

T=4:00
├─ 🎯 CRONJOB #2 Ejecuta
├─ + 5 contenedores más
└─ Patrón se repite

T=5:00
├─ Sistema en ritmo
├─ Puedes ver el flujo claramente
└─ Buen momento para tomar screenshot
```

---

## 📸 QUÉ SCREENSHOT TOMAR

Para evidencia funcional, toma captures de:

### 1. Terminal del Daemon
```
Mostrar:
├─ Inicialización ✓
├─ Logs de ciclos
├─ "Procesos detectados"
├─ "Acción: Eliminó N"
└─ Timestamps
```

### 2. Grafana Dashboard
```
Mostrar:
├─ Tarjetas con valores
├─ Gráfica zigzag
├─ Top 5 contenedores
├─ Contador incrementado
└─ URL: http://localhost:3000 visible
```

### 3. Docker ps (Contadores)
```bash
docker ps -a | wc -l
# Muestra cuántos contenedores hay
```

### 4. Valkey datos
```bash
docker exec db_valkey valkey-cli DBSIZE
# Muestra cuántos datos hay guardados
```

---

## ✨ PUNTOS CLAVE A OBSERVAR

✅ **Validación de que funciona:**
1. ¿Grafana se actualiza cada 30s? SI ✓
2. ¿Los números cambian? SI ✓
3. ¿Hay sincronización con cronjob (t=2,4,6 min)? SI ✓
4. ¿El contador incrementa? SI ✓
5. ¿Top 5 varía dinámicamente? SI ✓

---

## 🛑 PARAR EL SISTEMA

### Cuando quieras detener:

```bash
# En terminal del daemon
Ctrl+C

# El daemon ejecutará:
# - Remove cronjob ✓
# - rmmod sonda.ko ✓
# - Close Valkey ✓
# - Finalizado ✓

# En otra terminal
cd /home/carlos/Desktop/Proyecto2/docker
docker-compose down
```

---

## 📝 RESUMEN DEL FLUJO VISIBLE

```
┌─────────────────────────────────────────────────┐
│         LO QUE VERÁS EN ACCIÓN                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ Terminal (Daemon):                              │
│ ├─ "Ciclo N completado"                        │
│ ├─ "Procesos detectados: 45"                   │
│ ├─ "Acción: Eliminó 2 contenedores"            │
│ └─ Cada 20-60 segundos                         │
│                                                  │
│ Grafana (Dashboard):                            │
│ ├─ Tarjetas actualizadas                       │
│ ├─ Gráfica con patrón zigzag                   │
│ ├─ Top 5 cambiando                             │
│ └─ Cada 30 segundos                            │
│                                                  │
│ Cronjob (Background):                           │
│ ├─ Crea 5 contenedores                         │
│ └─ Cada 2 minutos (invisible)                  │
│                                                  │
│ RESULTADO: Sistema autónomo funcionando        │
│            en tiempo real                      │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## 🎓 APRENDIZAJE

Cuando ves esto en acción, entiendes:

1. **Kernel Module**: Lee información del sistema
2. **Daemon**: Procesa y toma decisiones
3. **Docker**: Ejecuta comandos según decisiones
4. **Valkey**: Persiste datos para histórico
5. **Grafana**: Visualiza lo que el daemon hace
6. **Sistema Autónomo**: Todo ocurre sin intervención

---

**Proyecto 2 - SO1 - Carnet: 202300625**
**Cómo Observar el Flujo en Tiempo Real**
