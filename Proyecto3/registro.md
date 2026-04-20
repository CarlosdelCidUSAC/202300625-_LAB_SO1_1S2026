## Instalación de herramientas - 14/04/2026

Se instalaron las siguientes herramientas en sistema Arch Linux:

- Google Cloud bash (gcloud) 564.0.0 - desde AUR
- kubectl 1.35.3 - desde repositorios oficiales
- Docker 29.4.0 - actualizado
- Rust y Cargo 1.94.1 - toolchain completo
- Go 1.26.2
- Locust 2.43.4 - via pipx
- Protoc (Protocol Buffers) 34.1
- gRPC bash y bibliotecas 1.80.0

Se eliminó versión corrupta de kubectl en ~/.local/bin, se mantiene versión del sistema.

Todas las herramientas están disponibles en PATH y listas para uso.

## Configuracion de Google Cloud

```bash
# Crear el Clúster de GKE con Virtualización Anidada

gcloud init
gcloud auth list

gcloud config set project Proyecto3_202300625 

# se debe habilitar la facturación

gcloud container clusters create gke-kubevirt-cluster \
  --region=us-east1 \
  --machine-type=n1-standard-2 \
  --num-nodes=1 \
  --enable-nested-virtualization \
  --node-labels=nested-virtualization=enabled

#Obtener las Credenciales del Clúster

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1  

kubectl get nodes
```

### Salida

```bash
kubeconfig entry generated for gke-kubevirt-cluster.
NAME                  LOCATION  MASTER_VERSION      MASTER_IP      MACHINE_TYPE   NODE_VERSION        NUM_NODES  STATUS   STACK_TYPE
gke-kubevirt-cluster  us-east1  1.35.1-gke.1396002  34.73.152.152  n1-standard-2  1.35.1-gke.1396002  3          RUNNING  IPV4
➜  Proyecto3 git:(main) ✗ gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
Fetching cluster endpoint and auth data.
kubeconfig entry generated for gke-kubevirt-cluster.
➜  Proyecto3 git:(main) ✗ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-gke-kubevirt-cluster-default-pool-02c92b54-lq9n   Ready    <none>   13m   v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-05c9670c-bzsv   Ready    <none>   13m   v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-ff077238-gwt0   Ready    <none>   13m   v1.35.1-gke.1396002
```

```bash

#Instalar KubeVirt

# Desplegar el Operador de KubeVirt

export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"

kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"


# Desplegar el Custom Resource de KubeVirt

kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
```

### Salida

```bash
namespace/kubevirt created
customresourcedefinition.apiextensions.k8s.io/kubevirts.kubevirt.io created
priorityclass.scheduling.k8s.io/kubevirt-cluster-critical created
clusterrole.rbac.authorization.k8s.io/kubevirt.io:operator created
serviceaccount/kubevirt-operator created
role.rbac.authorization.k8s.io/kubevirt-operator created
rolebinding.rbac.authorization.k8s.io/kubevirt-operator-rolebinding created
clusterrole.rbac.authorization.k8s.io/kubevirt-operator created
clusterrolebinding.rbac.authorization.k8s.io/kubevirt-operator created
Warning: spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[1].matchExpressions[0].key: node-role.kubernetes.io/master is use "node-role.kubernetes.io/control-plane" instead
deployment.apps/virt-operator created

# -----------------------------

kubevirt.kubevirt.io/kubevirt created
```

```bash

#Verificar la instalación

kubectl get pods -n kubevirt

#Validar el Soporte de Virtualización por Hardware

kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
kubectl logs -n kubevirt -l kubevirt.io=virt-handler --tail=300 | grep -Ei "hardware virtualization|kvm"
```

### Salida 

```bash
kubevirt.kubevirt.io/kubevirt condition met
{"component":"virt-handler","level":"info","msg":"kvm device plugin started","timestamp":"2026-04-15T17:09:47.582299Z"}
{"component":"virt-handler","level":"info","msg":"device '/dev/kvm' is present.","timestamp":"2026-04-15T17:09:47.582512Z"}
```

## Troubleshooting aplicado en GKE

Cuando `virt-operator` queda en `Pending` con eventos de `node affinity/selector`, en este entorno fue necesario permitir despliegue sobre nodos worker.

