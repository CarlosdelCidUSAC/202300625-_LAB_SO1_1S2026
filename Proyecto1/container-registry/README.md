# Registro Privado de Contenedores (Zot)

Esta carpeta contiene la configuración para el registro privado de imágenes de contenedores usando Zot.

## Estructura

- `zot-config/` - Archivos de configuración de Zot
- `images-backup/` - Backup de imágenes importantes
- `certificates/` - Certificados SSL/TLS para HTTPS

## Zot Container Registry

Zot es un registro de contenedores ligero y compatible con OCI, ideal para entornos privados.

### Características
- Compatible con Docker/OCI
- Autenticación básica y JWT
- Soporte para múltiples almacenamientos
- Fácil de configurar y mantener
- Bajo consumo de recursos

### Configuración Básica

Archivo de configuración: `zot-config/config.json`

```json
{
  "storage": {
    "rootDirectory": "/var/lib/zot",
    "gc": true,
    "gcInterval": "1h",
    "dedupe": true
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000",
    "realm": "zot",
    "auth": {
      "htpasswd": {
        "path": "/etc/zot/htpasswd"
      }
    },
    "tls": {
      "cert": "/etc/zot/cert.pem",
      "key": "/etc/zot/key.pem"
    }
  },
  "log": {
    "level": "info",
    "output": "/var/log/zot/zot.log"
  }
}
```

### Instalación en VM2-registry

1. **Instalar Zot**:
```bash
# Descargar e instalar Zot
wget https://github.com/project-zot/zot/releases/latest/download/zot-linux-amd64
sudo mv zot-linux-amd64 /usr/local/bin/zot
sudo chmod +x /usr/local/bin/zot
```

2. **Crear usuario y directorios**:
```bash
sudo useradd -r -s /bin/false zot
sudo mkdir -p /etc/zot /var/lib/zot /var/log/zot
sudo chown -R zot:zot /etc/zot /var/lib/zot /var/log/zot
```

3. **Configurar autenticación**:
```bash
# Crear archivo htpasswd
sudo htpasswd -B -c /etc/zot/htpasswd admin
# Agregar más usuarios si es necesario
sudo htpasswd -B /etc/zot/htpasswd usuario1
```

4. **Generar certificados SSL** (opcional para HTTPS):
```bash
# Generar certificado autofirmado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/zot/key.pem \
  -out /etc/zot/cert.pem \
  -subj "/C=GT/ST=Guatemala/L=Guatemala City/O=USAC/CN=vm2-registry"
```

### Uso del Registro

#### Configurar Docker para usar el registro privado

```bash
# Agregar registro inseguro (solo para desarrollo)
echo '{"insecure-registries": ["vm2-registry:5000"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# Iniciar sesión en el registro
docker login vm2-registry:5000 -u admin -p password
```

#### Subir imágenes al registro

```bash
# Etiquetar imagen
docker tag mi-servicio:latest vm2-registry:5000/mi-servicio:latest

# Subir imagen
docker push vm2-registry:5000/mi-servicio:latest
```

#### Descargar imágenes del registro

```bash
# Descargar imagen
docker pull vm2-registry:5000/mi-servicio:latest
```

### Integración con los Servicios API

Los servicios API usarán el registro privado para:
1. Construir y subir sus imágenes
2. Descargar imágenes para despliegue
3. Compartir imágenes entre servicios

### Scripts de Automatización

Los scripts para gestionar el registro se encuentran en `../scripts/container-deployment/`:
- `deploy-to-registry.sh` - Subir imágenes al registro
- `backup-registry.sh` - Backup de imágenes
- `restore-registry.sh` - Restaurar imágenes desde backup

### Monitoreo

El registro Zot expone métricas en `/metrics` para integración con Prometheus.

### Seguridad

1. **Autenticación**: Todos los usuarios deben autenticarse
2. **HTTPS**: Usar certificados SSL/TLS en producción
3. **Firewall**: Restringir acceso solo a las VMs del proyecto
4. **Backup**: Realizar backup regular de imágenes importantes
5. **Logs**: Monitorear logs de acceso y errores

### Próximos Pasos

1. Instalar Zot en vm2-registry
2. Configurar autenticación
3. Generar certificados SSL
4. Configurar Docker en todas las VMs para usar el registro
5. Crear scripts de automatización
6. Configurar monitoreo del registro