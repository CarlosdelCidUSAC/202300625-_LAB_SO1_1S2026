# Guía Rápida: Generación de Logs

## ¿Qué se ha creado?

Se han generado automáticamente **10 archivos de logs** con las pruebas de las APIs:

### Logs Generados

```
logs/
├── api1-health.log          # Health check API1
├── api2-health.log          # Health check API2
├── api3-health.log          # Health check API3
├── api1-call-api2-ok.log    # API1 → API2 ✓
├── api1-call-api3-ok.log    # API1 → API3 ✓
├── api2-call-api1-ok.log    # API2 → API1 ✓
├── api2-call-api3-ok.log    # API2 → API3 ✓
├── api3-call-api1-ok.log    # API3 → API1 ✓
├── api3-call-api2-ok.log    # API3 → API2 ✓
└── resumen.log              # Resumen general
```

### Scripts Creados

```
scripts/
├── logs-manager.sh          # Script maestro (RECOMENDADO)
├── generate-logs.sh         # Genera logs exitosos
├── generate-error-logs.sh   # Genera logs de error
├── view-logs.sh            # Visualiza logs
├── clean-logs.sh           # Limpia logs
└── README.md               # Documentación completa
```

---

## Uso Rápido

### Opción 1: Script Interactivo (Recomendado)

```bash
cd scripts
./logs-manager.sh
```

Te mostrará un menú con todas las opciones:
1. Generar logs de pruebas
2. Generar logs de error
3. Ver logs
4. Ver resumen
5. Limpiar logs
6. Ayuda
7. Salir

### Opción 2: Scripts Individuales

```bash
# Generar todos los logs
cd scripts
./generate-logs.sh

# Ver los logs generados
./view-logs.sh

# Ver resumen rápido
cat ../logs/resumen.log
```

---

## Estado Actual

**Logs ya generados:** 10 archivos (ejecutados el 01/02/2026)

**NOTA IMPORTANTE:** 
Los logs actuales muestran que las APIs no estaban respondiendo cuando se ejecutó el script. 

Para obtener logs con datos reales:

1. **Asegúrate que las VMs estén activas:**
   ```bash
   ping -c 2 192.168.122.10  # VM1
   ping -c 2 192.168.122.20  # VM2
   ```

2. **Verifica que las APIs estén corriendo:**
   ```bash
   curl http://192.168.122.10:8081/health  # API1
   curl http://192.168.122.10:8082/health  # API2
   curl http://192.168.122.20:8083/health  # API3
   ```

3. **Regenera los logs:**
   ```bash
   cd scripts
   ./logs-manager.sh
   # Selecciona opción 1
   ```

---

## Próximos Pasos

### Para documentar en Evidencia_Pruebas.md:

1. **Inicia las APIs** en las VMs correspondientes

2. **Regenera los logs** con APIs funcionando:
   ```bash
   cd scripts
   ./generate-logs.sh
   ```

3. **Revisa los logs generados:**
   ```bash
   cd scripts
   ./view-logs.sh
   ```

4. **Opcionalmente, genera logs de error:**
   - Detén una API (ej: API3)
   - Ejecuta: `./generate-error-logs.sh`
   - Esto documenta el comportamiento cuando un servicio falla

5. **Los logs se pueden usar directamente** en la documentación o convertirlos a capturas de pantalla

---

## Ubicación de Archivos

- **Logs:** `/logs/`
- **Scripts:** `/scripts/`
- **Documentación:** `/docs/operations/Evidencia_Pruebas.md`
- **Guías:** 
  - `/scripts/README.md` - Guía completa de scripts
  - `/logs/README.md` - Info sobre logs

---

##  Útiles

```bash
# Ver todos los logs
ls -lh logs/

# Ver un log específico
cat logs/api1-health.log

# Ver resumen
cat logs/resumen.log

# Limpiar y regenerar
cd scripts
./clean-logs.sh
./generate-logs.sh

# Verificar APIs antes de generar logs
curl http://192.168.122.10:8081/health
curl http://192.168.122.10:8082/health
curl http://192.168.122.20:8083/health
```

---

## Características

Generación automática de logs  
Scripts interactivos fáciles de usar  
Documentación completa  
Logs organizados por tipo de prueba  
Resumen automático  
Manejo de errores documentado  
Visualización interactiva  

---

## Necesitas Ayuda?

1. Ejecuta el script maestro: `./scripts/logs-manager.sh`
2. Selecciona opción 6 (Ayuda)
3. O consulta: `scripts/README.md`

---

**Última actualización:** 01/02/2026  
**Carnet:** 202300625  
**Proyecto:** LAB SO1 - Comunicación entre APIs