```bash
# 1) Quitar afinidad estricta del deployment de virt-operator
kubectl -n kubevirt patch deployment virt-operator --type=json -p='[
  {"op":"remove","path":"/spec/template/spec/affinity/nodeAffinity/requiredDuringSchedulingIgnoredDuringExecution"}
]'

# 2) Forzar node placement para infra/workloads en Linux workers
kubectl patch kubevirt -n kubevirt kubevirt --type=merge -p '{
  "spec":{
    "infra":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}},
    "workloads":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}}
  }
}'

# 3) Recrear el Job de estrategia para que tome la nueva configuración
kubectl delete job -n kubevirt kubevirt-24adb5335df840be8057c5e37813cce9c0477006-job6tjgv

# 4) Esperar disponibilidad y verificar componentes
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
kubectl get pods -n kubevirt -o wide
```

Resultado esperado: pods `virt-api`, `virt-controller`, `virt-handler` y `virt-operator` en `Running`.

## Apagar y reactivar para ahorrar costos

### Opcion A: Pausa de workloads (mantener clúster y Gateway)

Esta opcion reduce costo de CPU/RAM de aplicaciones, manteniendo infraestructura base activa.

```bash
# Escalar apps del proyecto a 0 replicas
kubectl scale deployment rust-api-deployment --replicas=0
kubectl scale deployment go-receiver-deployment --replicas=0

# Verificar
kubectl get deploy rust-api-deployment go-receiver-deployment
kubectl get pods
```

Para reactivar workloads:

```bash
kubectl scale deployment go-receiver-deployment --replicas=1
kubectl scale deployment rust-api-deployment --replicas=1

kubectl rollout status deployment/go-receiver-deployment --timeout=240s
kubectl rollout status deployment/rust-api-deployment --timeout=240s
kubectl get hpa rust-api-hpa
```

### Opcion B: Pausa de nodos (mantener clúster, quitar costo de workers)

Esta opcion deja el control plane pero apaga los nodos. Al volver, los workloads se recuperan desde los manifests ya aplicados.

```bash
# Ver node pool
gcloud container node-pools list --cluster=gke-kubevirt-cluster --region=us-east1

# Apagar nodos
gcloud container clusters resize gke-kubevirt-cluster \
  --region=us-east1 \
  --node-pool=default-pool \
  --num-nodes=0 \
  --quiet
```

Para reactivar nodos:

```bash
gcloud container clusters resize gke-kubevirt-cluster \
  --region=us-east1 \
  --node-pool=default-pool \
  --num-nodes=1 \
  --quiet

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
kubectl get nodes
kubectl get pods -A
kubectl get gateway military-gateway
```

### Opcion C: Apagado total (minimizar costos al maximo)

Elimina el clúster completo. Requiere recrear GKE y re-aplicar manifests del proyecto.

```bash
gcloud container clusters delete gke-kubevirt-cluster --region=us-east1 --quiet
```

Para reactivar (crear desde cero y levantar lo implementado):

```bash
# 1) Crear cluster
gcloud container clusters create gke-kubevirt-cluster \
  --region=us-east1 \
  --machine-type=n1-standard-2 \
  --num-nodes=1 \
  --enable-nested-virtualization \
  --node-labels=nested-virtualization=enabled \
  --gateway-api=standard

# 2) Conectar kubectl
gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1

# 3) (Si aplica) reinstalar KubeVirt
export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s

# 4) Re-aplicar lo ya implementado
kubectl apply -f kube/gateway.yaml
kubectl apply -f kube/go-receiver-deploy.yaml
kubectl apply -f kube/go-receiver-service.yaml
kubectl apply -f kube/rust-api-service.yaml
kubectl apply -f kube/rust-api-deploy.yaml
kubectl apply -f kube/hpa.yaml
kubectl apply -f kube/rust-api-httproute-v2.yaml

# 5) Verificar estado
kubectl rollout status deployment/go-receiver-deployment --timeout=240s
kubectl rollout status deployment/rust-api-deployment --timeout=240s
kubectl get gateway military-gateway
kubectl get httproute rust-api-httproute
```

## VM externa para Zot Container Registry

Para exponer Zot fuera del clúster, se puede usar una VM Linux externa con Docker. En este caso Zot corre como contenedor y escucha en `5000`.

### 1) Crear la VM y abrir el puerto

```bash
gcloud compute instances create zot-registry-vm \
  --zone=us-east1-b \
  --machine-type=n1-standard-2 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=zot-registry
gcloud compute firewall-rules create allow-zot-registry \
  --allow tcp:5000 \
  --target-tags zot-registry
```

