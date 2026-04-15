# Compilacion y Ajustes de la API REST en Rust (Proyecto3)

Este documento describe el proceso aplicado para compilar la imagen Docker de la API REST en Rust, los problemas encontrados durante el build, y las correcciones realizadas en el Dockerfile para lograr una compilacion exitosa.

---

## 1. Contexto Inicial

Se trabajo sobre el directorio del servicio Rust:

```bash
cd src/rust-api
```

La imagen se intento compilar con:

```bash
docker build -t rust-api:local .
```

---

## 2. Dockerfile Original

El archivo inicial en [src/rust-api/Dockerfile](src/rust-api/Dockerfile) tenia dos etapas:

1. Build con `rust:1.77-slim`
2. Runtime con `debian:bookworm-slim`

Comportamiento original:

- Compilaba con `cargo build --release` en la etapa builder.
- Copiaba el binario final a `/usr/local/bin/rust-api`.

---

## 3. Problemas Detectados en la Compilacion

### 3.1 Error por Edition 2024 (Rust/Cargo desactualizado)

En el primer intento de build, Cargo fallo al resolver dependencias recientes (ej. `hashbrown`) porque requerian `edition2024`, no soportada por Cargo 1.77.

**Error clave detectado:**

```text
feature `edition2024` is required
The package requires the Cargo feature called `edition2024`
```

### 3.2 Error de OpenSSL y pkg-config

Despues de actualizar Rust, el build fallo en `openssl-sys` por ausencia de utilidades/librerias del sistema para resolver OpenSSL durante la compilacion.

**Error clave detectado:**

```text
Could not find openssl via pkg-config
The pkg-config command could not be found
```

---

## 4. Correcciones Aplicadas

Se actualizaron las imagenes y paquetes del Dockerfile para resolver ambos errores.

### 4.1 Actualizacion de la imagen Rust

Se cambio:

```dockerfile
FROM rust:1.77-slim as builder
```

por:

```dockerfile
FROM rust:1.94-slim as builder
```

### 4.2 Dependencias de compilacion para OpenSSL

Se agrego en la etapa builder:

```dockerfile
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
```

### 4.3 Dependencias runtime para librerias SSL

Se ajusto la etapa final para incluir `libssl3` junto a certificados:

```dockerfile
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
```

---

## 5. Dockerfile Final (Resumen)

Archivo final en [src/rust-api/Dockerfile](src/rust-api/Dockerfile):

```dockerfile
# Etapa de construccion
FROM rust:1.94-slim as builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY . .
RUN cargo build --release

# Etapa de ejecucion (imagen final ligera)
FROM debian:bookworm-slim
WORKDIR /app
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/rust-api /usr/local/bin/rust-api

EXPOSE 8080
CMD ["rust-api"]
```

---

## 6. Resultado de la Compilacion

Comando ejecutado:

```bash
docker build -t rust-api:local .
```

Resultado final:

```text
Successfully built 2186f2866602
Successfully tagged rust-api:local
```

Estado: compilacion exitosa de la imagen local `rust-api:local`.

---

## 7. Verificacion Rapida Recomendada

Para ejecutar el contenedor localmente:

```bash
docker run --rm -p 8080:8080 rust-api:local
```

Para validar que la imagen existe:

```bash
docker images | grep rust-api
```

---

## 8. Troubleshooting Aplicado

### 8.1 Si vuelve a aparecer error de edition2024

- Verificar que la imagen builder use Rust moderno (>= 1.85 recomendado para ecosystema actual).
- Confirmar que no se este usando cache viejo:

```bash
docker build --no-cache -t rust-api:local .
```

### 8.2 Si falla por OpenSSL en build

- Confirmar presencia de `pkg-config` y `libssl-dev` en la etapa builder.
- Revisar si alguna dependencia fuerza backend TLS nativo.

### 8.3 Si el binario falla al arrancar en runtime

- Verificar libreria `libssl3` en la imagen final.
- Validar que el binario copiado exista en `/usr/local/bin/rust-api`.

---

## 9. Referencias y Comandos Utiles

### Comandos usados durante la correccion

```bash
cd src/rust-api
docker build -t rust-api:local .
```

### Archivos modificados

- [src/rust-api/Dockerfile](src/rust-api/Dockerfile)
- [api_rest_rust.md](api_rest_rust.md)

---

*Ultima actualizacion: 15/04/2026*  
*Proyecto: Proyecto3_202300625*
