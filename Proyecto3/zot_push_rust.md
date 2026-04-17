# Ejecucion de Zot y Push de Imagen Rust (Proyecto3)

Este documento describe la ejecucion del registro Zot en Docker, el etiquetado de la imagen local `rust-api:local`, y el push de la imagen al registro en el puerto `5000`.

---

## 1. Contexto

Se realizo el proceso desde el proyecto:

```bash
cd /home/carlos/Escritorio/Sopes1/202300625-_LAB_SO1_1S2026/Proyecto3
```

Se contaba con la imagen local previamente compilada:

```bash
docker build -t rust-api:local .
```

---

## 2. Ejecutar Zot

Comando solicitado:

```bash
docker run -d -p 5000:5000 --name zot-registry ghcr.io/project-zot/zot-linux-amd64:latest
```

Estado observado durante la ejecucion:

- El contenedor `zot-registry` ya existia y estaba en ejecucion.
- Se confirmo con:

```bash
docker ps -a --filter name=zot-registry
```

Salida relevante:

```text
NAMES
zot-registry
```

---

## 3. Etiquetar y Subir Imagen Rust

Comandos solicitados (para VM en GCP):

```bash
# Reemplaza <IP_VM_ZOT> por la IP de tu instancia en GCP
docker tag rust-api:local <IP_VM_ZOT>:5000/rust-api:v1
docker push <IP_VM_ZOT>:5000/rust-api:v1
```

Comandos ejecutados en esta sesion (registro local):

```bash
docker tag rust-api:local 127.0.0.1:5000/rust-api:v1
docker push 127.0.0.1:5000/rust-api:v1
```

Resultado del push:

```text
The push refers to repository [127.0.0.1:5000/rust-api]
v1: digest: sha256:2186f2866602a9c9d0b3353e578b2c025d112560e5bf77abc19d43b5abce68d1 size: 1187
```

Estado: imagen publicada correctamente en Zot con tag `v1`.

---

## 4. Verificaciones Rapidas

Verificar que Zot sigue activo:

```bash
docker ps --filter name=zot-registry
```

Consultar catalogo del registro:

```bash
curl http://127.0.0.1:5000/v2/_catalog
```

Consultar tags del repositorio:

```bash
curl http://127.0.0.1:5000/v2/rust-api/tags/list
```

---

## 5. Uso en GCP (Referencia)

Para usar una VM externa en GCP con Zot:

1. Reemplazar `127.0.0.1` por la IP externa de la VM.
2. Asegurar apertura del puerto `5000` en firewall.
3. Si Zot esta con TLS, usar URL `https://<IP_VM_ZOT>:5000` y configurar cliente segun certificados.

Ejemplo:

```bash
docker tag rust-api:local <IP_VM_ZOT>:5000/rust-api:v1
docker push <IP_VM_ZOT>:5000/rust-api:v1
```

---

## 6. Comandos Utiles

```bash
# Ver imagen local
docker images | grep rust-api

# Ver contenedor Zot
docker ps -a --filter name=zot-registry

# Reiniciar Zot
docker restart zot-registry
```

---

*Ultima actualizacion: 15/04/2026*  
*Proyecto: Proyecto3_202300625*
