# Flujo de despliegue y ejecucion desde cero - Proyecto 3

Este documento unifica el flujo completo real del proyecto, desde un entorno vacio hasta pruebas de carga y apagado total en Google Cloud.

Base del flujo: manifiestos y componentes existentes en el repositorio.

## 1. Alcance

Incluye:

1. Preparacion de herramientas y autenticacion en Google Cloud.
2. Creacion de cluster GKE con Gateway API y virtualizacion anidada.
3. Instalacion de KubeVirt.
4. Build y push de imagenes en registro de contenedores (Zot requerido por el proyecto; GCR solo como contingencia tecnica).
5. Despliegue del stack completo en Kubernetes.
6. Ejecucion de pruebas funcionales y de carga.
7. Apagado parcial y eliminacion total del proyecto en Google Cloud.

No incluye:

1. Creacion automatizada de CI/CD.
2. Configuracion TLS productiva en Gateway API.

## 2. Prerrequisitos

Herramientas minimas instaladas localmente:

1. gcloud
2. kubectl
3. docker
4. skopeo
5. oras (si deseas publicar artifact OCI)
6. python + locust

Variables recomendadas para no repetir valores:

	export PROJECT_ID="proyecto3-202300625"
	export REGION="us-east1"
	export ZONE="us-east1-d"
	export CLUSTER_NAME="gke-kubevirt-cluster"
	export ZOT_VM="zot-registry-vm"
	export ZOT_REGISTRY="35.237.182.41:5000"
	export GCR_REGISTRY="gcr.io/${PROJECT_ID}"

## 3. Fase 0 - Google Cloud desde cero

### 3.1 Login y proyecto

	gcloud init
	gcloud auth list
	gcloud config set project "$PROJECT_ID"

### 3.2 APIs necesarias

	gcloud services enable container.googleapis.com compute.googleapis.com

### 3.3 Crear cluster GKE

	gcloud container clusters create "$CLUSTER_NAME" \
	  --zone="$ZONE" \
	  --machine-type=n1-standard-2 \
	  --num-nodes=3 \
	  --enable-nested-virtualization \
	  --node-labels=nested-virtualization=enabled \
	  --gateway-api=standard

### 3.4 Conectar kubectl al cluster

	gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE"
	gcloud container clusters list --zone="$ZONE" --format="table(name,status)"
	kubectl get nodes -o wide

Validacion minima antes de seguir a Fase 1:

1. El cluster debe estar en estado `RUNNING` (no `PROVISIONING`).
2. `kubectl get nodes` debe listar nodos en `Ready`.
3. Si `kubectl get nodes` responde `No resources found`, espera 1 a 2 minutos y repite 3.4.
4. Si aun aparece `PROVISIONING`, espera y vuelve a ejecutar los comandos de 3.4.

## 4. Fase 1 - Instalar KubeVirt

### 4.1 Instalar operador y CR

	export KUBEVIRT_VERSION="$(curl -fsSL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)"
	kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml"
	kubectl apply -f "https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml"
	kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s

### 4.2 Si virt-operator queda Pending (caso registrado)

	kubectl -n kubevirt patch deployment virt-operator --type=json -p='[
	  {"op":"remove","path":"/spec/template/spec/affinity/nodeAffinity/requiredDuringSchedulingIgnoredDuringExecution"}
	]'

	kubectl patch kubevirt -n kubevirt kubevirt --type=merge -p '{
	  "spec":{
		"infra":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}},
		"workloads":{"nodePlacement":{"nodeSelector":{"kubernetes.io/os":"linux"}}}
	  }
	}'

	kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=300s
	kubectl get pods -n kubevirt

### 4.3 Si KubeVirt queda con `ImagePullBackOff` en `virt-handler` o `virt-operator`

Este caso ocurre cuando el cluster no logra hacer pull estable desde Quay durante bootstrap.

1. Confirmar el error exacto:

	kubectl get pods -n kubevirt -o wide
	kubectl describe pod -n kubevirt <pod_en_fallo>

2. Publicar imagenes de KubeVirt usadas por este flujo en GCR:

	gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io
	for image in virt-operator virt-api virt-controller virt-handler virt-launcher virt-exportserver virt-exportproxy virt-synchronization-controller pr-helper sidecar-shim; do
	  docker pull "quay.io/kubevirt/${image}:v1.8.2"
	  docker tag "quay.io/kubevirt/${image}:v1.8.2" "gcr.io/${PROJECT_ID}/${image}:v1.8.2"
	  docker push "gcr.io/${PROJECT_ID}/${image}:v1.8.2"
	done

3. Reapuntar `virt-operator` a GCR y forzar rollout:

	kubectl -n kubevirt set image deployment/virt-operator virt-operator=gcr.io/${PROJECT_ID}/virt-operator:v1.8.2
	kubectl -n kubevirt set env deployment/virt-operator VIRT_OPERATOR_IMAGE=gcr.io/${PROJECT_ID}/virt-operator:v1.8.2
	kubectl rollout restart deployment/virt-operator -n kubevirt
	kubectl rollout status deployment/virt-operator -n kubevirt --timeout=600s
	kubectl wait --for=condition=Available kubevirt/kubevirt -n kubevirt --timeout=600s

