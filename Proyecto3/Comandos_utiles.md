# Comandos utiles para depuracion

Esta hoja resume los comandos mas usados para validar el estado del proyecto, obtener IPs y revisar rapidamente los componentes mas sensibles del despliegue.

## 1. Obtener IPs y endpoints

### 1.1 VM externa de Zot

```bash
gcloud compute instances list --filter='name=zot-registry-vm' --format='table(name,zone,status,EXTERNAL_IP)'
```

Si ya tienes la IP, puedes validar el catalogo de Zot con:

```bash
curl -k https://<IP_ZOT>:5000/v2/_catalog
```

### 1.2 Nodos del cluster GKE

```bash
kubectl get nodes -o wide
```

### 1.3 Gateway y ruta HTTP

```bash
kubectl get gateway military-gateway -o wide
kubectl get httproute rust-api-httproute -o yaml
```

### 1.4 VMs KubeVirt

```bash
kubectl get vm,vmi -o wide
kubectl get vm valkey-vm
kubectl get vm grafana-vm
kubectl get vmi -o wide
```

### 1.5 Grafana por port-forward

```bash
kubectl port-forward svc/grafana-service 3000:80
```

Luego abre:

```text
http://127.0.0.1:3000
```

## 2. Verificacion de recursos

### 2.1 Escalado automatico de Rust

```bash
kubectl get hpa rust-api-hpa -w
```

### 2.2 Estado del gateway

```bash
kubectl get gateway military-gateway -o wide
kubectl describe gateway military-gateway
```

### 2.3 Estado de la ruta HTTP

```bash
kubectl get httproute rust-api-httproute -o yaml
kubectl describe httproute rust-api-httproute
```

### 2.4 Estado de Grafana y Valkey en KubeVirt

```bash
kubectl get vm grafana-vm
kubectl get vmi grafana-vm -o wide
kubectl get vm valkey-vm
kubectl get vmi valkey-vm -o wide
kubectl get svc grafana-service
kubectl get endpoints grafana-service
```

## 3. Logs y diagnostico rapido

### 3.1 Consumer de RabbitMQ

```bash
kubectl logs -l app=rabbitmq-consumer --tail=50 -f
```

### 3.2 Pods relacionados con RabbitMQ

```bash
kubectl get pods -l app=rabbitmq
kubectl describe pod -l app=rabbitmq-consumer
```

### 3.3 Estado general del cluster

```bash
kubectl get pods -A -o wide
kubectl get services -A -o wide
```

## 4. Locust

### 4.1 Ejecutar prueba de carga

```bash
cd locust
LOCUST_PATH=/grpc-202300625 locust -f locustfile.py --host=http://<IP_GATEWAY>
```

Si el Gateway expone HTTPS, usa:

```bash
LOCUST_PATH=/grpc-202300625 locust -f locustfile.py --host=https://<IP_GATEWAY>
```

### 4.2 Acceso a la interfaz web

```text
http://127.0.0.1:8089
```

## 5. Comandos de referencia para Zot

```bash
curl -k https://<IP_ZOT>:5000/v2/_catalog
curl -k https://<IP_ZOT>:5000/v2/go-client/tags/list
curl -k https://<IP_ZOT>:5000/v2/go-server/tags/list
curl -k https://<IP_ZOT>:5000/v2/rabbitmq-consumer/tags/list
curl -k https://<IP_ZOT>:5000/v2/rust-api/tags/list
```

## 6. Resumen rapido por captura

```text
curl-zot-registry-vm.png              -> curl -k https://<IP_ZOT>:5000/v2/_catalog
gcloud_copute_instances_list.png      -> gcloud compute instances list --filter='name=zot-registry-vm' --format='table(name,zone,status,EXTERNAL_IP)'
grafana.png                           -> kubectl port-forward svc/grafana-service 3000:80
kubectl_get_gateway_military-gateway.png -> kubectl get gateway military-gateway -o wide
kubectl_get_hpa_rust-api-hpa.png      -> kubectl get hpa rust-api-hpa -w
kubectl_get_httproute.png             -> kubectl get httproute rust-api-httproute -o yaml
kubectl_get_vms.png                   -> kubectl get vm,vmi -o wide
kubectl_logs_rabbitmq-consumer.png    -> kubectl logs -l app=rabbitmq-consumer --tail=50 -f
kubertl_get_nodes.png                 -> kubectl get nodes -o wide
locust.png                            -> LOCUST_PATH=/grpc-202300625 locust -f locustfile.py --host=http://<IP_GATEWAY>
```
