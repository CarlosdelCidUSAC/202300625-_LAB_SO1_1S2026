# Manual de Usuario - Sistema de Monitoreo de Contenedores

## **Introducción**

Bienvenido al sistema de monitoreo y gestión automatizada de contenedores. Este sistema está diseñado para:

- **Monitorear** en tiempo real el uso de recursos (CPU, RAM) de contenedores Docker.
- **Tomar decisiones automáticas** sobre la eliminación de contenedores cuando se superan umbrales de consumo.
- **Visualizar métricas** mediante un dashboard interactivo en Grafana.
- **Generar carga de prueba** automáticamente para simular escenarios reales.

### **Componentes principales**

1. **Módulo del kernel** (`sonda.ko`) – Expone métricas del sistema en `/proc/continfo_pr2_so1_202300625`.
2. **Daemon en Go** (`daemon-so1`) – Lee, analiza y actúa sobre los datos del módulo kernel.
3. **Base de datos Valkey** – Almacena las métricas históricas y en tiempo real.
4. **Dashboard Grafana** – Presenta gráficos y paneles para visualizar el estado del sistema.
5. **Cronjob** – Genera contenedores de prueba cada 2 minutos.

### **Público objetivo**

Este manual está dirigido a:
- **Estudiantes** que desean ejecutar el proyecto para fines académicos.
- **Administradores de sistemas** que necesitan un sistema de monitoreo ligero.
- **Evaluadores** que verifican el funcionamiento del proyecto.

---

## **1. Requisitos Previos**

Antes de comenzar, asegúrate de tener lo siguiente:

### **1.1 Software requerido**
- **Sistema Operativo**: Linux (probado con kernel 5.x o superior).
- **Docker** y **Docker Compose**.
- **Go** (versión 1.20 o superior).
- **GCC** y **Make** (para compilar el módulo kernel).
- **Headers del kernel** (`/lib/modules/$(uname -r)/build`).
- Permisos de **sudo** para operaciones privilegiadas.

### **1.2 Verificación rápida**
Ejecuta los siguientes comandos para confirmar que tienes lo necesario:

```bash
# Verificar Docker
docker --version

# Verificar Go
go version

# Verificar GCC
gcc --version

# Verificar headers del kernel
ls /lib/modules/$(uname -r)/build
```

Si algún comando falla, instala los paquetes necesarios antes de continuar.

---

## **2. Instalación Paso a Paso**

### **2.1 Ubicación del proyecto**

El proyecto se encuentra en:
```bash
cd /home/carlos/Desktop/Proyecto2
```

Si tienes una ubicación diferente, ajusta las rutas en los comandos.

### **2.2 Compilar el módulo del kernel**

```bash
cd kernel-module
make clean && make
```

**Salida esperada:**
```
  CC [M]  src/sonda.o
  LD [M]  build/sonda.ko
  MODPOST build/sonda.mod
  CC      build/sonda.mod.o
  LD [M]  build/sonda.ko
```

Verifica que el archivo `build/sonda.ko` se haya generado:
```bash
ls -lh build/sonda.ko
```

### **2.3 Compilar el daemon en Go**

```bash
cd ../daemon-go
go build -o bin/daemon-so1 cmd/daemon/main.go
```

**Salida esperada:**
- Binario `bin/daemon-so1` creado.

Verifica:
```bash
ls -lh bin/daemon-so1
```

### **2.4 Levantar la infraestructura Docker**

```bash
cd ../docker
sudo docker-compose up -d
```

**Servicios que deben estar activos:**
- `db_valkey` (puerto 6379) – Base de datos en memoria.
- `dashboard_grafana` (puerto 3000) – Dashboard de visualización.

Verifica:
```bash
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```

Deberías ver ambos contenedores con estado `Up`.

---

## **3. Ejecución del Sistema**

### **3.1 Iniciar el daemon principal**

```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
sudo ./bin/daemon-so1
```

**¿Qué hace el daemon?**
1. Levanta Docker Compose (si no está activo).
2. Carga el módulo del kernel.
3. Instala un cronjob que genera contenedores de prueba cada 2 minutos.
4. Entra en un ciclo de monitoreo cada 30 segundos.

**Salida esperada (primeros segundos):**
```
╔════════════════════════════════════════════╗
║  DAEMON GESTOR DE CONTENEDORES             ║
║  Proyecto 2: SO1 Carnet: 202300625         ║
║  Versión: 1.0.0                            ║
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
```

### **3.2 Verificar que todo funciona**

Abre **otra terminal** y ejecuta:

```bash
# Verificar módulo cargado
lsmod | grep sonda

# Verificar archivo /proc
head -20 /proc/continfo_pr2_so1_202300625

# Verificar cronjob
crontab -l

# Verificar contenedores de prueba
sudo docker ps | grep -E "alpine|go-client"
```

