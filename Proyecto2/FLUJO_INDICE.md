# 📚 ÍNDICE: ENTENDER EL FLUJO DE EJECUCIÓN

## 🎯 Elige Tu Camino de Aprendizaje

### 👤 "Soy principiante - Quiero empezar simple"
**Tiempo: 5 minutos**

1. Lee: [FLUJO_SIMPLIFICADO.md](FLUJO_SIMPLIFICADO.md)
   - 3 niveles de complejidad
   - Diagramas del ciclo
   - Línea de tiempo de 10 minutos

2. Luego ejecuta: `make run -C daemon-go`

3. Abre: http://localhost:3000 (admin/admin)

---

### 🎓 "Quiero entender todo bien"
**Tiempo: 20 minutos**

1. Lee: [FLUJO_SIMPLIFICADO.md](FLUJO_SIMPLIFICADO.md) (conceptos)
2. Lee: [FLUJO_EJECUCION.md](FLUJO_EJECUCION.md) (detalles completos)
3. Ver: Diagramas Mermaid incluidos
4. Ejecuta: [FLUJO_OBSERVAR.md](FLUJO_OBSERVAR.md) (ver en acción)

---

### 🔬 "Quiero ver funcionando en tiempo real"
**Tiempo: Variable (observación activa)**

1. Instrucciones: [FLUJO_OBSERVAR.md](FLUJO_OBSERVAR.md)
   - Cómo iniciar el sistema
   - Qué esperar
   - Cómo interpretar datos
   - Debugging en vivo

---

## 📖 Descripción de Documentos

### [FLUJO_SIMPLIFICADO.md](FLUJO_SIMPLIFICADO.md)
**Nivel Básico**

Contiene:
- ✅ ¿Qué hace el proyecto? (1 párrafo)
- ✅ ¿Cómo funciona? (6 pasos principales)
- ✅ ¿Cuándo ocurre cada cosa? (línea de tiempo)
- ✅ Frecuencias de ejecución
- ✅ Escenario real de 10 minutos
- ✅ Concepto: Equilibrio dinámico
- ✅ Resumen en una frase

**Lee si**: Necesitas entender rápido sin profundidad

---

### [FLUJO_EJECUCION.md](FLUJO_EJECUCION.md)
**Nivel Completo**

Contiene:
- ✅ Visión general del sistema
- ✅ Línea de tiempo de ejecución (4 pasos)
- ✅ Ciclo principal detallado (6 acciones)
- ✅ Paralelismo (cronjob, grafana)
- ✅ Flujo de datos completo (kernel → usuario)
- ✅ Descripción de cada componente
- ✅ Ciclo de vida completo
- ✅ Diagrama de estados
- ✅ Comunicación entre componentes
- ✅ Flujos paralelos

**Lee si**: Necesitas documentación de referencia

---

### [FLUJO_OBSERVAR.md](FLUJO_OBSERVAR.md)
**Nivel Práctico**

Contiene:
- ✅ Requisitos previos
- ✅ Paso 1: Iniciar sistema
- ✅ Paso 2: Abrir Grafana
- ✅ Paso 3: Ver flujo en acción
- ✅ Paso 4: Observar patrones
- ✅ Interpretación de datos
- ✅ Debugging en vivo
- ✅ Línea de tiempo de observación
- ✅ Qué screenshot tomar
- ✅ Cómo validar que funciona

**Lee si**: Quieres ejecutar y observar el sistema

---

## 🎬 DIAGRAMAS (En los documentos)

### FLUJO_EJECUCION.md incluye:

```
1. Arquitectura General
   └─ Cómo se conectan todos los componentes

2. Máquina de Estados
   └─ Estados por los que pasa el daemon

3. Secuencia de Ejecución
   └─ Paso a paso con timings

4. Flujo de Datos
   └─ Kernel → Usuario
```

---

## 🚀 FLUJO RECOMENDADO

```
PASO 1: Lectura Rápida (5 min)
    └─ FLUJO_SIMPLIFICADO.md

PASO 2: Ejecutar Sistema (2 min)
    └─ make run -C daemon-go
    └─ docker-compose up -d

PASO 3: Abrir Grafana (1 min)
    └─ http://localhost:3000

PASO 4: Observar (10 min)
    └─ FLUJO_OBSERVAR.md
    └─ Seguir instrucciones

PASO 5: Profundizar (15 min)
    └─ FLUJO_EJECUCION.md
    └─ Leer diagramas

RESULTADO: Entendimiento completo del flujo
```

