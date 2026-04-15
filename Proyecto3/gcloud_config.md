# Configuración de Google Cloud y KubeVirt para Proyecto3

Este documento describe la configuración de Google Cloud Platform (GCP) para desplegar un cluster de Google Kubernetes Engine (GKE) con soporte de virtualización anidada, la instalación de KubeVirt, y la configuración de un registro de contenedores Zot en una VM externa.

---

## 1. Prerrequisitos e Instalación de Herramientas

Se instalaron las siguientes herramientas en un sistema Arch Linux (14/04/2026):

| Herramienta | Versión | Origen |
|-------------|---------|--------|
| Google Cloud CLI (gcloud) | 564.0.0 | AUR |
| kubectl | 1.35.3 | Repositorios oficiales |
| Docker | 29.4.0 | Actualizado |
| Rust y Cargo | 1.94.1 | Toolchain completo |
| Go | 1.26.2 | Repositorios oficiales |
| Locust | 2.43.4 | pipx |
| Protoc (Protocol Buffers) | 34.1 | Repositorios oficiales |
| gRPC CLI y bibliotecas | 1.80.0 | Repositorios oficiales |

**Nota:** Se eliminó una versión corrupta de kubectl en `~/.local/bin`, manteniéndose la versión del sistema. Todas las herramientas están disponibles en el PATH y listas para uso.

---

## 2. Configuración de Google Cloud

### 2.1 Inicialización y autenticación

```bash
# Inicializar gcloud
gcloud init

# Verificar cuentas autenticadas
gcloud auth list

# Configurar proyecto (ajustar según tu proyecto)
gcloud config set project Proyecto3_202300625
```

**Importante:** Asegurarse de habilitar la facturación para el proyecto.

### 2.2 Creación del cluster GKE con virtualización anidada

```bash
gcloud container clusters create gke-kubevirt-cluster \
  --region=us-east1 \
  --machine-type=n2-standard-4 \
  --num-nodes=1 \
  --enable-nested-virtualization \
  --node-labels=nested-virtualization=enabled
```

### 2.3 Obtener credenciales del cluster

```bash
gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
```

### 2.4 Verificar nodos

```bash
kubectl get nodes
```

**Salida esperada:**
```
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-gke-kubevirt-cluster-default-pool-02c92b54-lq9n   Ready    <none>   13m   v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-05c9670c-bzsv   Ready    <none>   13m   v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-ff077238-gwt0   Ready    <none>   13m   v1.35.1-gke.1396002
```

---

## 3. Instalación de KubeVirt

### 3.1 Obtener la versión estable de KubeVirt

```bash
export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
```

### 3.2 Desplegar el operador de KubeVirt

```bash
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
```

### 3.3 Desplegar el Custom Resource de KubeVirt

```bash
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
```

---

## 4. Verificación y Validación

### 4.1 Verificar pods de KubeVirt

```bash
kubectl get pods -n kubevirt
```

### 4.2 Esperar disponibilidad de KubeVirt

```bash
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
```

### 4.3 Validar soporte de virtualización por hardware

```bash
kubectl logs -n kubevirt -l kubevirt.io=virt-handler --tail=300 | grep -Ei "hardware virtualization|kvm"
```

**Salida esperada:**
```
{"component":"virt-handler","level":"info","msg":"kvm device plugin started","timestamp":"2026-04-15T17:09:47.582299Z"}
{"component":"virt-handler","level":"info","msg":"device '/dev/kvm' is present.","timestamp":"2026-04-15T17:09:47.582512Z"}
```

---

## 5. Troubleshooting aplicado en GKE

Cuando `virt-operator` queda en estado `Pending` con eventos de `node affinity/selector`, es necesario permitir el despliegue sobre nodos worker.

### 5.1 Quitar afinidad estricta del deployment de virt-operator

```bash
kubectl -n kubevirt patch deployment virt-operator --type=json -p='[
  {"op":"remove","path":"/spec/template/spec/affinity/nodeAffinity/requiredDuringSchedulingIgnoredDuringExecution"}
]'
```

### 5.2 Forzar node placement para infra/workloads en Linux workers

```bash
kubectl patch kubevirt -n kubevirt kubevirt --type=merge -p '{
  "spec":{
    "infra":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}},
    "workloads":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}}
  }
}'
```

### 5.3 Recrear el Job de estrategia

```bash
kubectl delete job -n kubevirt kubevirt-24adb5335df840be8057c5e37813cce9c0477006-job6tjgv
```

### 5.4 Esperar disponibilidad y verificar componentes

```bash
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
kubectl get pods -n kubevirt -o wide
```

**Resultado esperado:** pods `virt-api`, `virt-controller`, `virt-handler` y `virt-operator` en estado `Running`.

---

## 6. Gestión de Costos: Apagar y Reactivar

### 6.1 Opción A: Pausa parcial (mantener el clúster)

Reduce el node pool a 0 nodos para evitar costo de VMs. El control plane del clúster sigue existiendo y puede generar costo mínimo de administración.

```bash
# Ver nombre del node pool
gcloud container node-pools list --cluster=gke-kubevirt-cluster --region=us-east1

# Apagar nodos (ejemplo con default-pool)
gcloud container clusters resize gke-kubevirt-cluster \
  --region=us-east1 \
  --node-pool=default-pool \
  --num-nodes=0 \
  --quiet
```

**Para reactivar:**

```bash
gcloud container clusters resize gke-kubevirt-cluster \
  --region=us-east1 \
  --node-pool=default-pool \
  --num-nodes=1 \
  --quiet

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
kubectl get nodes
```

