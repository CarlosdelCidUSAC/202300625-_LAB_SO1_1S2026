package logger

import (
	"fmt"
	"log"
	"os"
	"time"
)

// Level define los niveles de logging
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
	FATAL
)

var levelNames = []string{"DEBUG", "INFO", "WARN", "ERROR", "FATAL"}

// Logger estructura para logging centralizado
type Logger struct {
	level  Level
	logger *log.Logger
	file   *os.File
}

// NewLogger crea una nueva instancia del logger
func NewLogger(level Level, filepath string) (*Logger, error) {
	var file *os.File
	var err error

	if filepath != "" {
		file, err = os.OpenFile(filepath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			return nil, err
		}
	}

	var output *os.File
	if file != nil {
		output = file
	} else {
		output = os.Stdout
	}

	return &Logger{
		level:  level,
		logger: log.New(output, "", log.LstdFlags),
		file:   file,
	}, nil
}

// Debug registra un mensaje de debug
func (l *Logger) Debug(msg string, fields ...interface{}) {
	if l.level <= DEBUG {
		l.log(DEBUG, msg, fields...)
	}
}

// Info registra un mensaje de información
func (l *Logger) Info(msg string, fields ...interface{}) {
	if l.level <= INFO {
		l.log(INFO, msg, fields...)
	}
}

// Warn registra un mensaje de advertencia
func (l *Logger) Warn(msg string, fields ...interface{}) {
	if l.level <= WARN {
		l.log(WARN, msg, fields...)
	}
}

// Error registra un mensaje de error
func (l *Logger) Error(msg string, fields ...interface{}) {
	if l.level <= ERROR {
		l.log(ERROR, msg, fields...)
	}
}

// Fatal registra un mensaje y termina la ejecución
func (l *Logger) Fatal(msg string, fields ...interface{}) {
	l.log(FATAL, msg, fields...)
	if l.file != nil {
		l.file.Close()
	}
	os.Exit(1)
}

// log es la función interna que realiza el logging
func (l *Logger) log(lvl Level, msg string, fields ...interface{}) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logMsg := fmt.Sprintf("[%s] [%s] %s", timestamp, levelNames[lvl], msg)
	if len(fields) > 0 {
		logMsg = fmt.Sprintf("%s %v", logMsg, fields)
	}
	l.logger.Println(logMsg)
}

// Close cierra el archivo de log si está abierto
func (l *Logger) Close() error {
	if l.file != nil {
		return l.file.Close()
	}
	return nil
}

// LogJSON registra datos en formato JSON (para almacenamiento estructurado)
func (l *Logger) LogJSON(data map[string]interface{}) {
	logMsg := fmt.Sprintf("[%s] [JSON] %v", time.Now().Format("2006-01-02 15:04:05"), data)
	l.logger.Println(logMsg)
}