## 5. Fase 2 - Registro de imagenes

Ruta recomendada para despliegue en GKE: usar GCR (`gcr.io/${PROJECT_ID}`) porque evita el bloqueo de confianza TLS en nodos con registros self-signed.

Zot se mantiene como opcion de laboratorio.

### 5.1 Registro requerido (Zot)

Verificar imagenes y tags esperados en Zot:

	# Reemplazar con el endpoint real de Zot cuando se valide el catalogo
	curl -k https://$ZOT_REGISTRY/v2/_catalog
	curl -k https://$ZOT_REGISTRY/v2/go-client/tags/list
	curl -k https://$ZOT_REGISTRY/v2/go-server/tags/list
	curl -k https://$ZOT_REGISTRY/v2/rabbitmq-consumer/tags/list
	curl -k https://$ZOT_REGISTRY/v2/rust-api/tags/list

Nota:

1. El proyecto exige publicar y consumir las imagenes desde Zot.
2. Si debes usar GCR de forma temporal por un bloqueo de certificados, tratalo como contingencia operativa, no como requisito del proyecto.
3. Si publicas versiones nuevas, conserva los tags usados en manifiestos (`v1` y `v2`) o actualiza los YAML.

### 5.2 Opcion alternativa - GCR temporal por contingencia

### 5.2.1 Crear VM Zot y firewall

	gcloud compute instances create "$ZOT_VM" \
	  --zone="$ZONE" \
	  --machine-type=e2-medium \
	  --image-family=ubuntu-2404-lts-amd64 \
	  --image-project=ubuntu-os-cloud \
	  --tags=zot-registry

	gcloud compute firewall-rules create allow-zot-registry \
	  --allow tcp:5000 \
	  --target-tags zot-registry

### 5.2.2 Build y push de imagenes del proyecto

Desde la raiz del repo:

	chmod +x docker/push-zot-images.sh
	./docker/push-zot-images.sh "$ZOT_REGISTRY"

Nota operativa registrada:

1. El push usa skopeo con verificacion TLS configurable.
2. Si GKE falla al hacer pull por certificado self-signed (`x509 unknown authority`), debes confiar la CA en los nodos para seguir cumpliendo el requisito del proyecto.
3. Solo usa GCR para pruebas de contingencia cuando no sea posible estabilizar Zot.

## 6. Fase 3 - Despliegue de plataforma base en K8s

Orden recomendado para evitar dependencias rotas.

### 6.1 RabbitMQ

	kubectl apply -f kube/rabbitmq.yaml
	kubectl rollout status deployment/rabbitmq --timeout=180s

### 6.2 Writers gRPC (Go server) y servicio interno

	kubectl apply -f kube/grpc-server.yaml
	kubectl get svc grpc-server-service
	kubectl get pods -l app=go-server

### 6.3 Go client (REST -> gRPC)

	kubectl apply -f kube/go-client.yaml
	kubectl apply -f kube/go-client-service.yaml
	kubectl rollout status deployment/go-client-deployment --timeout=240s

### 6.4 Rust API + Service + HPA

	kubectl apply -f kube/rust-api-deploy.yaml
	kubectl apply -f kube/rust-api-service.yaml
	kubectl apply -f kube/hpa.yaml
	kubectl rollout status deployment/rust-api-deployment --timeout=240s

### 6.5 Gateway API

	kubectl apply -f kube/gateway.yaml
	kubectl apply -f kube/rust-api-httproute-v2.yaml
	kubectl get gateway military-gateway
	kubectl get httproute rust-api-httproute

### 6.6 Consumer (RabbitMQ -> Valkey)

	kubectl apply -f kube/consumer.yaml
	kubectl rollout status deployment/rabbitmq-consumer-deployment --timeout=240s

## 7. Fase 4 - VMs KubeVirt (Valkey y Grafana)

### 7.1 Valkey

	kubectl apply -f kube/kubevirt/valkey-pvc.yaml
	kubectl apply -f kube/kubevirt/valkey-vm.yaml
	kubectl apply -f kube/kubevirt/valkey-service.yaml

Verificacion:

	kubectl get vm valkey-vm
	kubectl get vmi
	kubectl get svc valkey-service
	kubectl get endpoints valkey-service

### 7.2 Grafana

Aplicar en este orden para cumplir dependencia del secret:

	kubectl apply -f kube/kubevirt/grafana-cloudinit-secret.yaml
	kubectl apply -f kube/kubevirt/grafana-vm.yaml
	kubectl apply -f kube/kubevirt/grafana-service.yaml

Nota:

1. El manifiesto actual de `grafana-vm` usa `emptyDisk` para `datadisk` (no consume `grafana-pvc`).
2. `kube/kubevirt/grafana-pvc.yaml` se conserva como referencia, pero no es requisito para este flujo.

Verificacion:

	kubectl get vm grafana-vm
	kubectl get vmi
	kubectl get svc grafana-service
	kubectl get endpoints grafana-service

