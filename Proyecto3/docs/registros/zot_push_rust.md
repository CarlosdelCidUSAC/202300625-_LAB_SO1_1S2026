# Ejecucion de Zot y Push de Imagenes (Proyecto3)

Documento actualizado con lo ejecutado en la VM externa de Zot y el estado de integracion con GKE.

---

## 1. Objetivo

Publicar imagenes del proyecto en Zot remoto y validar consumo desde Kubernetes.

Registro objetivo:

- Host: 35.237.182.41
- Puerto: 5000
- URL: https://35.237.182.41:5000

---

## 2. Hallazgo inicial

El catalogo respondia vacio:

```bash
curl -sS -k https://35.237.182.41:5000/v2/_catalog
{"repositories":[]}
```

---

## 3. Build y push realizados

Se creo script para build/push de imagenes:

```bash
./docker/push-zot-images.sh 35.237.182.41:5000
```

Durante la publicacion, docker push presento error TLS por certificado self-signed. Se utilizo skopeo como mecanismo de push:

```bash
skopeo copy --dest-tls-verify=false \
	docker-daemon:35.237.182.41:5000/rust-api:v2 \
	docker://35.237.182.41:5000/rust-api:v2
```

Misma estrategia para:

- go-client:v1
- go-server:v1
- go-receiver:v1
- rabbitmq-consumer:v1
- rust-api:v2

---

## 4. Verificacion de catalogo

Despues del push:

```bash
curl -sS -k https://35.237.182.41:5000/v2/_catalog
```

Resultado:

```json
{"repositories":["go-client","go-receiver","go-server","rabbitmq-consumer","rust-api"]}
```

---

## 5. Ajuste de certificado en VM de Zot

Se regenero certificado de Zot agregando Subject Alternative Name para la IP publica:

- CN: zot-registry-vm
- SAN: DNS:zot-registry-vm, IP Address:35.237.182.41

Esto resolvio el error de IP sin SAN.

---

## 6. Resultado al consumir desde GKE

Aunque el catalogo y push quedaron correctos, los pods en GKE fallaron al hacer pull desde Zot con:

```text
x509: certificate signed by unknown authority
```

Accion tomada:

- Se hizo rollback de deployments para restaurar estado estable.
- El flujo principal siguio funcionando por Gateway con respuesta 201.

---

## 7. Estado final (19/04/2026)

- Zot remoto poblado con todas las imagenes del proyecto.
- Integracion runtime GKE -> Zot pendiente por confianza de CA en nodos.
- Sistema operativo restaurado usando revision previa estable de deployments.

---

## 8. Siguiente paso recomendado

Para cumplir consumo de imagenes desde Zot en Kubernetes sin errores de pull:

1. Emitir certificado de Zot con CA publica confiable por los nodos GKE, o
2. Configurar confianza de CA privada en los nodos (opcion mas compleja).

---

Ultima actualizacion: 19/04/2026
Proyecto: Proyecto3_202300625
