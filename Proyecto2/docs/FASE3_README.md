# Fase 3: Imágenes Docker, Scripts y Cronjob

## Descripción

Esta fase implementa el sistema de generación automática de contenedores Docker con diferentes perfiles de consumo, junto con un cronjob que ejecuta el proceso automáticamente cada 2 minutos.

## Estructura

```
docker/
├── high-memory/
│   └── Dockerfile          # Imagen para alto consumo de RAM (go-client)
├── high-cpu/
│   └── Dockerfile          # Imagen para alto consumo de CPU (cálculos matemáticos)
├── low-consumption/
│   └── Dockerfile          # Imagen para bajo consumo (simple sleep)
├── generar.sh              # Script principal de generación de contenedores
├── docekr-compose.yml      # Docker Compose con Valkey y Grafana
└── grafana/                # Configuraciones de Grafana
    ├── dashboards/
    ├── provisioning/
    │   ├── dashboards/
    │   └── datasources/
└── valkey/
    └── main.go

cron/
├── install-cron.sh         # Script para instalar cronjob
├── uninstall-cron.sh       # Script para desinstalar cronjob
```

## Imágenes Docker

### 1. Alto Consumo de RAM (go-client)
- **Dockerfile**: `docker/high-memory/Dockerfile`
- **Descripción**: Utiliza la imagen precompilada `roldyoran/go-client`
- **Consumo**: Significativo consumo de memoria RAM
- **Comando**: `docker run -d roldyoran/go-client`

### 2. Alto Consumo de CPU  
- **Dockerfile**: `docker/high-cpu/Dockerfile`
- **Descripción**: Contenedor Alpine que ejecuta cálculos matemáticos infinitos
- **Consumo**: Alta carga computacional
- **Comando**: `docker run -d alpine sh -c "while true; do echo '2^20' | bc > /dev/null; sleep 2; done"`

### 3. Bajo Consumo
- **Dockerfile**: `docker/low-consumption/Dockerfile`
- **Descripción**: Contenedor Alpine que simplemente duerme
- **Consumo**: Ínfimo de RAM y CPU
- **Comando**: `docker run -d alpine sleep 240`

## Script de Generación

**Archivo**: `docker/generar.sh`

### Funcionalidades:
- Crea **5 contenedores** en cada ejecución
- Selecciona **aleatoriamente** entre las 3 imágenes disponibles
- Manejo de errores y logging de resultados
- Genera timestamps para cada contenedor creado
- Reporta éxitos y errores

### Ejecución Manual:
```bash
/home/carlos/Desktop/Proyecto2/docker/generar.sh
```

### Salida Esperada:
```
======================================
Iniciando creacion de 5 contenedores aleatorios...
======================================
[2026-03-05 20:15:30] Contenedor 1/5: High Consumo RAM (indice 0)
  ✓ Contenedor creado exitosamente
[2026-03-05 20:15:31] Contenedor 2/5: Bajo consumo (indice 2)
  ✓ Contenedor creado exitosamente
... (más contenedores)
======================================
Despliegue finalizado.
Contenedores creados: 5
Errores: 0
======================================
```

## Cronjob

### Instalación

**Script**: `cron/install-cron.sh`

```bash
bash /home/carlos/Desktop/Proyecto2/cron/install-cron.sh
```

### Características:
- Ejecuta `generar.sh` **cada 2 minutos**
- Log a `/var/log/proyecto2-contenedores.log`
- Verifica existencia del script antes de instalar
- Evita instalación duplicada
- Muestra cronjobs activos tras instalación

### Desinstalación

**Script**: `cron/uninstall-cron.sh`

```bash
bash /home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh
```

### Formato crontab:
```
*/2 * * * * /home/carlos/Desktop/Proyecto2/docker/generar.sh >> /var/log/proyecto2-contenedores.log 2>&1
```

### Ver Cronjobs Activos:
```bash
crontab -l
```

### Ver Logs:
```bash
sudo tail -f /var/log/proyecto2-contenedores.log
```

## Docker Compose

**Archivo**: `docker/docekr-compose.yml`

Define dos servicios:

### Valkey (Base de Datos)
- **Puerto**: 6379
- **Imagen**: valkey/valkey:latest
- **Contenedor**: db_valkey
- **Red**: red_telemetria

### Grafana (Dashboard)
- **Puerto**: 3000
- **Imagen**: grafana/grafana:latest
- **Contenedor**: dashboard_grafana
- **Usuario**: admin
- **Contraseña**: admin
- **Red**: red_telemetria

### Iniciar servicios:
```bash
cd /home/carlos/Desktop/Proyecto2/docker
docker-compose -f docekr-compose.yml up -d
```

### Verificar estado:
```bash
docker-compose -f docekr-compose.yml ps
```

### Detener servicios:
```bash
docker-compose -f docekr-compose.yml down
```

## Flujo de Trabajo Fase 3

1. **Iniciar servicios base**:
   ```bash
   docker-compose -f /home/carlos/Desktop/Proyecto2/docker/docekr-compose.yml up -d
   ```

2. **Instalar cronjob**:
   ```bash
   bash /home/carlos/Desktop/Proyecto2/cron/install-cron.sh
   ```

3. **Verificar cronjob instalado**:
   ```bash
   crontab -l
   ```

4. **Monitorear generación de contenedores**:
   ```bash
   # Terminal 1: Ver logs en tiempo real
   sudo tail -f /var/log/proyecto2-contenedores.log
   
   # Terminal 2: Ver contenedores activos
   docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
   ```

5. **Acceder a Grafana**:
   ```
   http://localhost:3000
   Usuario: admin
   Contraseña: admin
   ```

## Testing

### Probar generación manual:
```bash
bash /home/carlos/Desktop/Proyecto2/docker/generar.sh
docker ps
```

### Ver contenedores creados:
```bash
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.CreatedAt}}"
```

### Limpiar contenedores (si es necesario):
```bash
# Eliminar todos los contenedores parados
docker container prune -f

# Eliminar todos los contenedores
docker rm -f $(docker ps -aq)
```

## Notas Importantes

- El cronjob requiere que el script sea ejecutable: `chmod +x /home/carlos/Desktop/Proyecto2/docker/generar.sh`
- Los logs de cronjob necesitan permisos de escritura: `sudo chmod 666 /var/log/proyecto2-contenedores.log`
- Valkey y Grafana se comunican entre sí en la red `red_telemetria`
- Los contenedores generados se crean en la red por defecto (bridge)
- Cada ejecución crea 5 nuevos contenedores

## Próximos Pasos

- **Fase 4**: Implementar el Daemon en Go que:
  - Levanta Grafana al iniciar
  - Lee datos del módulo kernel
  - Analiza consumo de contenedores
  - Almacena en Valkey
  - Elimina contenedores según restricciones
