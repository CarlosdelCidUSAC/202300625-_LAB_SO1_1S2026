FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o rabbitmq-consumer main.go

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/rabbitmq-consumer .
CMD ["./rabbitmq-consumer"]