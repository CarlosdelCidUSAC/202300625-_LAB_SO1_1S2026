# Comunicación entre APIs - Especificaciones Detalladas

Este documento describe la comunicación entre las 3 APIs (API1, API2, API3) según los requerimientos del proyecto.

## Configuración General

### Variables Personalizadas
- **#CARNET**: `202300625` 
- **Formato de datos**: JSON
- **Protocolo**: REST/HTTP

### Configuración de Red
- **VM1**: 192.168.100.10 (API1:8081, API2:8082)
- **VM2**: 192.168.100.20 (API3:8083)
- **VM3**: 192.168.100.30 (ZOT Registry:5000)

## Endpoints Requeridos

### API1 (VM1 - Containerd)
```
GET /health
GET /api1/202300625/call-api2
GET /api1/202300625/call-api3
```

### API2 (VM1 - Containerd)
```
GET /health
GET /api2/202300625/call-api1
GET /api2/202300625/call-api3
```

### API3 (VM2 - Containerd)
```
GET /health
GET /api3/202300625/call-api1
GET /api3/202300625/call-api2
```

## Formatos de Respuesta JSON

### 1. Endpoint `/health`
```json
{
  "status": "UP",
  "message": "API# is Ready",
  "timestamp": "2025-01-31T14:30:00Z",
  "VM": 1,
  "carnet": "202300625"
}
```

**Campos:**
- `status`: Siempre "UP" cuando la API está funcionando
- `message`: "API1 is Ready", "API2 is Ready", "API3 is Ready"
- `timestamp`: Fecha y hora en formato ISO 8601
- `VM`: Número de VM (1 para API1/API2, 2 para API3)
- `carnet`: "202300625"

### 2. Endpoint de llamada exitosa `/api#/202300625/call-api#`
```json
{
  "apiname": "API#",
  "message": "The API# located on the VM# is working",
  "connection": true,
  "carnet": "202300625"
}
```

**Ejemplo para API2 llamando a API1 exitosamente:**
```json
{
  "apiname": "API1",
  "message": "The API1 located on the VM1 is working",
  "connection": true,
  "carnet": "202300625"
}
```

### 3. Endpoint de llamada con error `/api#/202300625/call-api#`
```json
{
  "apiname": "API#",
  "message": "ERROR: The API# located on the VM# is not working",
  "connection": false,
  "carnet": "202300625"
}
```

**Ejemplo para API2 llamando a API1 con error:**
```json
{
  "apiname": "API1",
  "message": "ERROR: The API1 located on the VM1 is not working",
  "connection": false,
  "carnet": "202300625"
}
```

## Flujo de Comunicación

### Ejemplo 1: API2 verifica estado de API1

1. **Usuario realiza solicitud:**
   ```
   GET http://192.168.100.10:8082/api2/202300625/call-api1
   ```

2. **API2 procesa la solicitud:**
   - Valida que el carnet en la URL sea "202300625"
   - Realiza llamada HTTP a `GET http://192.168.100.10:8081/health`
   - Espera respuesta de API1 (timeout: 5 segundos)

3. **API1 responde (si está funcionando):**
   ```json
   {
     "status": "UP",
     "message": "API1 is Ready",
     "timestamp": "2025-01-31T14:30:00Z",
     "VM": 1,
     "carnet": "202300625"
   }
   ```

4. **API2 analiza respuesta:**
   - Verifica que `status` sea "UP"
   - Verifica que `carnet` sea "202300625"

5. **API2 responde al usuario:**
   ```json
   {
     "apiname": "API1",
     "message": "The API1 located on the VM1 is working",
     "connection": true,
     "carnet": "202300625"
   }
   ```

### Ejemplo 2: API1 verifica estado de API3 (entre VMs diferentes)

1. **Usuario realiza solicitud:**
   ```
   GET http://192.168.100.10:8081/api1/202300625/call-api3
   ```

2. **API1 procesa la solicitud:**
   - Valida carnet
   - Realiza llamada HTTP a `GET http://192.168.100.20:8083/health`
   - Cruza de VM1 a VM2 a través de la red bridge

3. **API3 responde (si está funcionando):**
   ```json
   {
     "status": "UP",
     "message": "API3 is Ready",
     "timestamp": "2025-01-31T14:30:00Z",
     "VM": 2,
     "carnet": "202300625"
   }
   ```

4. **API1 responde al usuario:**
   ```json
   {
     "apiname": "API3",
     "message": "The API3 located on the VM2 is working",
     "connection": true,
     "carnet": "202300625"
   }
   ```

## Manejo de Errores

### Casos de error a considerar:

1. **API destino no responde:**
   - Timeout de conexión (5 segundos)
   - Respuesta con `connection: false`

2. **API destino responde con error HTTP:**
   - Código 4xx o 5xx
   - Respuesta con `connection: false`

3. **API destino responde con formato incorrecto:**
   - JSON inválido
   - Campos faltantes
   - Respuesta con `connection: false`

4. **Carnet incorrecto en la URL:**
   - Validar que el carnet en la ruta sea "202300625"
   - Responder con error HTTP 400 Bad Request

5. **API destino responde con status != "UP":**
   - Verificar campo `status` en respuesta `/health`
   - Si no es "UP", considerar como error

## Implementación en Go

### Estructuras de datos:
```go
type HealthResponse struct {
    Status    string `json:"status"`
    Message   string `json:"message"`
    Timestamp string `json:"timestamp"`
    VM        int    `json:"VM"`
    Carnet    string `json:"carnet"`
}

type APICallResponse struct {
    APIName    string `json:"apiname"`
    Message    string `json:"message"`
    Connection bool   `json:"connection"`
    Carnet     string `json:"carnet"`
}
```

### Función para verificar salud de otra API:
```go
func checkAPIHealth(apiURL string) (bool, error) {
    client := &http.Client{Timeout: 5 * time.Second}
    resp, err := client.Get(apiURL + "/health")
    if err != nil {
        return false, err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return false, fmt.Errorf("status code: %d", resp.StatusCode)
    }
    
    body, err := io.ReadAll(resp.Body)
    if err != nil {
        return false, err
    }
    
    var healthResp HealthResponse
    if err := json.Unmarshal(body, &healthResp); err != nil {
        return false, err
    }
    
    return healthResp.Status == "UP" && healthResp.Carnet == "202300625", nil
}
```

## Pruebas de Comunicación

### Comandos curl para probar:

```bash
# Verificar salud de API1
curl http://192.168.100.10:8081/health

# API2 llama a API1
curl http://192.168.100.10:8082/api2/202300625/call-api1

# API1 llama a API3 (entre VMs)
curl http://192.168.100.10:8081/api1/202300625/call-api3

# API3 llama a API2 (entre VMs)
curl http://192.168.100.20:8083/api3/202300625/call-api2
```

## Diagrama de Comunicación

```
Usuario
   │
   ▼
[ API2:8082 ]───HTTP Call───▶[ API1:8081 ] (misma VM)
   │
   └───────────HTTP Call───▶[ API3:8083 ] (VM diferente)
   
Usuario
   │
   ▼
[ API1:8081 ]───HTTP Call───▶[ API2:8082 ] (misma VM)
   │
   └───────────HTTP Call───▶[ API3:8083 ] (VM diferente)
   
Usuario
   │
   ▼
[ API3:8083 ]───HTTP Call───▶[ API1:8081 ] (VM diferente)
   │
   └───────────HTTP Call───▶[ API2:8082 ] (VM diferente)
```