FROM alpine:latest

# Contenedor que consume alto consumo de CPU
# Ejecuta cálculos matemáticos infinitos
RUN apk add --no-cache bc

CMD ["/bin/sh", "-c", "while true; do echo '2^20' | bc > /dev/null; sleep 2; done"]