Created [https://www.googleapis.com/compute/v1/projects/proyecto3-202300625/zones/us-east1-b/instances/zot-registry-vm].
NAME             ZONE        MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP  STATUS
zot-registry-vm  us-east1-b  n1-standard-2                  10.142.0.6   34.73.45.51  RUNNING

Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/proyecto3-202300625/global/firewalls/allow-zot-registry]. 
Creating firewall...done.                                                                                                              
NAME                NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
allow-zot-registry  default  INGRESS    1000      tcp:5000        False

## Comandos operativos rapidos - 17/04/2026

### Limpiar y recrear valkey-cli en una sola linea

Este comando evita el error `AlreadyExists` y valida conectividad inmediatamente:

```bash
kubectl delete pod valkey-cli --ignore-not-found && kubectl run -i --tty valkey-cli --image=valkey/valkey:latest --restart=Never --rm -- valkey-cli -h valkey-service.default.svc.cluster.local ping
```

Salida esperada:

```text
PONG
```

### Liberar puerto local 8080 y reabrir Grafana

Cuando `kubectl port-forward` falla con `address already in use`:

```bash
ss -ltnp '( sport = :8080 )' && kill <PID_KUBECTL_8080>
kubectl port-forward svc/grafana-service 8080:80
```

Verificacion esperada:

```text
Forwarding from 127.0.0.1:8080 -> 3000
Forwarding from [::1]:8080 -> 3000
```

### Fix aplicado: Grafana en KubeVirt (17/04/2026)

Problema observado:

- `kubectl port-forward svc/grafana-service 8080:80` iniciaba, pero al conectar devolvia `connection refused` o `lost connection to pod`.

Causa raiz:

- El `cloud-init` original de `grafana-vm` instalaba Docker y levantaba Grafana en contenedor, pero la instalacion fallaba por espacio en disco (`No space left on device`).
- El bootstrap de Grafana no completaba y no quedaba proceso escuchando en `3000`.

Correccion aplicada:

- Migracion a instalacion nativa de `grafana` (sin Docker en guest).
- Uso de `Secret` para cloud-init por limite de tamano de `userData` inline.
- Montaje temprano del disco persistente y uso de ese disco para cache/paths de Grafana durante instalacion y ejecucion.

Manifiestos actualizados:

- `kube/kubevirt/grafana-vm.yaml`
- `kube/kubevirt/grafana-cloudinit-secret.yaml`

Validacion final:

```bash
kubectl port-forward svc/grafana-service 8080:80
curl -sS -m 5 http://127.0.0.1:8080/api/health
```

Salida valida observada:

```json
{
  "database": "ok",
  "version": "13.0.1",
  "commit": "a100054f"
}
```

### Acceder a la VM

Para entrar a la VM y administrar Zot:

```bash
# Ver la IP externa de la VM
gcloud compute instances list --filter='name=zot-registry-vm'

# Conectarse por SSH
gcloud compute ssh zot-registry-vm --zone=us-east1-b
```

Ya dentro de la VM puedes revisar el contenedor y los logs con:

```bash
sudo docker ps
sudo docker logs zot-registry --tail 100
sudo docker restart zot-registry
```

### 2) Instalar Docker en la VM

```bash
sudo apt-get update
sudo apt-get install -y docker.io openssl
sudo systemctl enable --now docker
```

### 3) Crear certificados TLS y configuracion de Zot

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

### 4) Levantar Zot en la VM

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

### 5) Verificar desde afuera

```bash
curl -k https://<IP_PUBLICA_VM>:5000/v2/_catalog
```

### 6) Publicar una imagen

```bash
# Obtener la IP externa real de la VM y usarla como destino
ZOT_REGISTRY="<EXTERNAL_IP_VM>:5000"

# Opcion 1: si tienes skopeo instalado
skopeo copy --dest-tls-verify=false \
  docker://ghcr.io/project-zot/golang:1.20 \
  docker://${ZOT_REGISTRY}/golang:1.20

# Opcion 2: con Docker (si prefieres no instalar skopeo)
docker pull ghcr.io/project-zot/golang:1.20
docker tag ghcr.io/project-zot/golang:1.20 ${ZOT_REGISTRY}/golang:1.20
docker login ${ZOT_REGISTRY}
docker push ${ZOT_REGISTRY}/golang:1.20
```