Acceso local:

	kubectl port-forward svc/grafana-service 3000:80

Si `port-forward` falla, primero confirma que `grafana-service` tenga endpoints y que el VMI este en `Running`.

URL: http://127.0.0.1:3000

Credenciales registradas:

1. usuario: admin
2. password: 1234

## 8. Fase 5 - Ejecucion y pruebas

### 8.1 Prueba funcional end-to-end

Obtiene primero IP publica del Gateway:

	kubectl get gateway military-gateway -o wide

Ejecuta prueba POST:

	curl -i -X POST http://<GATEWAY_IP>/grpc-202300625 \
	  -H 'Content-Type: application/json' \
	  -d '{"country":"ESP","warplanes_in_air":10,"warships_in_water":5,"timestamp":"2026-04-19T22:20:00Z"}'

Respuesta esperada:

1. HTTP 201 Created
2. mensaje de reporte reenviado correctamente

### 8.2 Prueba de carga con Locust

	cd locust
	LOCUST_PATH=/grpc-202300625 locust -f locustfile.py --host=http://<GATEWAY_IP> //34.49.221.114 por el momento
	//kubectl get gateway military-gateway -o wide  Para obtener la IP

En UI de Locust (http://127.0.0.1:8089):

1. usuarios: 10, 50, 100
2. spawn rate: 10
3. ejecutar 5 a 10 minutos

### 8.3 Verificaciones de salud durante carga

	kubectl get hpa rust-api-hpa -w
	kubectl get pods -l app=rust-api
	kubectl logs -l app=rabbitmq-consumer --tail=50

## 9. Flujo rapido de redeploy

Cuando cambias codigo y vuelves a desplegar:

1. Construir/push imagenes con docker/push-zot-images.sh.
2. Reaplicar manifiestos afectados con kubectl apply -f.
3. Forzar rollout si no cambia tag:

	kubectl rollout restart deployment/rust-api-deployment
	kubectl rollout restart deployment/go-client-deployment
	kubectl rollout restart deployment/go-server-deployment-2
	kubectl rollout restart deployment/go-server-deployment-3
	kubectl rollout restart deployment/rabbitmq-consumer-deployment

## 10. Apagado del proyecto

## 10.1 Opcion A - Solo pausar (reduce costo, no borra cluster)

	gcloud container node-pools list --cluster="$CLUSTER_NAME" --region="$REGION"

	gcloud container clusters resize "$CLUSTER_NAME" \
	  --region="$REGION" \
	  --node-pool=default-pool \
	  --num-nodes=0 \
	  --quiet

Para reactivar:

	gcloud container clusters resize "$CLUSTER_NAME" \
	  --region="$REGION" \
	  --node-pool=default-pool \
	  --num-nodes=1 \
	  --quiet

## 10.2 Opcion B - Botar todo el proyecto en Google Cloud (eliminacion total)

Esta es la ruta recomendada si ya terminaste el laboratorio y no volveras a usar recursos.

Paso 1 - Borrar cluster GKE completo (incluye workloads, Gateway, KubeVirt, VMs dentro del cluster):

	gcloud container clusters delete "$CLUSTER_NAME" --region="$REGION" --quiet

Paso 2 - Borrar VM externa de Zot:

	gcloud compute instances delete "$ZOT_VM" --zone="$ZONE" --quiet

Paso 3 - Borrar firewall de Zot:

	gcloud compute firewall-rules delete allow-zot-registry --quiet

Paso 4 - Verificar que no queden recursos de compute/container:

	gcloud container clusters list --region="$REGION"
	gcloud compute instances list
	gcloud compute firewall-rules list --filter="name=allow-zot-registry"

Paso 5 (opcional) - Borrar el proyecto completo de GCP:

	gcloud projects delete "$PROJECT_ID" --quiet

Advertencia:

1. Este paso elimina todo lo que exista dentro del proyecto, no solo este laboratorio.
2. Solo ejecutar si estas 100 por ciento seguro.

## 11. Checklist final de cierre

Proyecto correctamente eliminado cuando:

1. gcloud container clusters list no muestra el cluster.
2. gcloud compute instances list no muestra zot-registry-vm.
3. no existe regla allow-zot-registry.
4. (si aplicaste borrado total) el proyecto aparece en estado DELETE_REQUESTED o ya no listado.

## 12. Referencias de manifiestos usados

1. kube/rabbitmq.yaml
2. kube/grpc-server.yaml
3. kube/go-client.yaml
4. kube/go-client-service.yaml
5. kube/rust-api-deploy.yaml
6. kube/rust-api-service.yaml
7. kube/hpa.yaml
8. kube/gateway.yaml
9. kube/rust-api-httproute-v2.yaml
10. kube/consumer.yaml
11. kube/kubevirt/valkey-pvc.yaml
12. kube/kubevirt/valkey-vm.yaml
13. kube/kubevirt/valkey-service.yaml
14. kube/kubevirt/grafana-pvc.yaml
15. kube/kubevirt/grafana-cloudinit-secret.yaml
16. kube/kubevirt/grafana-vm.yaml
17. kube/kubevirt/grafana-service.yaml

