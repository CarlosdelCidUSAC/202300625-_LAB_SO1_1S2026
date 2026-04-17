package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/redis/go-redis/v9"
)

// Estructura del mensaje esperado desde RabbitMQ
type MilitaryReport struct {
	Country         string `json:"country"`
	WarplanesInAir  int32  `json:"warplanes_in_air"`
	WarshipsInWater int32  `json:"warships_in_water"`
	Timestamp       string `json:"timestamp"`
}

var ctx = context.Background()

const (
	defaultValkeyAddr     = "localhost:6379"
	defaultRabbitURL      = "amqp://guest:guest@localhost:5672/"
	defaultQueueName      = "war_reports_queue"
	defaultPrefetchCount  = 25
	defaultRetrySeconds   = 5
	defaultTimeSeriesSize = 2000
)

var validCountries = map[string]struct{}{
	"USA": {},
	"RUS": {},
	"CHN": {},
	"ESP": {},
	"GTM": {},
}

func main() {
	valkeyAddr := getEnv("VALKEY_ADDR", defaultValkeyAddr)
	queueName := getEnv("RABBITMQ_QUEUE", defaultQueueName)
	prefetchCount := getEnvAsInt("RABBITMQ_PREFETCH", defaultPrefetchCount)
	retrySeconds := getEnvAsInt("RETRY_SECONDS", defaultRetrySeconds)
	timeSeriesMaxLen := getEnvAsInt("TIMESERIES_MAXLEN", defaultTimeSeriesSize)

	valkeyClient := redis.NewClient(&redis.Options{Addr: valkeyAddr})
	for {
		if err := valkeyClient.Ping(ctx).Err(); err != nil {
			log.Printf("Valkey no disponible (%v), reintentando en %ds...", err, retrySeconds)
			time.Sleep(time.Duration(retrySeconds) * time.Second)
			continue
		}
		break
	}
	log.Println("Conectado exitosamente a Valkey")

	for {
		err := consumeFromRabbit(valkeyClient, queueName, prefetchCount, timeSeriesMaxLen)
		if err != nil {
			log.Printf("Consumo detenido (%v). Reintentando en %ds...", err, retrySeconds)
		}
		time.Sleep(time.Duration(retrySeconds) * time.Second)
	}
}

// Función para almacenar las métricas necesarias para Grafana en Valkey
func processAndStore(db *redis.Client, report MilitaryReport, timeSeriesMaxLen int) error {
	// 1. Guardar el evento crudo en una lista para la serie temporal del país
	eventJSON, err := json.Marshal(report)
	if err != nil {
		return fmt.Errorf("error serializando reporte: %w", err)
	}

	timeSeriesKey := fmt.Sprintf("timeseries:%s", report.Country)
	reportsTotalKey := fmt.Sprintf("total_reports:%s", report.Country)
	pipe := db.TxPipeline()

	pipe.RPush(ctx, timeSeriesKey, eventJSON)
	if timeSeriesMaxLen > 0 {
		pipe.LTrim(ctx, timeSeriesKey, -int64(timeSeriesMaxLen), -1)
	}

	// 2. Actualizar el Top de Países con más aviones (Sorted Set)
	pipe.ZIncrBy(ctx, "top_countries_warplanes", float64(report.WarplanesInAir), report.Country)

	// 3. Actualizar el Top de Países con más barcos (Sorted Set)
	pipe.ZIncrBy(ctx, "top_countries_warships", float64(report.WarshipsInWater), report.Country)

	// 4. Contador total de reportes recibidos por país
	pipe.Incr(ctx, reportsTotalKey)

	// 5. Histogramas para calcular moda en Grafana
	pipe.HIncrBy(ctx, "mode_warplanes", strconv.Itoa(int(report.WarplanesInAir)), 1)
	pipe.HIncrBy(ctx, "mode_warships", strconv.Itoa(int(report.WarshipsInWater)), 1)

	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("error guardando datos en Valkey: %w", err)
	}

	log.Printf("Procesado y guardado en Valkey: País %s | Aviones: %d | Barcos: %d",
		report.Country, report.WarplanesInAir, report.WarshipsInWater)
	return nil
}

func consumeFromRabbit(db *redis.Client, queueName string, prefetchCount int, timeSeriesMaxLen int) error {
	rabbitURL := getEnv("RABBITMQ_URL", defaultRabbitURL)

	conn, err := amqp.Dial(rabbitURL)
	if err != nil {
		return fmt.Errorf("no se pudo conectar a RabbitMQ: %w", err)
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		return fmt.Errorf("no se pudo abrir canal en RabbitMQ: %w", err)
	}
	defer ch.Close()

	_, err = ch.QueueDeclare(
		queueName,
		true,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		return fmt.Errorf("fallo al declarar cola %s: %w", queueName, err)
	}

	if err := ch.Qos(prefetchCount, 0, false); err != nil {
		return fmt.Errorf("fallo configurando prefetch=%d: %w", prefetchCount, err)
	}

	msgs, err := ch.Consume(
		queueName,
		"",
		false,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		return fmt.Errorf("fallo al registrar consumidor: %w", err)
	}

	log.Printf("Consumer iniciado. Cola=%s, prefetch=%d", queueName, prefetchCount)
	for d := range msgs {
		report, err := decodeReport(d.Body)
		if err != nil {
			log.Printf("Mensaje inválido descartado: %v", err)
			_ = d.Ack(false)
			continue
		}

		if err := processAndStore(db, report, timeSeriesMaxLen); err != nil {
			log.Printf("Error almacenando en Valkey: %v", err)
			_ = d.Nack(false, true)
			continue
		}

		if err := d.Ack(false); err != nil {
			log.Printf("Error al confirmar mensaje: %v", err)
		}
	}

	return fmt.Errorf("canal de consumo cerrado")
}

func decodeReport(body []byte) (MilitaryReport, error) {
	var report MilitaryReport
	if err := json.Unmarshal(body, &report); err != nil {
		return report, fmt.Errorf("error decodificando JSON: %w", err)
	}

	report.Country = strings.ToUpper(strings.TrimSpace(report.Country))
	if _, ok := validCountries[report.Country]; !ok {
		return report, fmt.Errorf("país inválido: %s", report.Country)
	}

	if report.WarplanesInAir < 0 || report.WarplanesInAir > 50 {
		return report, fmt.Errorf("warplanes_in_air fuera de rango: %d", report.WarplanesInAir)
	}

	if report.WarshipsInWater < 0 || report.WarshipsInWater > 30 {
		return report, fmt.Errorf("warships_in_water fuera de rango: %d", report.WarshipsInWater)
	}

	return report, nil
}

func getEnv(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func getEnvAsInt(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	parsed, err := strconv.Atoi(value)
	if err != nil {
		log.Printf("Valor inválido en %s=%q, usando fallback=%d", key, value, fallback)
		return fallback
	}

	if parsed <= 0 {
		log.Printf("Valor no positivo en %s=%q, usando fallback=%d", key, value, fallback)
		return fallback
	}

	return parsed
}
