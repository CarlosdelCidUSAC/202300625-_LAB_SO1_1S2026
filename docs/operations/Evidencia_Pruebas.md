# Evidencia de Pruebas

Este documento consolida evidencia de funcionamiento para los endpoints y la comunicación entre APIs.

---

## 1. Endpoints `/health`

### API1
- URL: `http://192.168.122.10:8081/health`
- Evidencia (captura o log):
  - Inserta captura en `docs/operations/assets/api1-health.png`

### API2
- URL: `http://192.168.122.10:8082/health`
- Evidencia (captura o log):
  - Inserta captura en `docs/operations/assets/api2-health.png`

### API3
- URL: `http://192.168.122.20:8083/health`
- Evidencia (captura o log):
  - Inserta captura en `docs/operations/assets/api3-health.png`

---

## 2. Comunicación exitosa entre APIs

### API2 -> API1 (connection: true)
- URL: `http://192.168.122.10:8082/api2/202300625/call-api1`
- Evidencia requerida: JSON con `connection: true`.
- Captura o log: `docs/operations/assets/api2-call-api1-ok.png`

### API1 -> API3 (connection: true)
- URL: `http://192.168.122.10:8081/api1/202300625/call-api3`
- Evidencia requerida: JSON con `connection: true`.
- Captura o log: `docs/operations/assets/api1-call-api3-ok.png`

### API3 -> API2 (connection: true)
- URL: `http://192.168.122.20:8083/api3/202300625/call-api2`
- Evidencia requerida: JSON con `connection: true`.
- Captura o log: `docs/operations/assets/api3-call-api2-ok.png`

---

## 3. Manejo de errores (nodo caído)

1. Detener temporalmente una API en su VM.
2. Ejecutar la llamada desde otra API.
3. Guardar evidencia del JSON con `connection: false`.

### Ejemplo: API1 -> API3 (API3 detenido)
- URL: `http://192.168.122.10:8081/api1/202300625/call-api3`
- Evidencia requerida: JSON con `connection: false`.
- Captura o log: `docs/operations/assets/api1-call-api3-error.png`

---

## 4. Logs

### Generación Automática de Logs

Se han creado scripts automatizados para generar todos los logs de pruebas:

#### Generar logs de pruebas exitosas:
```bash
cd scripts
./generate-logs.sh
```

#### Generar logs de pruebas de error:
```bash
cd scripts
./generate-error-logs.sh
```

#### Ver logs generados:
```bash
cd scripts
./view-logs.sh
```

### Logs Generados

Los siguientes archivos se crean automáticamente en `logs/`:

**Health Checks:**
- `logs/api1-health.log` - Estado de API1
- `logs/api2-health.log` - Estado de API2
- `logs/api3-health.log` - Estado de API3

**Comunicación Exitosa:**
- `logs/api1-call-api2-ok.log` - API1 → API2 ✓
- `logs/api1-call-api3-ok.log` - API1 → API3 ✓
- `logs/api2-call-api1-ok.log` - API2 → API1 ✓
- `logs/api2-call-api3-ok.log` - API2 → API3 ✓
- `logs/api3-call-api1-ok.log` - API3 → API1 ✓
- `logs/api3-call-api2-ok.log` - API3 → API2 ✓

**Manejo de Errores:**
- `logs/api1-call-api3-error.log` - API1 → API3 (API3 caída) ✗
- `logs/api2-call-api1-error.log` - API2 → API1 (API1 caída) ✗
- `logs/api3-call-api2-error.log` - API3 → API2 (API2 caída) ✗

**Resumen:**
- `logs/resumen.log` - Resumen general de todas las pruebas

### Consultar Documentación

Para más información sobre los scripts de logs:
- Ver `scripts/README.md` - Guía completa de uso de scripts
- Ver `logs/README.md` - Información sobre estructura de logs

---

## 5. Checklist de evidencia

- [ ] `/health` API1
- [ ] `/health` API2
- [ ] `/health` API3
- [ ] API2 -> API1 (connection: true)
- [ ] API1 -> API3 (connection: true)
- [ ] API3 -> API2 (connection: true)
- [ ] Error controlado con `connection: false`
