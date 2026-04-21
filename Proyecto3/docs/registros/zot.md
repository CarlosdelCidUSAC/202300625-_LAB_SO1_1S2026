# Registro Zot en VM externa (actualizado 19/04/2026)

## 1. VM y endpoint actual

- VM: zot-registry-vm
- Zona: us-east1-d
- IP externa actual: 35.237.182.41
- Endpoint: https://35.237.182.41:5000

Verificacion basica:

```bash
curl -sS -k https://35.237.182.41:5000/v2/_catalog
```

Catalogo actual:

```json
{"repositories":["go-client","go-receiver","go-server","rabbitmq-consumer","rust-api"]}
```

## 2. Comportamiento HTTP/HTTPS

- Zot esta sirviendo en HTTPS.
- Si se usa HTTP contra el puerto 5000, responde: Client sent an HTTP request to an HTTPS server.

## 3. Certificado TLS

Se regenero certificado de Zot con SAN para evitar error por IP sin SAN:

- Subject: CN=zot-registry-vm
- SAN: DNS:zot-registry-vm, IP Address:35.237.182.41

Validacion:

```bash
echo | openssl s_client -connect 35.237.182.41:5000 -servername 35.237.182.41 2>/dev/null \
| openssl x509 -noout -subject -ext subjectAltName
```

## 4. Resultado de integracion con GKE

- El registro responde y el catalogo contiene imagenes.
- El pull desde nodos GKE falla con x509 certificate signed by unknown authority al usar imagenes 35.237.182.41:5000/*.
- Por este motivo, los deployments se revirtieron a revision estable (imagenes en gcr.io) para mantener el sistema operativo.

## 5. Estado funcional del flujo principal

Luego del rollback, se valido el flujo por Gateway:

```bash
curl -sS -o /tmp/gw_resp.txt -w '%{http_code}\n' \
  -X POST http://34.110.235.118/grpc-202300625 \
  -H 'Content-Type: application/json' \
  -d '{"country":"ESP","warplanes_in_air":7,"warships_in_water":3,"timestamp":"2026-04-19T20:25:00Z"}'
cat /tmp/gw_resp.txt
```

Respuesta observada:

```text
201
{"message":"Report forwarded to Go service successfully","status":"success"}
```

## 6. Nota tecnica

Para usar Zot como origen de imagenes en GKE de forma estable, se requiere que los nodos confien en la CA del certificado de Zot o usar un certificado emitido por CA publica confiable.
