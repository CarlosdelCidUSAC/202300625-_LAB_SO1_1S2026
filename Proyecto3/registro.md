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
  --machine-type=n2-standard-4 \
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
gke-kubevirt-cluster  us-east1  1.35.1-gke.1396002  34.73.152.152  n2-standard-4  1.35.1-gke.1396002  3          RUNNING  IPV4
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

### Opcion A: Pausa parcial (mantener el clúster)

Reduce el node pool a 0 nodos para evitar costo de VMs. El control plane del clúster sigue existiendo y puede generar costo minimo de administracion.

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

Para reactivar:

```bash
gcloud container clusters resize gke-kubevirt-cluster \
  --region=us-east1 \
  --node-pool=default-pool \
  --num-nodes=1 \
  --quiet

gcloud container clusters get-credentials gke-kubevirt-cluster --region=us-east1
kubectl get nodes
```

### Opcion B: Apagado total (minimizar costos al maximo)

Elimina el clúster completo. Para volver, hay que crearlo otra vez y reinstalar KubeVirt.

```bash
# Apagar total
gcloud container clusters delete gke-kubevirt-cluster --region=us-east1 --quiet
```

Para reactivar (crear desde cero):

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

## VM externa para Zot Container Registry

Para exponer Zot fuera del clúster, se puede usar una VM Linux externa con Docker. En este caso Zot corre como contenedor y escucha en `5000`.

### 1) Crear la VM y abrir el puerto

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

Created [https://www.googleapis.com/compute/v1/projects/proyecto3-202300625/zones/us-east1-b/instances/zot-registry-vm].
NAME             ZONE        MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP  STATUS
zot-registry-vm  us-east1-b  e2-medium                  10.142.0.6   34.73.45.51  RUNNING

Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/proyecto3-202300625/global/firewalls/allow-zot-registry]. 
Creating firewall...done.                                                                                                              
NAME                NETWORK  DIRECTION  PRIORITY  ALLOW     DENY  DISABLED
allow-zot-registry  default  INGRESS    1000      tcp:5000        False

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