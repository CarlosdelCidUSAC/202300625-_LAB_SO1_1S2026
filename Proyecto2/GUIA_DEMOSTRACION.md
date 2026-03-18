# Guía Rápida de Demostración - Proyecto 2 SO1

**Carnet: 202300625**

##  Inicio Rápido (5 minutos)

### Pre-requisitos
```bash
# Verificar que tienes permisos
sudo echo "OK"

# Limpiar entorno anterior (opcional)
sudo /home/carlos/Desktop/Proyecto2/tests/limpiar-entorno.sh
```

---

##  Demostración Completa (Paso a Paso)

###  PASO 1: Verificar que todo funciona (1 minuto)
```bash
cd /home/carlos/Desktop/Proyecto2
sudo ./tests/verificar-requisitos.sh
```

**Resultado esperado:** 
-  32/32 pruebas exitosas
-  100% de cumplimiento
-  Reporte generado en `docs/evidencias/verificacion_*.txt`

---

###  PASO 2: Mostrar el módulo kernel (2 minutos)

#### 2.1 Código fuente
```bash
# Ver estructura del módulo
head -60 /home/carlos/Desktop/Proyecto2/kernel-module/src/sonda.c
```

**Explicar:**
- Usa `task_struct` para iterar procesos
- Detecta contenedores por `pid_namespace`
- Calcula memoria (VSZ, RSS, %) y CPU
- Expone todo en `/proc/continfo_pr2_so1_202300625`

#### 2.2 Compilación
```bash
cd /home/carlos/Desktop/Proyecto2/kernel-module
make clean && make
ls -lh build/sonda.ko
```

#### 2.3 Carga del módulo
```bash
sudo insmod build/sonda.ko
lsmod | grep sonda
```

#### 2.4 Verificar salida
```bash
# Ver formato completo
head -40 /proc/continfo_pr2_so1_202300625

# Ver solo contenedores
grep "container:" /proc/continfo_pr2_so1_202300625 | head -10
```

**Explicar formato:**
```
[MEMORIA]
Total: 3921 MB
Libre: 126 MB
Uso: 3795 MB

[PROCESOS]
PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID
```

---

###  PASO 3: Mostrar el daemon GO (3 minutos)

#### 3.1 Estructura del proyecto
```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
tree -L 3 -d
```

**Explicar arquitectura:**
- `cmd/daemon/main.go` → Entrypoint
- `internal/orchestrator/` → Coordinador central
- `internal/parser/` → Lee y parsea `/proc`
- `internal/analyzer/` → Toma decisiones (eliminar)
- `internal/storage/` → Guarda en Valkey
- `internal/config/` → Configuración centralizada

#### 3.2 Ver código clave
```bash
# Parser (lee /proc)
head -100 internal/parser/parser.go

# Analyzer (elimina contenedores)
head -120 internal/analyzer/analyzer.go | grep -A 20 "AnalyzeAndDecide"

# Configuración (restricciones)
grep -A 5 "MinLowConsumption\|MinHighConsumption" internal/config/config.go
```

#### 3.3 Compilar
```bash
go build -o bin/daemon-so1 cmd/daemon/main.go
ls -lh bin/daemon-so1
```

---

###  PASO 4: Cronjob (1 minuto)

#### 4.1 Ver script generador
```bash
cat /home/carlos/Desktop/Proyecto2/docker/generar.sh | head -40
```

**Explicar:**
- Genera 5 contenedores aleatorios
- Tipos: `roldyoran/go-client` (alto RAM), `alpine` (alto CPU o bajo)
- Se ejecuta cada 2 minutos

#### 4.2 Verificar cronjob instalado
```bash
crontab -l
```

**Debe mostrar:**
```
*/2 * * * * /home/carlos/Desktop/Proyecto2/docker/generar.sh >> /var/log/proyecto2-contenedores.log 2>&1
```

#### 4.3 Ver log de ejecuciones
```bash
tail -20 /var/log/proyecto2-contenedores.log
```