---

## 📞 RESPUESTAS A PREGUNTAS TÍPICAS

### "¿Cuándo se ejecuta cada cosa?"

**Respuesta**: Lee la sección "Línea de Tiempo" en [FLUJO_SIMPLIFICADO.md](FLUJO_SIMPLIFICADO.md)

```
T=0:00  Daemon inicia
T=0:20  Ciclo daemon #1
T=0:30  Grafana actualiza
T=2:00  Cronjob crea contenedores
...
```

---

### "¿Cómo se comunican los componentes?"

**Respuesta**: Lee "Comunicación entre Componentes" en [FLUJO_EJECUCION.md](FLUJO_EJECUCION.md)

```
Kernel → /proc → Daemon → Valkey → Grafana → Browser
```

---

### "¿Qué debo ver en Grafana?"

**Respuesta**: Lee "Lo que verás en Grafana" en [FLUJO_OBSERVAR.md](FLUJO_OBSERVAR.md)

```
- Tarjetas con valores
- Gráfica zigzag
- Top 5 cambiando
- Contador incrementando
```

---

### "¿Cómo sé que funciona?"

**Respuesta**: Lee "Validación de que funciona" en [FLUJO_OBSERVAR.md](FLUJO_OBSERVAR.md)

```
✅ Grafana se actualiza cada 30s
✅ Números cambian
✅ Sincronización con cronjob
✅ Contador incrementa
✅ Top 5 varía dinámicamente
```

---

## 🎓 CONCEPTOS CLAVE

### Equilibrio Dinámico
Cronjob agrega → Daemon elimina → Equilibrio → Repite
[Ver en FLUJO_SIMPLIFICADO.md > Equilibrio dinámico]

### Paralelismo
Daemon, Cronjob, Grafana ocurren simultáneamente
[Ver en FLUJO_EJECUCION.md > Flujos paralelos]

### Persistencia
Datos en Valkey con TTL de 24h
[Ver en FLUJO_EJECUCION.md > Almacenamiento]

---

## 🔗 CONEXIONES RÁPIDAS

```
¿Cuál es el ciclo principal?
└─ FLUJO_SIMPLIFICADO.md > "Los 6 Pasos"

¿Cuál es el estado inicial?
└─ FLUJO_EJECUCION.md > "Paso 0: Initialize"

¿Cuándo se actualiza Grafana?
└─ FLUJO_EJECUCION.md > "Paso 4: Visualización"

¿Qué hace el cronjob?
└─ FLUJO_SIMPLIFICADO.md > "Minuto 2:00"

¿Cómo elimina contenedores?
└─ FLUJO_SIMPLIFICADO.md > "Paso 4: Acción"

¿Dónde se guardan los datos?
└─ FLUJO_EJECUCION.md > "Esquema de Datos"

¿Cómo observo en vivo?
└─ FLUJO_OBSERVAR.md > Todos los pasos
```

---

## 📊 ESTRUCTURA

```
Proyecto2/
└── docs/
    ├── FLUJO_EJECUCION.md ............ Referencia completa
    ├── FLUJO_SIMPLIFICADO.md ........ Inicio fácil
    ├── FLUJO_OBSERVAR.md ........... Ver en acción
    └── FLUJO_INDICE.md ............. Este archivo
```

---

## 🎯 VALIDACIÓN FINAL

Cuando termines, deberías poder responder:

- [ ] ¿Qué hace el kernel module?
- [ ] ¿Cuál es el ciclo principal del daemon?
- [ ] ¿Cada cuánto ejecuta el cronjob?
- [ ] ¿Cómo se comunican los componentes?
- [ ] ¿Dónde se guardan los datos?
- [ ] ¿Cada cuándo actualiza Grafana?
- [ ] ¿Cuál es el concepto de equilibrio dinámico?

Si respondiste todas, **¡Entiendes el flujo!** ✅

---

**Proyecto 2 - SO1 - Carnet: 202300625**
**Índice de Flujo de Ejecución**