Nota: la IP `10.142.0.6` es interna de la VM y no se puede usar desde tu laptop. Si vas a empujar desde fuera de GCP, usa la IP externa `34.73.45.51:5000` o ejecuta el push dentro de la VM con `gcloud compute ssh zot-registry-vm --zone=us-east1-b`.

### Re-activar

Si la VM se apaga, basta con volver a iniciar Docker y el contenedor:

```bash
sudo systemctl start docker
sudo docker start zot-registry
```

### Apagar y encender la VM de Zot (ahorro de costos)

Para pausar gasto de CPU/RAM de la VM (manteniendo disco):

```bash
# Apagar VM
gcloud compute instances stop zot-registry-vm --zone=us-east1-b

# Encender VM
gcloud compute instances start zot-registry-vm --zone=us-east1-b

# Verificar estado
gcloud compute instances list --filter='name=zot-registry-vm'
```

Si no la usaras por varios dias y quieres ahorro maximo, puedes eliminarla:

```bash
gcloud compute instances delete zot-registry-vm --zone=us-east1-b --quiet
```

Al recrearla, vuelve a ejecutar la seccion de instalacion de Docker y despliegue de Zot.

Si planeas que GKE tire imágenes desde esta VM, luego hay que confiar el certificado en los nodos o usar una CA válida.



kubectl patch vm grafana-vm --type=merge -p '{"spec":{"running":true}}'
kubectl patch vm valkey-vm --type=merge -p '{"spec":{"running":true}}'
gcloud compute instances start zot-registry-vm --zone=us-east1-b

## Limpieza total de costos en Google Cloud - 18/04/2026

Se ejecuto limpieza completa para dejar en cero los recursos facturables principales del proyecto `proyecto3-202300625`.

### Recursos detectados y eliminados

- Clusters GKE: `gke-kubevirt-cluster` (eliminado).
- Instancias Compute Engine: `zot-registry-vm` (eliminada).
- Discos persistentes huerfanos (PVC):
  - `pvc-6b256d85-5065-4484-b86e-9106cd7adaac` (eliminado).
  - `pvc-b60d69e0-abda-41b0-bff8-1e952fd92284` (eliminado).

### Comandos aplicados

```bash
# Eliminar cluster GKE
gcloud container clusters delete gke-kubevirt-cluster --region=us-east1 --quiet

# Eliminar VM externa de Zot
gcloud compute instances delete zot-registry-vm --zone=us-east1-b --quiet

# Eliminar discos huerfanos de PVC
gcloud compute disks delete pvc-6b256d85-5065-4484-b86e-9106cd7adaac --zone=us-east1-c --quiet
gcloud compute disks delete pvc-b60d69e0-abda-41b0-bff8-1e952fd92284 --zone=us-east1-d --quiet
```

### Verificacion final (estado vacio)

```bash
gcloud container clusters list --format='table(name,location,status)'
gcloud compute instances list --format='table(name,zone,status)'
gcloud compute disks list --format='table(name,zone,sizeGb,type,status)'
gcloud compute snapshots list --format='table(name,status,diskSizeGb)'
gcloud compute addresses list --format='table(name,region,status,address)'
gcloud compute addresses list --global --format='table(name,status,address)'
gcloud compute forwarding-rules list --format='table(name,region,IPAddress,IPProtocol,loadBalancingScheme)'
gcloud compute forwarding-rules list --global --format='table(name,IPAddress,IPProtocol,loadBalancingScheme)'
gcloud artifacts repositories list --location=us-east1 --format='table(name,format,location)'
gcloud storage buckets list --format='value(name)'
```

Salida observada: sin clusters, sin instancias, sin discos, sin snapshots, sin IPs reservadas, sin forwarding rules, sin repos de Artifact Registry en `us-east1` y sin buckets listados.

### Nota operativa

Durante una verificacion extendida, `gcloud` solicito habilitar APIs que estaban apagadas. Se revirtio para mantener huella minima:

```bash
gcloud services disable redis.googleapis.com run.googleapis.com cloudfunctions.googleapis.com --quiet
```

Estado final: proyecto sin infraestructura activa de GKE/Compute y sin recursos residuales detectados en los servicios auditados.

## Procedimiento de reactivacion total - 18/04/2026

