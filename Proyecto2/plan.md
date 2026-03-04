# Plan de elavoracion del proyexto 2

## Fase 1

- Instalar los requerimientos en mi maquina virtual.

## Fase 2

- **Dar estructura base**: crear archivo .c y Makefile que compile, cargue y descargue un modulo básico.

- **Lectura de procesos**: Utilizar la estructura `task_struck` del kernel para iterar sobre los procesos del sistema y los contenedores.

- **Estracción de metricas**: Obtener el PID, nombre, memoria virtual (VSZ), memoria física (RSS), uso de RAM y uso de CPU.

- **Sistema de Archivos**: Escribir la informacion en el archivo `/proc/continfo_pr2_so1_202300625`

## Fase 3

- **Imágenes Base**: Crear las 3 imagenes de Docker especificadas:
  - Alto consumo de RAM (usando go-client).
  - Alto consumo de CPU (usando alpine con un calculo matematico infinito).
  - Bajo consumo (usando alpine con comando sleep).
- **Script de Automatización**:  Escribir un script de bash que levante 5 contenedores de forma aleatoria eligiendo entre estas tres imagenes.

- **Cronjob**: Configura tu sistema ara que este script se ejecute cada 2 minutos.

## Fase 4

- **Inicialización**: Configura el daemon para que, al iniciar, levante el contenedor de Grafana (preferiblemente usando Docker Compose junto con Valkey) y ejecute el script que carga el modulo del kernel.

- **Ciclo principal**: Crear un loop infinitto que se ejecute cada 20 a 60 segundos.

- **Lecutura y Parseo**: En cada iteracion, el daemon debe leer el archivo `/proc/continfo_pr2_so1_202300625`, deserializar la informacion y enviarla a la base de datos Valkey.

- **Toma de deciciones**: Implementar la logica para el aalisis de consumo. Debe detener y eliminar contenedores que excedan los limites, pero respetando la restricción estricta: siempre deben existir 3 contenedores de bajo consumo y 2 de alto consumo en todo momento. No se debe eliminar a Grafana.
 

## Fase 5

- **Conexió**: Conecta Grafana a tu base e datos Valkey.

-  **Dashboard**: Construye el panel requerido ("Panel de contenedores por carnet").
  
- **Métricas**: Agregar las tarjetas para RAM total, RAM usada, RAM libre, y total de contenedores eliminados.

- **Gráficas**: Añadir la gráfica de línea para el uso de RAM en el tiempo, y las gráficas de paste para el Top 5 de contenedores por consumo de RAM y CPU.

## Fase 6

- **Limpieza**:  Asegurarse de que, al finalizar el servicio de Go, este elimine cronjob para evitar que la máquina colapse por la creación infinita de contenedores.

- **Documentación** Redactar el manual técnico, laguía de instalación y preparar las capturas de prueba.

- **Extra**: Si hay tiempo, desarrollar el submódulo en Rust que imprima "Hola Mundo 202300625" en los logs del kernel para obtener puntos extra.

