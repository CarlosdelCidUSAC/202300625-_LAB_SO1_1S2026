FROM alpine:latest

# Argumento para saber qué binario copiar (se pasa al construir)
ARG BIN_PATH

WORKDIR /app

# Copiamos el binario desde la ruta relativa del host
COPY ${BIN_PATH} ./app_executable

RUN chmod +x ./app_executable

ENTRYPOINT ["./app_executable"]