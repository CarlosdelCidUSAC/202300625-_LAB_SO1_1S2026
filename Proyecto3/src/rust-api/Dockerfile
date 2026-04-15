# src/rust-api/Dockerfile

# Etapa de construcción
FROM rust:1.94-slim as builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY . .
RUN cargo build --release

# Etapa de ejecución (imagen final ligera)
FROM debian:bookworm-slim
WORKDIR /app
# Instalar certificados SSL necesarios para reqwest/HTTPS si aplicara
RUN apt-get update && apt-get install -y ca-certificates libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/rust-api /usr/local/bin/rust-api

EXPOSE 8080
CMD ["rust-api"]