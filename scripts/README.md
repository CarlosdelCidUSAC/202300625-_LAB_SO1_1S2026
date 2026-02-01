# Scripts de Generación de Logs

Esta carpeta contiene scripts automatizados para generar y gestionar logs de pruebas de las APIs.

## Inicio Rápido

**Forma más fácil (recomendada):**
```bash
cd scripts
./logs-manager.sh
```

Este script interactivo te guía por todas las opciones disponibles.

---

## Scripts Disponibles

### `logs-manager.sh` (RECOMENDADO)
Script maestro con menú interactivo para gestionar todos los logs.

**Uso:**
```bash
cd scripts
./logs-manager.sh
```

**Características:**
- Menú interactivo fácil de usar
- Genera logs de pruebas exitosas
- Genera logs de error
- Visualiza logs generados
- Muestra resumen
- Limpia logs antiguos
- Ayuda integrada

---

### `generate-logs.sh`
Genera todos los logs de pruebas cuando las APIs están funcionando correctamente.

**Uso:**
```bash
cd scripts
./generate-logs.sh
```

**Genera:**
- Logs de health checks de todas las APIs
- Logs de comunicación exitosa entre APIs
- Resumen general

**Salida:** Archivos `.log` en el directorio `../logs/`

---

### `generate-error-logs.sh`
Genera logs de pruebas de error cuando una API está caída.

**Uso:**
```bash
cd scripts
./generate-error-logs.sh
```

**Casos de prueba:**
- API1 -> API3 (con API3 detenida)
- API2 -> API1 (con API1 detenida)
- API3 -> API2 (con API2 detenida)

**Nota:** Para logs reales, detén la API correspondiente antes de ejecutar.

---

### `view-logs.sh`
Visualiza los logs generados de forma interactiva.

**Uso:**
```bash
cd scripts
./view-logs.sh
```

**Opciones:**
1. Ver solo health checks
2. Ver comunicación exitosa
3. Ver logs de error
4. Ver todos los logs
5. Buscar log específico

---

### `clean-logs.sh`
Limpia todos los logs generados previamente.

**Uso:**
```bash
cd scripts
./clean-logs.sh
```

---

### `test_workflow.sh`
Script de pruebas existente del proyecto.

---

## Flujo de Trabajo Recomendado

### 1. Preparación
```bash
# Verificar que las VMs estén activas
ping -c 2 192.168.122.10  # VM1
ping -c 2 192.168.122.20  # VM2

# Verificar que las APIs estén corriendo
curl http://192.168.122.10:8081/health
curl http://192.168.122.10:8082/health
curl http://192.168.122.20:8083/health
```

### 2. Generar Logs Exitosos
```bash
cd scripts
./generate-logs.sh
```

### 3. Generar Logs de Error (Opcional)
```bash
# Detén una API en su VM
# Por ejemplo, en VM2:
ssh carlos@192.168.122.20
docker stop api3  # o el comando correspondiente

# Desde el host, genera los logs
cd scripts
./generate-error-logs.sh
```

### 4. Verificar Logs Generados
```bash
cd scripts
./view-logs.sh
# O revisar directamente:
ls -lh ../logs/
cat ../logs/resumen.log
```

### 5. Usar en Documentación
Los logs se pueden copiar o referenciar en:
- `docs/operations/Evidencia_Pruebas.md`
- Manual Técnico
- Reportes de laboratorio

---

## Estructura de un Log

Cada archivo `.log` contiene:

```
=========================================
Prueba: [Nombre de la prueba]
URL: [Endpoint probado]
Fecha: [Timestamp]
=========================================

RESPUESTA:
[JSON response o mensaje de error]

Código HTTP: [200, 500, etc.]

=========================================
```

---

## Solución de Problemas

### Las APIs no responden
```bash
# Verificar estado de contenedores/servicios
ssh carlos@192.168.122.10
docker ps  # o el comando correspondiente

# Reiniciar APIs si es necesario
docker restart api1 api2
```

### Error de conectividad
```bash
# Verificar rutas de red
ip route
ping 192.168.122.10
ping 192.168.122.20

# Verificar firewall
sudo firewall-cmd --list-all
```

### Logs vacíos o sin datos
```bash
# Ejecutar pruebas manuales primero
curl -v http://192.168.122.10:8081/health

# Revisar que curl esté instalado
which curl
```

---

## Variables Importantes

Puedes modificar estas variables en los scripts:

- `LOGS_DIR`: Directorio donde se guardan los logs (default: `../logs`)
- `CARNET`: Tu número de carnet (default: `202300625`)
- IPs de las VMs:
  - VM1: `192.168.122.10` (API1, API2)
  - VM2: `192.168.122.20` (API3)

---

## Contribuir

Para agregar nuevas pruebas:

1. Edita `generate-logs.sh`
2. Usa la función `test_endpoint` con los parámetros:
   - Nombre descriptivo
   - URL del endpoint
   - Nombre del archivo log

Ejemplo:
```bash
test_endpoint \
    "Mi Nueva Prueba" \
    "http://192.168.122.10:8081/api1/endpoint" \
    "mi-prueba.log"
```
