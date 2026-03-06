package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/redis/go-redis/v9"
	"time"
)

var ctx = context.Background()
var rdb *redis.Client

func iniciarConexionValkey() {
	rdb = redis.NewClient(&redis.Options{
		Addr:     "localhost:6379", // Puerto expuesto en tu docker-compose
		Password: "",               // Sin contraseña por defecto
		DB:       0,
	})
	fmt.Println("Conexión a Valkey inicializada.")
}

func guardarEnValkey(captura CapturaTelemetria) {
	// 1. Convertir la estructura a JSON
	jsonData, err := json.Marshal(captura)
	if err != nil {
		fmt.Println("Error al serializar a JSON:", err)
		return
	}

	// 2. Generar una clave única basada en el timestamp
	key := fmt.Sprintf("telemetria:%d", captura.Timestamp)

	// 3. Guardar en Valkey con un tiempo de expiración opcional (ej. 1 hora)
	err = rdb.Set(ctx, key, jsonData, 1*time.Hour).Err()
	if err != nil {
		fmt.Println("Error al guardar en Valkey:", err)
	} else {
		fmt.Println("Datos guardados en Valkey bajo la clave:", key)
	}
}