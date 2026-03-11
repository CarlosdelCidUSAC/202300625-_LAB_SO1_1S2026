# Guía de Verificación de Requisitos - Proyecto 2 SO1

**Carnet: 202300625**  
**Sistema Operativos 1**

## Scripts de Verificación Creados

### 1. `tests/verificar-requisitos.sh` ✅
Script completo que valida **todos los requisitos** del proyecto automáticamente.

**Ejecución:**
```bash
cd /home/carlos/Desktop/Proyecto2
sudo ./tests/verificar-requisitos.sh
```

**Qué verifica:**
- ✅ Compilación del módulo kernel (Makefile, sonda.c → sonda.ko)
- ✅ Carga del módulo en el kernel (`insmod`)
- ✅ Creación y formato del archivo `/proc/continfo_pr2_so1_202300625`
- ✅ Datos de memoria (Total, Libre, Uso)
- ✅ Procesos listados con formato correcto (`PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID`)
- ✅ Compilación del daemon GO
- ✅ Estructura de paquetes internos (parser, analyzer, storage, orchestrator)
- ✅ Scripts de cronjob (install/uninstall)
- ✅ Contenedores Docker (Grafana, Valkey)
- ✅ Almacenamiento en Valkey (métricas de memoria, Top 5 RAM/CPU, contador de eliminados)
- ✅ Restricciones clave (mínimos: 3 bajo consumo, 2 alto consumo)

**Salida:** Genera reporte en `docs/evidencias/verificacion_TIMESTAMP.txt` con evidencias para el manual técnico.

---

### 2. `tests/limpiar-entorno.sh` 🧹
Script para limpiar el entorno antes de una demostración.

**Ejecución:**
```bash
sudo ./tests/limpiar-entorno.sh
```

**Qué hace:**
- Elimina todos los contenedores de prueba (excepto Grafana y Valkey)
- Limpia datos acumulados en Valkey
- Descarga el módulo kernel si está cargado
- Reporta estado final del sistema

---

## Flujo de Ejecución del Proyecto

### Fase 1: Preparación del Entorno
```bash
# 1. Compilar módulo kernel
cd /home/carlos/Desktop/Proyecto2/kernel-module
make clean && make

# 2. Compilar daemon GO
cd /home/carlos/Desktop/Proyecto2/daemon-go
go build -o bin/daemon-so1 cmd/daemon/main.go

# 3. Levantar infraestructura (Grafana + Valkey)
cd /home/carlos/Desktop/Proyecto2/docker
sudo docker-compose up -d
```

### Fase 2: Inicialización del Sistema
```bash
# 4. Cargar módulo kernel manualmente (o dejar que el daemon lo haga)
sudo insmod /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko

# 5. Verificar que /proc se creó
ls -la /proc/continfo_pr2_so1_202300625
head -20 /proc/continfo_pr2_so1_202300625

# 6. Instalar cronjob
bash /home/carlos/Desktop/Proyecto2/cron/install-cron.sh
crontab -l  # Verificar
```

### Fase 3: Ejecución del Daemon
```bash
# 7. Ejecutar daemon (hace todo automáticamente)
cd /home/carlos/Desktop/Proyecto2/daemon-go
sudo ./bin/daemon-so1
```

**El daemon automáticamente:**
- ✅ Levanta `docker-compose` (Grafana + Valkey)
- ✅ Carga el módulo kernel
- ✅ Instala el cronjob
- ✅ Entra en loop (cada 30s):
  - Lee `/proc/continfo_pr2_so1_202300625`
  - Parsea datos (memoria + procesos)
  - Guarda métricas en Valkey
  - Analiza y elimina contenedores según reglas
- ✅ Al finalizar (Ctrl+C):
  - Desinstala cronjob
  - Descarga módulo kernel
  - Detiene docker-compose

### Fase 4: Visualización en Grafana
```bash
# 8. Abrir navegador
firefox http://localhost:3000

# Credenciales:
#   Usuario: daemon-so1
#   Contraseña: 1234

# 9. Ir a Dashboards → "Telemetría de Contenedores - Proyecto 2 SO1"
```

**Dashboard muestra:**
- 📊 RAM Total, Usada, Libre
- 📈 Uso de RAM a lo largo del tiempo
- 🥧 Top 5 contenedores por RAM
- 🥧 Top 5 contenedores por CPU
- 📊 Contenedores eliminados a lo largo del tiempo

---

## Comandos de Validación Manual

### Módulo Kernel
```bash
# Compilar
cd /home/carlos/Desktop/Proyecto2/kernel-module && make

# Cargar
sudo insmod build/sonda.ko

# Verificar
lsmod | grep sonda
cat /proc/continfo_pr2_so1_202300625 | head -30

# Descargar
sudo rmmod sonda
```