### 6.2 Opción B: Apagado total (minimizar costos al máximo)

Elimina el clúster completo. Para volver, hay que crearlo otra vez y reinstalar KubeVirt.

```bash
# Apagar total
gcloud container clusters delete gke-kubevirt-cluster --region=us-east1 --quiet
```

**Para reactivar (crear desde cero):**

```bash
gcloud container clusters create gke-kubevirt-cluster \
  --region=us-east1 \
  --machine-type=n2-standard-4 \
  --num-nodes=1 \
  --enable-nested-virtualization \
  --node-labels=nested-virtualization=enabled

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1

export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
```

---

## 7. Registro de Contenedores Zot en VM Externa

Para exponer Zot fuera del clúster, se puede usar una VM Linux externa con Docker.

### 7.1 Crear la VM y abrir el puerto

```bash
gcloud compute instances create zot-registry-vm \
  --zone=us-east1-b \
  --machine-type=e2-medium \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=zot-registry

gcloud compute firewall-rules create allow-zot-registry \
  --allow tcp:5000 \
  --target-tags zot-registry
```

### 7.2 Acceder a la VM

```bash
# Ver la IP externa de la VM
gcloud compute instances list --filter='name=zot-registry-vm'

# Conectarse por SSH
gcloud compute ssh zot-registry-vm --zone=us-east1-b
```

Dentro de la VM, revisar el contenedor y logs:

```bash
sudo docker ps
sudo docker logs zot-registry --tail 100
sudo docker restart zot-registry
```

### 7.3 Instalar Docker en la VM

```bash
sudo apt-get update
sudo apt-get install -y docker.io openssl
sudo systemctl enable --now docker
```

### 7.4 Crear certificados TLS y configuración de Zot

```bash
sudo mkdir -p /opt/zot/{data,certs}
cd /opt/zot

sudo openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
  -nodes -keyout certs/zot.key -out certs/zot.crt \
  -subj "/CN=$(curl -s ifconfig.me)"

sudo tee /opt/zot/config.json > /dev/null <<'EOF'
{
  "distSpecVersion": "1.1.1",
  "storage": {
    "rootDirectory": "/var/lib/zot"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000",
    "tls": {
      "cert": "/etc/zot/certs/zot.crt",
      "key": "/etc/zot/certs/zot.key"
    }
  },
  "log": {
    "level": "debug"
  }
}
EOF
```

### 7.5 Levantar Zot en la VM

```bash
sudo docker run -d --name zot-registry \
  --restart unless-stopped \
  -p 5000:5000 \
  -v /opt/zot/data:/var/lib/zot \
  -v /opt/zot/config.json:/etc/zot/config.json:ro \
  -v /opt/zot/certs:/etc/zot/certs:ro \
  ghcr.io/project-zot/zot:latest \
  serve /etc/zot/config.json
```

### 7.6 Verificar desde afuera

```bash
curl -k https://<IP_PUBLICA_VM>:5000/v2/_catalog
```

### 7.7 Publicar una imagen

```bash
# Obtener la IP externa real de la VM
ZOT_REGISTRY="<EXTERNAL_IP_VM>:5000"

# Opción 1: con skopeo
skopeo copy --dest-tls-verify=false \
  docker://ghcr.io/project-zot/golang:1.20 \
  docker://${ZOT_REGISTRY}/golang:1.20

# Opción 2: con Docker
docker pull ghcr.io/project-zot/golang:1.20
docker tag ghcr.io/project-zot/golang:1.20 ${ZOT_REGISTRY}/golang:1.20
docker login ${ZOT_REGISTRY}
docker push ${ZOT_REGISTRY}/golang:1.20
```

**Nota:** La IP `10.142.0.6` es interna de la VM. Para empujar desde fuera de GCP, usar la IP externa (ej. `34.73.45.51:5000`) o ejecutar el push dentro de la VM mediante SSH.

### 7.8 Re-activar

Si la VM se apaga, basta con volver a iniciar Docker y el contenedor:

```bash
sudo systemctl start docker
sudo docker start zot-registry
```

### 7.9 Apagar y encender la VM de Zot (ahorro de costos)

Para pausar gasto de CPU/RAM de la VM (manteniendo disco):

```bash
# Apagar VM
gcloud compute instances stop zot-registry-vm --zone=us-east1-b

# Encender VM
gcloud compute instances start zot-registry-vm --zone=us-east1-b

# Verificar estado
gcloud compute instances list --filter='name=zot-registry-vm'
```

Si no se usará por varios días y se desea ahorro máximo, se puede eliminar:

```bash
gcloud compute instances delete zot-registry-vm --zone=us-east1-b --quiet
```

Al recrearla, volver a ejecutar la sección de instalación de Docker y despliegue de Zot.

---

## 8. Referencias y Comandos Útiles

### Comandos de verificación rápidos

```bash
# Ver estado del cluster
gcloud container clusters list --region=us-east1

# Ver nodos del cluster
kubectl get nodes -o wide

# Ver pods de KubeVirt
kubectl get pods -n kubevirt

# Ver servicios de KubeVirt
kubectl get svc -n kubevirt

# Ver logs de virt-handler
kubectl logs -n kubevirt -l kubevirt.io=virt-handler --tail=50
```

### Enlaces útiles

- [Documentación oficial de KubeVirt](https://kubevirt.io/)
- [Google Cloud SDK Installation](https://cloud.google.com/sdk/docs/install)
- [Zot Registry Documentation](https://zotregistry.io/)

---

*Última actualización: 15/04/2026*  
*Proyecto: Proyecto3_202300625*