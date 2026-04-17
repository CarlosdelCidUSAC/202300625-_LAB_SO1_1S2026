package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	pb "go-client/proto"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type MilitaryReport struct {
	Country         string `json:"country" binding:"required"`
	WarplanesInAir  int32  `json:"warplanes_in_air"`
	WarshipsInWater int32  `json:"warships_in_water"`
	Timestamp       string `json:"timestamp" binding:"required"`
}

var (
	grpcClient   pb.WarReportServiceClient
	countriesMap = map[string]pb.Countries{
		"USA": pb.Countries_usa,
		"RUS": pb.Countries_rus,
		"CHN": pb.Countries_chn,
		"ESP": pb.Countries_esp,
		"GTM": pb.Countries_gtm,
	}
)

func main() {
	// 1. Conexión al Servidor gRPC (Deployment 2)
	grpcAddr := os.Getenv("GRPC_SERVER_ADDR")
	if grpcAddr == "" {
		grpcAddr = "localhost:50051"
	}

	conn, err := grpc.Dial(grpcAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("No se pudo conectar al servidor gRPC: %v", err)
	}
	defer conn.Close()
	grpcClient = pb.NewWarReportServiceClient(conn)

	// 2. Servidor REST
	r := gin.Default()

	// Endpoint de salud para Kubernetes
	r.GET("/health", func(c *gin.Context) {
		c.String(http.StatusOK, "OK")
	})

	// Endpoint principal de ingesta
	r.POST("/api/reports", handleReport)

	if err := r.Run(":8081"); err != nil {
		log.Fatalf("no se pudo iniciar el servidor REST: %v", err)
	}
}

func handleReport(c *gin.Context) {
	var report MilitaryReport
	if err := c.ShouldBindJSON(&report); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Normaliza el país para aceptar entradas como "esp" o "Esp".
	countryEnum, exists := countriesMap[strings.ToUpper(report.Country)]
	if !exists {
		countryEnum = pb.Countries_countries_unknown
	}

	// Llamada gRPC al Servidor
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	res, err := grpcClient.SendReport(ctx, &pb.WarReportRequest{
		Country:         countryEnum,
		WarplanesInAir:  report.WarplanesInAir,
		WarshipsInWater: report.WarshipsInWater,
		Timestamp:       report.Timestamp,
	})

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": res.Status})
}