---

###  PASO 5: Infraestructura Docker (2 minutos)

#### 5.1 Ver contenedores activos
```bash
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | head -20
```

**Explicar:**
- `dashboard_grafana` → Visualización
- `db_valkey` → Base de datos en memoria
- Múltiples contenedores de prueba (alpine, go-client)

#### 5.2 Verificar Valkey
```bash
# Conexión
sudo docker exec db_valkey valkey-cli PING

# Ver datos almacenados
sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current

# Top 5 RAM
sudo docker exec db_valkey valkey-cli ZREVRANGE metrics:containers:ram:top 0 4 WITHSCORES

# Contenedores eliminados
sudo docker exec db_valkey valkey-cli GET stats:containers_deleted
```

---

###  PASO 6: Dashboard Grafana (3 minutos)

#### 6.1 Abrir navegador
```bash
firefox http://localhost:3000 &
```

**Credenciales:**
- Usuario: `admin`
- Contraseña: `admin`

#### 6.2 Navegar al dashboard
1. Click en el icono de menú (☰) izquierda
2. Click en "Dashboards"
3. Seleccionar: **"Telemetría de Contenedores - Proyecto 2 SO1"**

#### 6.3 Mostrar paneles
**Explicar cada panel:**

1. **Tarjetas superiores:**
   - RAM Total del Sistema
   - RAM Usada
   - Memoria Libre
   - Total Contenedores Eliminados

2. **Gráfico de líneas:**
   - Uso de RAM a lo largo del tiempo

3. **Pie charts:**
   - Top 5 Contenedores por Consumo de RAM
   - Top 5 Contenedores por Consumo de CPU

4. **Gráfico de barras:**
   - Contenedores Eliminados a lo largo del tiempo

---

###  PASO 7: Ejecutar daemon LIVE (5 minutos)

#### 7.1 Ejecutar daemon
```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
sudo ./bin/daemon-so1
```

**Observar salida en tiempo real:**
```
╔════════════════════════════════════════════╗
║  DAEMON GESTOR DE CONTENEDORES   ║
║  Proyecto 2: SO1 Carnet: 202300625        ║
║  Versión: 1.0.0                           ║
╚════════════════════════════════════════════╝

=== INICIALIZANDO DAEMON ===
Iniciando infraestructura con Docker Compose...
✓ Docker Compose iniciado
Cargando módulo del kernel...
✓ Módulo kernel cargado
Instalando cronjob automático...
✓ Cronjob instalado
=== INICIALIZACIÓN COMPLETADA ===

=== INICIANDO LOOP PRINCIPAL ===
Duracion de ciclo: 30 segundos

=== ITERACIÓN DE MONITOREO === numero: 1
Datos parseados correctamente procesos: 458 memoria_usada: 3725
...
```

#### 7.2 Mientras corre, abrir otra terminal
```bash
# Ver contenedores siendo eliminados
watch -n 5 'sudo docker ps --format "table {{.Names}}\t{{.Image}}"'

# Ver datos en Valkey actualizándose
watch -n 5 'sudo docker exec db_valkey valkey-cli GET stats:containers_deleted'
```

#### 7.3 Ver Grafana actualizándose
- Refrescar el dashboard (F5)
- Ver gráficos actualizándose en tiempo real

#### 7.4 Detener daemon
```
Ctrl+C
```

**Observar cleanup:**
```
Señal recibida señal: interrupt
=== FINALIZANDO DAEMON ===
Desinstalando cronjob...
Descargando módulo del kernel...
Deteniendo servicios...
=== DAEMON FINALIZADO ===
```

---

##  Verificar Restricciones Clave

### Restricción 1: Mínimo 3 bajo consumo + 2 alto consumo
```bash
# Ver configuración
grep -A 3 "Contenedores" /home/carlos/Desktop/Proyecto2/daemon-go/internal/config/config.go

# Verificar código de análisis
grep -A 20 "canDeleteFromLow\|canDeleteFromHigh" \
  /home/carlos/Desktop/Proyecto2/daemon-go/internal/analyzer/analyzer.go
```