### **3.3 Ejecución en segundo plano (opcional)**

Si deseas ejecutar el daemon como servicio en segundo plano:

```bash
cd /home/carlos/Desktop/Proyecto2/daemon-go
sudo nohup ./bin/daemon-so1 > daemon.log 2>&1 &
```

Puedes ver los logs en cualquier momento:
```bash
tail -f daemon.log
```

---

## **4. Dashboard Grafana**

### **4.1 Acceso**

1. Abre tu navegador web.
2. Ve a la dirección: **http://localhost:3000**
3. Credenciales:
   - **Usuario**: `admin`
   - **Contraseña**: `1234`

### **4.2 Navegación básica**

1. **Menú principal** (icono ☰ en la esquina superior izquierda).
2. Selecciona **"Dashboards"** → **"Browse"**.
3. Elige el dashboard llamado **"Telemetría de Contenedores – Proyecto 2 SO1"**.

### **4.3 Paneles explicados**

#### **Tarjetas superiores**
- **RAM Total del Sistema**: Memoria física total disponible.
- **RAM Usada**: Memoria actualmente en uso.
- **Memoria Libre**: Memoria disponible para nuevos procesos.
- **Total Contenedores Eliminados**: Número acumulado de contenedores eliminados por el daemon.

#### **Gráfico de líneas**
- **Uso de RAM a lo largo del tiempo**: Muestra cómo varía el consumo de memoria.

#### **Gráficos circulares (Pie charts)**
- **Top 5 Contenedores por Consumo de RAM**: Los 5 contenedores que más memoria usan.
- **Top 5 Contenedores por Consumo de CPU**: Los 5 contenedores que más CPU usan.

#### **Gráfico de barras**
- **Contenedores Eliminados a lo largo del tiempo**: Histórico de eliminaciones por ciclo.

### **4.4 Actualización y rango de tiempo**

- **Actualizar manualmente**: Click en el icono de refresh (↻).
- **Cambiar rango de tiempo**: Selector en la esquina superior derecha (por defecto: "Últimos 6 horas").
- **Auto‑refresh**: Puedes configurar actualización automática en el mismo selector.

---

## **5. Operación Diaria**

### **5.1 Comandos útiles para ver el estado**

```bash
# Ver todos los contenedores (incluidos los de prueba)
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

# Ver métricas en Valkey
sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current

# Ver top 5 de consumo de RAM
sudo docker exec db_valkey valkey-cli ZREVRANGE metrics:containers:ram:top 0 4 WITHSCORES

# Ver contador de eliminados
sudo docker exec db_valkey valkey-cli GET stats:containers_deleted

# Ver logs del cronjob
tail -20 /var/log/proyecto2-contenedores.log
```

### **5.2 Ver logs del daemon**

Si ejecutaste el daemon en primer plano (sección 3.1), los logs se muestran en la terminal.  
Si lo ejecutaste en segundo plano (sección 3.3):

```bash
tail -f /home/carlos/Desktop/Proyecto2/daemon-go/daemon.log
```

### **5.3 Reiniciar componentes individuales**

#### **Reiniciar solo Grafana o Valkey**
```bash
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose restart dashboard_grafana
sudo docker-compose restart db_valkey
```

#### **Recargar módulo del kernel**
```bash
sudo rmmod sonda 2>/dev/null || true
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
```

#### **Reinstalar cronjob**
```bash
bash /home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh
bash /home/carlos/Desktop/Proyecto2/cron/install-cron.sh
```

### **5.4 Generar carga manual (para pruebas)**

```bash
# Ejecutar el script generador una vez
bash /home/carlos/Desktop/Proyecto2/docker/generar.sh

# Ver los nuevos contenedores
sudo docker ps | grep -E "alpine|go-client"
```

---

## **6. Solución de Problemas Comunes**

### **6.1 El módulo del kernel no se carga**

**Síntoma:**  
```bash
sudo insmod build/sonda.ko
# ERROR: could not insert module build/sonda.ko: Operation not permitted
```

**Soluciones:**
1. Verificar que tienes permisos de sudo.
2. Asegurarte de que los headers del kernel están instalados:
   ```bash
   sudo apt-get install linux-headers-$(uname -r)   # Para Debian/Ubuntu
   ```
3. Recompilar el módulo:
   ```bash
   cd /home/carlos/Desktop/Proyecto2/kernel-module
   make clean && make
   ```

### **6.2 No aparece el archivo `/proc/continfo_pr2_so1_202300625`**

**Posibles causas:**
- El módulo no está cargado.
- El módulo se cargó pero hubo un error.

**Verificación:**
```bash
# Ver si el módulo está cargado
lsmod | grep sonda

# Ver logs del kernel
dmesg | tail -30

# Recargar módulo
sudo rmmod sonda 2>/dev/null || true
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
```