Este procedimiento deja de nuevo operativo todo el entorno que fue apagado o eliminado. Se debe ejecutar en este orden para evitar errores de dependencia.

### 1) Preparar el entorno local

```bash
gcloud config set project Proyecto3_202300625
gcloud auth list
```

### 2) Crear nuevamente el cluster GKE

```bash
gcloud container clusters create gke-kubevirt-cluster \
  --region=us-east1 \
  --machine-type=n1-standard-2 \
  --num-nodes=1 \
  --enable-nested-virtualization \
  --node-labels=nested-virtualization=enabled \
  --gateway-api=standard

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
kubectl get nodes
```

### 3) Reinstalar KubeVirt

```bash
export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
kubectl get pods -n kubevirt
```

### 4) Reaplicar los manifiestos del proyecto

```bash
kubectl apply -f kube/gateway.yaml
kubectl apply -f kube/go-receiver-deploy.yaml
kubectl apply -f kube/go-receiver-service.yaml
kubectl apply -f kube/rust-api-service.yaml
kubectl apply -f kube/rust-api-deploy.yaml
kubectl apply -f kube/hpa.yaml
kubectl apply -f kube/rust-api-httproute-v2.yaml
kubectl apply -f kube/consumer.yaml
kubectl apply -f kube/grpc-server.yaml
kubectl apply -f kube/go-client.yaml
kubectl apply -f kube/go-client-service.yaml
```

### 5) Verificar que el cluster quedó listo

```bash
kubectl rollout status deployment/go-receiver-deployment --timeout=240s
kubectl rollout status deployment/rust-api-deployment --timeout=240s
kubectl get gateway military-gateway
kubectl get httproute rust-api-httproute
kubectl get pods -A
```

### 6) Recrear la VM externa de Zot

```bash
gcloud compute instances create zot-registry-vm \
  --zone=us-east1-b \
  --machine-type=n1-standard-2 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=zot-registry

gcloud compute firewall-rules create allow-zot-registry \
  --allow tcp:5000 \
  --target-tags zot-registry
```

Luego, dentro de la VM:

```bash
sudo apt-get update
sudo apt-get install -y docker.io openssl
sudo systemctl enable --now docker

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

sudo docker run -d --name zot-registry \
  --restart unless-stopped \
  -p 5000:5000 \
  -v /opt/zot/data:/var/lib/zot \
  -v /opt/zot/config.json:/etc/zot/config.json:ro \
  -v /opt/zot/certs:/etc/zot/certs:ro \
  ghcr.io/project-zot/zot:latest \
  serve /etc/zot/config.json
```

### 7) Reponer datos o imágenes si aplica

Los discos persistentes de PVC fueron eliminados, así que si se requiere recuperar datos de aplicaciones o volúmenes, se deben volver a crear los recursos desde los manifiestos originales y volver a poblar la información manualmente o desde backups/snapshots si existen.

### 8) Verificacion final del entorno reactivado

```bash
kubectl get nodes
kubectl get pods -A
kubectl get gateway military-gateway
kubectl get httproute rust-api-httproute
gcloud compute instances list --filter='name=zot-registry-vm'
```

### Orden resumido de ejecucion

1. Configurar `gcloud` y autenticacion.
2. Crear el cluster GKE.
3. Instalar KubeVirt.
4. Reaplicar manifiestos Kubernetes.
5. Recrear la VM de Zot.
6. Reponer datos si existian volúmenes eliminados.
7. Verificar el estado final.

## Reactivacion correcta (segunda ocasion) - 19/04/2026

Se documento el flujo validado tras reactivar desde cero y resolver errores reales de capacidad en zona (`GCE_STOCKOUT` / `ZONE_RESOURCE_POOL_EXHAUSTED`) y arranque de imagenes.

### 1) Preparacion y APIs requeridas

```bash
gcloud config set project proyecto3-202300625
gcloud auth list

gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  cloudbuild.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com
```

### 2) Crear cluster GKE evitando stockout regional

Nota: en este entorno, dejar `--region` sin fijar `--node-locations` provoco fallos en `us-east1-b/c`. El flujo estable fue forzar nodos en `us-east1-d`.

```bash
gcloud container clusters create gke-kubevirt-cluster \
  --region=us-east1 \
  --node-locations=us-east1-d \
  --machine-type=n1-standard-2 \
  --num-nodes=1 \
  --enable-nested-virtualization \
  --node-labels=nested-virtualization=enabled \
  --gateway-api=standard

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
kubectl get nodes -o wide
```