### Daemon GO
```bash
# Compilar
cd /home/carlos/Desktop/Proyecto2/daemon-go
go build -o bin/daemon-so1 cmd/daemon/main.go

# Verificar sintaxis
go test ./...  # Debe estar limpio ahora

# Ejecutar
sudo ./bin/daemon-so1
```

### Cronjob
```bash
# Instalar
bash /home/carlos/Desktop/Proyecto2/cron/install-cron.sh

# Verificar
crontab -l
tail -f /var/log/proyecto2-contenedores.log

# Desinstalar
bash /home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh
```

### Docker
```bash
# Estado de contenedores
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

# Logs de Grafana
sudo docker logs dashboard_grafana

# Logs de Valkey
sudo docker logs db_valkey

# Consultar datos en Valkey
sudo docker exec db_valkey valkey-cli HGETALL metrics:memory:current
sudo docker exec db_valkey valkey-cli ZREVRANGE metrics:containers:ram:top 0 4 WITHSCORES
sudo docker exec db_valkey valkey-cli GET stats:containers_deleted
```

---

## Checklist de Cumplimiento (copiado del Proyecto)

### Módulo de Kernel (40 pts)
- [x] **1.1** Makefile correcto, módulo compila
- [x] **1.2** Módulo se carga/descarga limpiamente
- [x] **1.3** Archivo en `/proc` se crea/elimina y es legible
- [x] **1.4** Daemon GO compila y se ejecuta
- [x] **1.5** Daemon lee `/proc` e implementa opciones obligatorias

### Extracción y Parseo (25 pts)
- [x] **2.1** Módulo itera correctamente `task_struct`
- [x] **2.2** Se extraen PID, Memoria, CPU correctamente
- [x] **2.3** Daemon parsea información y la almacena en Valkey

### Calidad del Código (20 pts)
- [x] **3.1** Código kernel legible, estructurado y comentado
- [x] **3.2** Daemon GO usa datos del módulo correctamente

### Documentación (15 pts)
- [ ] **4.1** Manual técnico y manual de usuario (pendiente)
- [x] **4.2** Comprensión demostrada

---

## Troubleshooting

### Error: "Module not found"
```bash
# Verificar ruta correcta
ls -la /home/carlos/Desktop/Proyecto2/kernel-module/build/sonda.ko
```

### Error: "Permission denied" en docker
```bash
# Agregar usuario a grupo docker
sudo usermod -aG docker $USER
# Reiniciar sesión
```

### Error: "Valkey connection refused"
```bash
# Esperar a que Valkey esté listo
sudo docker logs db_valkey
sudo docker exec db_valkey valkey-cli ping
```

### Grafana no muestra datos
```bash
# 1. Verificar que el datasource está configurado
# 2. Ejecutar script de configuración:
bash /home/carlos/Desktop/Proyecto2/scripts/setup-grafana-datasource.sh

# 3. Insertar datos de prueba:
bash /home/carlos/Desktop/Proyecto2/scripts/test-grafana.sh
```

---

## Evidencias para el Manual Técnico

El script `verificar-requisitos.sh` genera automáticamente un reporte en:
```
/home/carlos/Desktop/Proyecto2/docs/evidencias/verificacion_TIMESTAMP.txt
```

Contiene:
- ✅ Resultado de cada prueba (PASS/FAIL)
- 📄 Muestra del archivo `/proc`
- 🐳 Lista de contenedores Docker activos
- 📊 Datos almacenados en Valkey
- 📈 Porcentaje de cumplimiento

**Usar este reporte como base para la sección de "Pruebas y Validación" del manual técnico.**

---

## Notas Importantes

1. **Restricciones cumplidas:**
   - Siempre mantiene mínimo 3 contenedores de bajo consumo
   - Siempre mantiene mínimo 2 contenedores de alto consumo
   - Nunca elimina Grafana ni Valkey

2. **Formato del archivo /proc:**
   ```
   [MEMORIA]
   Total: XXXX MB
   Libre: XXXX MB
   Uso: XXXX MB

   [PROCESOS]
   PID|Nombre|VSZ|RSS|%RAM|CPU|ComandoID
   1|systemd|26080|12232|0.30|4035506315|/usr/lib/systemd/systemd
   ...
   ```

3. **Ciclo de monitoreo:** 30 segundos por defecto (configurable en `daemon-go/internal/config/config.go`)

4. **Cronjob:** Ejecuta cada 2 minutos (`*/2 * * * *`)

---

**Autor:** Carlos - 202300625  
**Fecha:** Marzo 2026  
**Curso:** Sistemas Operativos 1
