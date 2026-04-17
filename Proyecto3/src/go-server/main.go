package main

import (
	"context"
	"encoding/json"
	"log"
	"net"
	"os"

	pb "go-server/proto"

	amqp "github.com/rabbitmq/amqp091-go"
	"google.golang.org/grpc"
)

type server struct {
	pb.UnimplementedWarReportServiceServer
	rabbitConn *amqp.Connection
	rabbitCh   *amqp.Channel
	queueName  string
}

// Estructura para enviar a RabbitMQ en formato JSON
type RabbitMessage struct {
	Country         string `json:"country"`
	WarplanesInAir  int32  `json:"warplanes_in_air"`
	WarshipsInWater int32  `json:"warships_in_water"`
	Timestamp       string `json:"timestamp"`
}

func (s *server) SendReport(ctx context.Context, req *pb.WarReportRequest) (*pb.WarReportResponse, error) {
	// Convertir Enum a String para el JSON
	countryStr := req.Country.String()

	msg := RabbitMessage{
		Country:         countryStr,
		WarplanesInAir:  req.WarplanesInAir,
		WarshipsInWater: req.WarshipsInWater,
		Timestamp:       req.Timestamp,
	}

	body, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Error al convertir a JSON: %v", err)
		return &pb.WarReportResponse{Status: "Error"}, err
	}

	// Publicar mensaje en RabbitMQ
	err = s.rabbitCh.PublishWithContext(ctx,
		"",          // exchange
		s.queueName, // routing key (nombre de la cola)
		false,       // mandatory
		false,       // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		})

	if err != nil {
		log.Printf("Error al publicar en RabbitMQ: %v", err)
		return &pb.WarReportResponse{Status: "Error"}, err
	}

	log.Printf("Reporte publicado en RabbitMQ: %s", countryStr)
	return &pb.WarReportResponse{Status: "Success"}, nil
}

func main() {
	// 1. Configuración de RabbitMQ
	rabbitURL := os.Getenv("RABBITMQ_URL")
	if rabbitURL == "" {
		rabbitURL = "amqp://guest:guest@localhost:5672/"
	}

	queueName := os.Getenv("RABBITMQ_QUEUE")
	if queueName == "" {
		queueName = "war_reports_queue"
	}

	conn, err := amqp.Dial(rabbitURL)
	if err != nil {
		log.Fatalf("No se pudo conectar a RabbitMQ: %v", err)
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		log.Fatalf("No se pudo abrir un canal en RabbitMQ: %v", err)
	}
	defer ch.Close()

	_, err = ch.QueueDeclare(
		queueName,
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)
	if err != nil {
		log.Fatalf("No se pudo declarar la cola: %v", err)
	}

	// 2. Configuración del Servidor gRPC
	grpcPort := os.Getenv("GRPC_PORT")
	if grpcPort == "" {
		grpcPort = "50051"
	}

	port := ":" + grpcPort
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("Fallo al escuchar en el puerto %s: %v", port, err)
	}

	s := grpc.NewServer()
	pb.RegisterWarReportServiceServer(s, &server{
		rabbitConn: conn,
		rabbitCh:   ch,
		queueName:  queueName,
	})

	log.Printf("Servidor gRPC + RabbitMQ Writer escuchando en %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Fallo al servir: %v", err)
	}
}