### 3) Instalar KubeVirt y aplicar fix de scheduling

```bash
export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"

# Fix cuando virt-operator queda Pending en GKE
kubectl -n kubevirt patch deployment virt-operator --type=json -p='[
  {"op":"remove","path":"/spec/template/spec/affinity/nodeAffinity/requiredDuringSchedulingIgnoredDuringExecution"}
]'

kubectl patch kubevirt -n kubevirt kubevirt --type=merge -p '{
  "spec":{
    "infra":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}},
    "workloads":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}}
  }
}'

kubectl delete pod -n kubevirt -l kubevirt.io=virt-operator --wait=false
kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=420s
kubectl get pods -n kubevirt -o wide
```

### 4) Construir y publicar imagenes antes de desplegar

Si se omite este paso, varios pods caen en `ImagePullBackOff`.

```bash
gcloud builds submit ./src/go-client --tag gcr.io/proyecto3-202300625/go-client:v1
gcloud builds submit ./src/go-client --tag gcr.io/proyecto3-202300625/go-receiver:v1
gcloud builds submit ./src/go-server --tag gcr.io/proyecto3-202300625/go-server:v1
gcloud builds submit ./src/consumer --tag gcr.io/proyecto3-202300625/rabbitmq-consumer:v1
gcloud builds submit ./src/rust-api --tag gcr.io/proyecto3-202300625/rust-api:v2
```

### 5) Aplicar manifiestos del proyecto

```bash
kubectl apply -f kube/rabbitmq.yaml
kubectl apply -f kube/gateway.yaml
kubectl apply -f kube/go-receiver-deploy.yaml
kubectl apply -f kube/go-receiver-service.yaml
kubectl apply -f kube/grpc-server.yaml
kubectl apply -f kube/go-client.yaml
kubectl apply -f kube/go-client-service.yaml
kubectl apply -f kube/rust-api-service.yaml
kubectl apply -f kube/rust-api-deploy.yaml
kubectl apply -f kube/hpa.yaml
kubectl apply -f kube/rust-api-httproute-v2.yaml
kubectl apply -f kube/consumer.yaml

kubectl apply -f kube/kubevirt/valkey-pvc.yaml
kubectl apply -f kube/kubevirt/valkey-vm.yaml
kubectl apply -f kube/kubevirt/valkey-service.yaml
kubectl apply -f kube/kubevirt/grafana-cloudinit-secret.yaml
kubectl apply -f kube/kubevirt/grafana-vm.yaml
kubectl apply -f kube/kubevirt/grafana-service.yaml
```

### 6) Escalado recomendado de nodos para VMs + workloads

Con 1 nodo no fue suficiente para VMs de KubeVirt y pods de app.

```bash
gcloud container clusters resize gke-kubevirt-cluster \
  --region=us-east1 \
  --node-pool=default-pool \
  --num-nodes=3 \
  --quiet
```

### 7) VM externa de Zot (ruta estable)

```bash
# Regla de firewall (idempotente)
gcloud compute firewall-rules describe allow-zot-registry >/dev/null 2>&1 || \
gcloud compute firewall-rules create allow-zot-registry \
  --allow tcp:5000 \
  --target-tags zot-registry

# En este ciclo, us-east1-b y us-east1-c tuvieron stockout.
# Configuracion que funciono: us-east1-d + n1-standard-1
gcloud compute instances create zot-registry-vm \
  --zone=us-east1-d \
  --machine-type=n1-standard-1 \
  --image-family=ubuntu-2404-lts-amd64 \
  --image-project=ubuntu-os-cloud \
  --tags=zot-registry
```

### 8) Validacion final

```bash
kubectl get nodes
kubectl get pods -A
kubectl get vm,vmi
kubectl get gateway military-gateway
kubectl get httproute rust-api-httproute
kubectl get hpa rust-api-hpa
gcloud container clusters list --format='table(name,location,status)'
gcloud compute instances list --filter='name=zot-registry-vm' --format='table(name,zone,status,EXTERNAL_IP)'
```

Resultado validado: cluster `RUNNING`, VM `zot-registry-vm` en `RUNNING`, Gateway programado, HTTPrRoute activo, `valkey-vm` y `grafana-vm` en `Running`, y despliegues base de la app en estado operativo.