package storage

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
	"proyecto2-daemon-202300625/internal/parser"
)

// ValkeyClient encapsula la conexión y operaciones con Valkey/Redis
type ValkeyClient struct {
	client *redis.Client
	ctx    context.Context
}

// NewValkeyClient crea una nueva conexión a Valkey
func NewValkeyClient(host, port string) (*ValkeyClient, error) {
	addr := fmt.Sprintf("%s:%s", host, port)
	
	client := redis.NewClient(&redis.Options{
		Addr: addr,
		DB:   0,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verificar conexión
	_, err := client.Ping(ctx).Result()
	if err != nil {
		return nil, fmt.Errorf("error conectando a Valkey en %s: %v", addr, err)
	}

	return &ValkeyClient{
		client: client,
		ctx:    context.Background(),
	}, nil
}

// StoreTelemetry almacena una captura de telemetría en Valkey
func (v *ValkeyClient) StoreTelemetry(captura *parser.CapturaTelemetria) error {
	timestamp := time.Now().Unix()
	
	// 1. Almacenar métricas de memoria en time series
	pipe := v.client.Pipeline()
	
	// Métricas de memoria actuales (últimas)
	pipe.HSet(v.ctx, "metrics:memory:current", map[string]interface{}{
		"timestamp": timestamp,
		"total":     captura.Memoria.TotalRAM,
		"used":      captura.Memoria.UsoRAM,
		"free":      captura.Memoria.LibreRAM,
	})
	
	// Time series de memoria (para gráficos históricos)
	pipe.ZAdd(v.ctx, "metrics:memory:history", redis.Z{
		Score: float64(timestamp),
		Member: fmt.Sprintf("%d:%d:%d", captura.Memoria.TotalRAM, captura.Memoria.UsoRAM, captura.Memoria.LibreRAM),
	})
	
	// Limpiar datos antiguos (mantener últimas 1000 entradas)
	pipe.ZRemRangeByRank(v.ctx, "metrics:memory:history", 0, -1001)
	
	// 2. Almacenar métricas de contenedores para Top 5
	// Limpiar lista anterior de contenedores activos
	pipe.Del(v.ctx, "metrics:containers:ram:top")
	pipe.Del(v.ctx, "metrics:containers:cpu:top")
	
	// Procesar solo procesos de contenedores
	for _, proc := range captura.Procesos {
		if strings.Contains(proc.ComandoID, "container:") {
			// Top RAM (sorted set por consumo RAM)
			pipe.ZAdd(v.ctx, "metrics:containers:ram:top", redis.Z{
				Score:  proc.PorcentajeRAM,
				Member: fmt.Sprintf("%d:%s:%dKB", proc.PID, proc.Nombre, proc.RSS),
			})
			
			// Top CPU (sorted set por consumo CPU)
			pipe.ZAdd(v.ctx, "metrics:containers:cpu:top", redis.Z{
				Score:  float64(proc.CPU),
				Member: fmt.Sprintf("%d:%s:%d", proc.PID, proc.Nombre, proc.CPU),
			})
		}
	}
	
	// Ejecutar todas las operaciones
	_, err := pipe.Exec(v.ctx)
	if err != nil {
		return fmt.Errorf("error almacenando telemetría: %v", err)
	}
	
	return nil
}

// StoreMemoryMetric almacena métrica de memoria
func (v *ValkeyClient) StoreMemoryMetric(timestamp int64, memoria *parser.MemoriaGlobal) error {
	data := map[string]interface{}{
		"timestamp": timestamp,
		"total":     memoria.TotalRAM,
		"used":      memoria.UsoRAM,
		"free":      memoria.LibreRAM,
	}

	jsonData, _ := json.Marshal(data)
	key := fmt.Sprintf("metric:memory:%d", timestamp)
	
	return v.client.Set(v.ctx, key, string(jsonData), 24*time.Hour).Err()
}

// StoreContainerMetric almacena métrica de un contenedor
func (v *ValkeyClient) StoreContainerMetric(timestamp int64, pid int, proc *parser.Proceso) error {
	data := map[string]interface{}{
		"timestamp": timestamp,
		"pid":       pid,
		"nombre":    proc.Nombre,
		"vsz":       proc.VSZ,
		"rss":       proc.RSS,
		"ram_pct":   proc.PorcentajeRAM,
		"cpu":       proc.CPU,
		"comando":   proc.ComandoID,
	}

	jsonData, _ := json.Marshal(data)
	key := fmt.Sprintf("metric:container:%d:%d", timestamp, pid)
	
	return v.client.Set(v.ctx, key, string(jsonData), 24*time.Hour).Err()
}

// IncrementContainersDeleted incrementa contador de contenedores eliminados
func (v *ValkeyClient) IncrementContainersDeleted(contador int) error {
	key := "stats:containers_deleted"
	return v.client.IncrBy(v.ctx, key, int64(contador)).Err()
}

// GetContainersDeleted obtiene el contador de contenedores eliminados
func (v *ValkeyClient) GetContainersDeleted() (int64, error) {
	val, err := v.client.Get(v.ctx, "stats:containers_deleted").Int64()
	if err == redis.Nil {
		return 0, nil
	}
	return val, err
}

// StoreDeletedContainer registra que un contenedor fue eliminado
func (v *ValkeyClient) StoreDeletedContainer(timestamp int64, pid int, nombre string, razon string) error {
	// Incrementar contador total
	v.IncrementContainersDeleted(1)
	
	// Agregar a time series de eliminaciones
	v.client.ZAdd(v.ctx, "metrics:containers:deleted:history", redis.Z{
		Score:  float64(timestamp),
		Member: fmt.Sprintf("%d:%s:%s", pid, nombre, razon),
	})
	
	// Limpiar datos antiguos (mantener últimas 500 entradas)
	v.client.ZRemRangeByRank(v.ctx, "metrics:containers:deleted:history", 0, -501)
	
	// Actualizar contador en hash de estadísticas
	v.client.HIncrBy(v.ctx, "metrics:containers:deleted:count", 
		fmt.Sprintf("%d", timestamp), 1)
	
	return nil
}

// GetLastMetrics obtiene las últimas N métricas
func (v *ValkeyClient) GetLastMetrics(count int64) ([]string, error) {
	// Buscar todas las claves de métricas
	keys, err := v.client.Keys(v.ctx, "metric:*").Result()
	if err != nil {
		return nil, err
	}

	if int64(len(keys)) > count {
		keys = keys[len(keys)-int(count):]
	}

	return keys, nil
}

// Ping verifica conectividad con Valkey
func (v *ValkeyClient) Ping() error {
	_, err := v.client.Ping(v.ctx).Result()
	return err
}

// Close cierra la conexión
func (v *ValkeyClient) Close() error {
	return v.client.Close()
}

// FlushMetrics limpia las métricas viejas (mayor a N horas)
func (v *ValkeyClient) FlushMetrics(hoursOld int) error {
	// Implementación: buscar y eliminar claves antiguas
	// Por ahora, confiar en la expiración de Redis
	return nil
}

// GetStats obtiene estadísticas almacenadas
func (v *ValkeyClient) GetStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	containersDeleted, err := v.GetContainersDeleted()
	if err != nil {
		return nil, err
	}

	stats["containers_deleted"] = containersDeleted
	stats["timestamp"] = time.Now().Unix()

	return stats, nil
}
