FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN go build -o go-client main.go

FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/go-client .
EXPOSE 8081
CMD ["./go-client"]