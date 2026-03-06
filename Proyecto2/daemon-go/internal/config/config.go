package config

import (
	"os"
	"strconv"
	"time"
)

// Config contiene toda la configuración del daemon
type Config struct {
	// Kernel
	ProcFile string
	Carnet   string

	// Docker
	DockerComposeFile string
	DockerComposePath string

	// Valkey/Redis
	ValkeyHost string
	ValkeyPort string

	// Daemon
	CycleDuration    time.Duration
	CheckInterval    time.Duration
	MaxIterations    int
	EnableGraceful   bool

	// Cronjob
	CronScriptPath string
	CronInstall    string
	CronUninstall  string

	// Contenedores
	MinLowConsumption  int
	MinHighConsumption int
	MaxContainers      int

	// Umbrales de eliminación (%)
	RAMThreshold    float64
	CPUThreshold    float64
}

// LoadConfig carga la configuración desde variables de entorno y valores por defecto
func LoadConfig() *Config {
	return &Config{
		// Kernel
		ProcFile: getEnv("PROC_FILE", "/proc/continfo_pr2_so1_202300625"),
		Carnet:   getEnv("CARNET", "202300625"),

		// Docker
		DockerComposeFile: getEnv("DOCKER_COMPOSE_FILE", "docker-compose.yml"),
		DockerComposePath: getEnv("DOCKER_COMPOSE_PATH", "/home/carlos/Desktop/Proyecto2/docker"),

		// Valkey/Redis
		ValkeyHost: getEnv("VALKEY_HOST", "localhost"),
		ValkeyPort: getEnv("VALKEY_PORT", "6379"),

		// Daemon
		CycleDuration:  time.Duration(getEnvInt("CYCLE_DURATION", 30)) * time.Second,
		CheckInterval:  time.Duration(getEnvInt("CHECK_INTERVAL", 5)) * time.Second,
		MaxIterations:  getEnvInt("MAX_ITERATIONS", 0), // 0 = infinito
		EnableGraceful: getEnvBool("ENABLE_GRACEFUL", true),

		// Cronjob
		CronScriptPath: getEnv("CRON_SCRIPT_PATH", "/home/carlos/Desktop/Proyecto2/docker/generar.sh"),
		CronInstall:    getEnv("CRON_INSTALL", "/home/carlos/Desktop/Proyecto2/cron/install-cron.sh"),
		CronUninstall:  getEnv("CRON_UNINSTALL", "/home/carlos/Desktop/Proyecto2/cron/uninstall-cron.sh"),

		// Contenedores (restricciones clave)
		MinLowConsumption:  3, // Mínimo 3 contenedores de bajo consumo
		MinHighConsumption: 2, // Mínimo 2 de alto consumo
		MaxContainers:      20,

		// Umbrales (%)
		RAMThreshold: getEnvFloat("RAM_THRESHOLD", 80.0),
		CPUThreshold: getEnvFloat("CPU_THRESHOLD", 90.0),
	}
}

// Funciones auxiliares para obtener variables de entorno
func getEnv(key, defaultVal string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	valStr := getEnv(key, "")
	if val, err := strconv.Atoi(valStr); err == nil {
		return val
	}
	return defaultVal
}

func getEnvFloat(key string, defaultVal float64) float64 {
	valStr := getEnv(key, "")
	if val, err := strconv.ParseFloat(valStr, 64); err == nil {
		return val
	}
	return defaultVal
}

func getEnvBool(key string, defaultVal bool) bool {
	valStr := getEnv(key, "")
	if valStr != "" {
		return valStr == "true" || valStr == "1" || valStr == "yes"
	}
	return defaultVal
}
