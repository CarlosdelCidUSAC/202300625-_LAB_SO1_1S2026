# Logs del Proyecto

Este directorio contiene los logs de pruebas de las APIs del laboratorio.

## Estructura de Logs

### Logs de Health Checks
- `api1-health.log` - Estado de salud de API1
- `api2-health.log` - Estado de salud de API2
- `api3-health.log` - Estado de salud de API3

### Logs de Comunicación Exitosa
- `api1-call-api2-ok.log` - API1 llama a API2 exitosamente
- `api1-call-api3-ok.log` - API1 llama a API3 exitosamente
- `api2-call-api1-ok.log` - API2 llama a API1 exitosamente
- `api2-call-api3-ok.log` - API2 llama a API3 exitosamente
- `api3-call-api1-ok.log` - API3 llama a API1 exitosamente
- `api3-call-api2-ok.log` - API3 llama a API2 exitosamente

### Logs de Manejo de Errores
- `api1-call-api3-error.log` - API1 intenta llamar a API3 (caída)
- `api2-call-api1-error.log` - API2 intenta llamar a API1 (caída)
- `api3-call-api2-error.log` - API3 intenta llamar a API2 (caída)

### Resumen
- `resumen.log` - Resumen general de todas las pruebas

## Cómo Generar los Logs

### Logs Normales (APIs funcionando)
```bash
cd scripts
./generate-logs.sh
```

### Logs de Error (APIs caídas)
```bash
cd scripts
./generate-error-logs.sh
```

## Prerrequisitos

1. Todas las VMs deben estar funcionando
2. Las APIs deben estar desplegadas y corriendo
3. La red entre VMs debe estar configurada correctamente

## Verificar Antes de Generar Logs

```bash
# Verificar conectividad
ping -c 2 192.168.122.10  # VM1
ping -c 2 192.168.122.20  # VM2

# Verificar APIs
curl http://192.168.122.10:8081/health  # API1
curl http://192.168.122.10:8082/health  # API2
curl http://192.168.122.20:8083/health  # API3
```

## Formato de Logs

Cada log contiene:
- Fecha y hora de la prueba
- URL del endpoint probado
- Respuesta completa (JSON)
- Código de estado HTTP
- Información de conexión

## Uso en Documentación

Los logs generados se pueden usar en:
- [Evidencia de Pruebas](../docs/operations/Evidencia_Pruebas.md)
- Manual Técnico
- Reportes de funcionamiento