### **6.3 Grafana no muestra datos**

**Pasos para diagnosticar:**
1. Verificar que Valkey tiene datos:
   ```bash
   sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current
   ```
2. Verificar que el daemon está ejecutándose:
   ```bash
   ps aux | grep daemon-so1
   ```
3. Revisar la configuración del datasource en Grafana:
   ```bash
   # Reconfigurar datasource
   bash /home/carlos/Desktop/Proyecto2/scripts/setup-grafana-datasource.sh
   ```

### **6.4 Valkey no responde**

**Síntoma:**  
```bash
sudo docker exec db_valkey valkey-cli PING
# (sin respuesta o error de conexión)
```

**Solución:**
```bash
# Reiniciar el contenedor
sudo docker restart db_valkey

# Verificar que está corriendo
sudo docker ps | grep db_valkey
```

### **6.5 El cronjob no genera contenedores**

**Verificación:**
```bash
# Ver si el cronjob está instalado
crontab -l

# Ver logs del cronjob
tail -30 /var/log/proyecto2-contenedores.log

# Ejecutar manualmente el script
bash /home/carlos/Desktop/Proyecto2/docker/generar.sh
```

---

## **7. Apagado y Mantenimiento**

### **7.1 Detener el sistema de forma controlada**

Si el daemon está corriendo en primer plano, presiona **Ctrl+C**.  
El daemon realizará automáticamente:

1. Desinstalación del cronjob.
2. Descarga del módulo del kernel.
3. Detención de los servicios Docker.

**Salida esperada:**
```
Señal recibida señal: interrupt
=== FINALIZANDO DAEMON ===
Desinstalando cronjob...
Descargando módulo del kernel...
Deteniendo servicios...
=== DAEMON FINALIZADO ===
```

### **7.2 Detener manualmente todos los componentes**

```bash
# Detener daemon (si está en segundo plano)
pkill -f daemon-so1

# Desinstalar cronjob
bash /home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh

# Descargar módulo kernel
sudo rmmod sonda 2>/dev/null || true

# Bajar servicios Docker
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose down
```

### **7.3 Limpieza completa**

Para eliminar todos los contenedores, imágenes y volúmenes creados por el proyecto:

```bash
cd /home/carlos/Desktop/Proyecto2
sudo ./tests/limpiar-entorno.sh
```

**¡Advertencia!** Este comando eliminará todos los contenedores de prueba y datos almacenados.

---

## **8. Apéndices**

### **8.1 Referencia rápida de comandos**

| Comando | Descripción |
|---------|-------------|
| `sudo ./bin/daemon-so1` | Iniciar daemon en primer plano |
| `sudo nohup ./bin/daemon-so1 &` | Iniciar daemon en segundo plano |
| `tail -f daemon.log` | Ver logs del daemon |
| `sudo docker ps` | Listar contenedores activos |
| `sudo docker exec db_valkey valkey-cli PING` | Probar conexión a Valkey |
| `http://localhost:3000` | Acceder a Grafana |
| `head -30 /proc/continfo_pr2_so1_202300625` | Ver datos del módulo kernel |
| `bash cron/install-cron.sh` | Instalar cronjob |
| `bash cron/uninstall-cron.sh` | Desinstalar cronjob |

### **8.2 Estructura de archivos clave**

```
Proyecto2/
├── kernel-module/
│   ├── src/sonda.c          # Código fuente del módulo kernel
│   ├── build/sonda.ko       # Módulo compilado
│   └── Makefile             # Script de compilación
├── daemon-go/
│   ├── cmd/daemon/main.go   # Punto de entrada del daemon
│   ├── bin/daemon-so1       # Daemon compilado
│   └── internal/            # Lógica interna (parser, analyzer, storage)
├── docker/
│   ├── docker-compose.yml   # Definición de servicios
│   ├── generar.sh           # Script generador de contenedores
│   └── grafana/             # Configuración de Grafana
├── cron/
│   ├── install-cron.sh      # Instalador de cronjob
│   └── uninstall-cron.sh    # Desinstalador de cronjob
└── tests/
    └── verificar-requisitos.sh  # Script de verificación completa
```

## **9. Verificación Final**

Ejecuta el script de verificación para confirmar que todo está funcionando correctamente:

```bash
cd /home/carlos/Desktop/Proyecto2
sudo ./tests/verificar-requisitos.sh
```

Este script generará un reporte detallado en `docs/evidencias/verificacion_YYYYMMDD_HHMMSS.txt` con el porcentaje de cumplimiento de requisitos.

---

**¡Gracias por usar el sistema de monitoreo de contenedores!** 

*Si tienes preguntas o encuentras algún problema, no dudes en revisar la documentación técnica o contactar al desarrollador.*