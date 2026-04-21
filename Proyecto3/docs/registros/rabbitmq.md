# Despliegue y Verificacion de RabbitMQ en GKE para Proyecto3

Este documento registra la verificacion del estado de RabbitMQ en el cluster de Google Kubernetes Engine (GKE), y el despliegue realizado cuando no se encontraron recursos existentes.

---

## 1. Objetivo

- Verificar si RabbitMQ estaba corriendo en el cluster.
- Si no existia, desplegar RabbitMQ con un servicio llamado `rabbitmq-service` en el puerto `5672`.

---

## 2. Verificacion Inicial

Se consultaron deployments, servicios y pods en todos los namespaces para detectar recursos relacionados con RabbitMQ.

```bash
kubectl get deployment,svc,pod -A | rg -i 'rabbitmq|rabbit'
```

**Resultado:** no se obtuvo salida, por lo que no habia recursos de RabbitMQ desplegados.

Como validacion adicional, se confirmo conectividad con el cluster:

```bash
kubectl get nodes -o wide
```

**Salida observada (resumen):**
```
NAME                                                  STATUS   VERSION
gke-gke-kubevirt-cluster-default-pool-02c92b54-lq9n   Ready    v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-05c9670c-bzsv   Ready    v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-ff077238-gwt0   Ready    v1.35.1-gke.1396002
```

---

## 3. Manifiesto Aplicado

Se creo el archivo `kube/rabbitmq.yaml` con un `Deployment` y un `Service` tipo `ClusterIP`.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
  labels:
    app: rabbitmq
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
        - name: rabbitmq
          image: rabbitmq:3.13
          ports:
            - containerPort: 5672
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq-service
spec:
  type: ClusterIP
  selector:
    app: rabbitmq
  ports:
    - name: amqp
      protocol: TCP
      port: 5672
      targetPort: 5672
```

---

## 4. Despliegue

Comandos ejecutados:

```bash
kubectl apply -f kube/rabbitmq.yaml
kubectl rollout status deployment/rabbitmq --timeout=180s
kubectl get deployment rabbitmq
kubectl get svc rabbitmq-service
```

**Salida observada (resumen):**
```
deployment.apps/rabbitmq created
service/rabbitmq-service created
deployment "rabbitmq" successfully rolled out
```

Estado del deployment:
```
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
rabbitmq   1/1     1            1           7s
```

Estado del servicio:
```
NAME               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
rabbitmq-service   ClusterIP   34.118.231.241   <none>        5672/TCP
```

---

## 5. Validacion Final

Se verifico el pod de RabbitMQ por etiqueta:

```bash
kubectl get pods -l app=rabbitmq -o wide
```

**Salida observada (resumen):**
```
NAME                       READY   STATUS    RESTARTS
rabbitmq-b8db555df-87rqh   1/1     Running   0
```

**Resultado final:** RabbitMQ quedo desplegado y funcionando en el cluster, con el servicio `rabbitmq-service` exponiendo el puerto `5672` dentro de la red del cluster.

---

## 6. Comandos de Verificacion Rapida

```bash
kubectl get deployment rabbitmq
kubectl get svc rabbitmq-service
kubectl get pods -l app=rabbitmq -o wide
```

---

*Fecha de registro: 17/04/2026*
*Proyecto: Proyecto3_202300625*