### Restricción 2: No eliminar Grafana/Valkey
```bash
# Ver protección en código
grep -B 5 -A 5 'grafana\|valkey' \
  /home/carlos/Desktop/Proyecto2/daemon-go/internal/analyzer/analyzer.go
```

### Restricción 3: Almacenamiento en Valkey
```bash
# Ver estructura de almacenamiento
head -80 /home/carlos/Desktop/Proyecto2/daemon-go/internal/storage/valkey.go
```

---

##  Escenarios de Prueba Sugeridos

### Escenario 1: Sistema bajo carga
```bash
# Generar muchos contenedores manualmente
for i in {1..10}; do
    sudo docker run -d roldyoran/go-client
done

# Observar que el daemon los elimina progresivamente
```

### Escenario 2: Verificar formato de /proc
```bash
# Comparar con requisitos del proyecto
head -50 /proc/continfo_pr2_so1_202300625

# Verificar columnas: PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID
```

### Escenario 3: Validar dashboard
```bash
# Insertar datos de prueba
bash /home/carlos/Desktop/Proyecto2/scripts/test-grafana.sh

# Ver reflejado en Grafana
```

---

##  Puntos Clave para la Defensa

### **Competencia Técnica (85 pts)**

**Módulo Kernel (40 pts):**
 Compila con Makefile  
 Se carga/descarga limpiamente  
 Crea `/proc/continfo_pr2_so1_202300625`  
 Formato correcto: `[MEMORIA]` y `[PROCESOS]`  
 Datos completos: PID, Nombre, VSZ, RSS, %RAM, CPU, ComandoID  

**Daemon GO (25 pts):**
 Compila sin errores  
 Lee y parsea `/proc` correctamente  
 Almacena en Valkey con estructura apropiada  
 Toma decisiones de eliminación basadas en reglas  

**Calidad de Código (20 pts):**
 Código kernel comentado y estructurado  
 Daemon GO modular (parser/analyzer/storage/orchestrator)  
 Makefile funcional para kernel  
 go.mod y estructura de paquetes correcta  

### **Documentación (15 pts)**

**Manual Técnico debe incluir:**
- Arquitectura del sistema (diagrama)
- Explicación del módulo kernel
- Explicación del daemon GO
- Formato de datos en Valkey
- Configuración de Grafana
- **Usar reporte de `verificar-requisitos.sh` como evidencia**

**Manual de Usuario debe incluir:**
- Instalación paso a paso
- Ejecución del daemon
- Acceso a Grafana
- Interpretación del dashboard

---

##  Checklist Pre-Demostración

- [ ] Compilar módulo kernel (`make clean && make`)
- [ ] Compilar daemon GO (`go build`)
- [ ] Levantar Grafana + Valkey (`docker-compose up -d`)
- [ ] Tener terminal limpia y preparada
- [ ] Abrir navegador con Grafana en pestaña
- [ ] Tener script `verificar-requisitos.sh` listo
- [ ] Conocer código clave (parser, analyzer, sonda.c)
- [ ] Revisar restricciones implementadas

---

##  Comandos de Emergencia

### Si algo no funciona:
```bash
# Reinicio completo del proyecto
cd /home/carlos/Desktop/Proyecto2
bash scripts/restart-services.sh
```

### Si el módulo no carga:
```bash
# Ver errores del kernel
sudo dmesg | tail -20

# Recompilar
cd kernel-module && make clean && make
```

### Si Grafana no muestra datos:
```bash
# Reconfigurar datasource
bash scripts/setup-grafana-datasource.sh
```

### Si Valkey no responde:
```bash
# Reiniciar contenedor
sudo docker restart db_valkey
```

---

**¡Éxito en tu demostración!** 🎓

**Carnet: 202300625**  
**Proyecto 2 - Sistemas Operativos 1**
