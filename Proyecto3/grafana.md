# Implementacion de Grafana sobre KubeVirt para Proyecto3

Este documento registra la implementacion realizada para desplegar **Grafana** en una **VM de KubeVirt** dentro del cluster GKE, con almacenamiento persistente y datasource de Valkey provisionado automaticamente.

---

## 1. Objetivo

Implementar el componente de visualizacion del flujo principal:

- ejecutar Grafana dentro de una VM administrada por KubeVirt,
- asegurar persistencia de configuracion/dashboards con PVC,
- exponer Grafana por Service interno,
- dejar provisionado el datasource hacia Valkey para acelerar la configuracion de paneles.

---

## 2. Arquitectura aplicada

Componentes usados:

1. `PersistentVolumeClaim` para datos de Grafana (`5Gi`, `ReadWriteOnce`).
2. `VirtualMachine` de KubeVirt con Ubuntu 22.04.
3. `cloud-init` para instalar Docker, montar disco persistente y levantar `grafana/grafana`.
4. `Service` interno `grafana-service` (puerto `80` hacia `3000`).
5. Provisioning automatico de datasource `Valkey` via archivo YAML.

Flujo de acceso:

`Browser (port-forward) -> grafana-service:80 -> grafana-vm:3000 -> Grafana`

Flujo de datos:

`Grafana -> redis-datasource plugin -> valkey-service:6379`

---

## 3. Manifiestos implementados

Archivos:

- `kube/kubevirt/grafana-pvc.yaml`
- `kube/kubevirt/grafana-vm.yaml`
- `kube/kubevirt/grafana-service.yaml`

### 3.1 PVC de datos

Se definio un PVC para persistencia:

- nombre: `grafana-data-pvc`
- capacidad: `5Gi`
- modo: `ReadWriteOnce`

### 3.2 VM de Grafana

La VM `grafana-vm` se configuro con:

- `running: true`
- etiqueta `app: grafana` para seleccion por Service
- interfaz de red con puerto `3000` expuesto (nombre `grafana`)
- disco de datos persistente con serial estable `grafanadata`

### 3.3 Provisionamiento con cloud-init

En `cloud-init` se implemento flujo idempotente:

1. instalar `docker.io` y habilitar servicio Docker,
2. detectar disco persistente por ruta estable `/dev/disk/by-id/virtio-grafanadata`,
3. crear filesystem solo si no existe,
4. montar en `/var/lib/grafana-data`,
5. registrar montaje en `/etc/fstab`,
6. recrear contenedor Grafana de forma segura,
7. instalar plugin `redis-datasource` al arranque.

### 3.4 Datasource Valkey provisionado

Se agrega en cloud-init el archivo:

- `/etc/grafana/provisioning/datasources/valkey.yaml`

Con datasource:

- name: `Valkey`
- type: `redis-datasource`
- url: `valkey-service.default.svc.cluster.local:6379`
- access: `proxy`
- default: `true`

El archivo se monta en el contenedor Grafana como volumen de solo lectura para provisioning automatico.

### 3.5 Service interno

Se configuro `grafana-service` como `ClusterIP`:

- puerto de servicio: `80`
- `targetPort: grafana` (puerto nombrado en la interfaz de la VM)
- selector: `app: grafana`

---

## 4. Comandos de despliegue

```bash
kubectl apply -f kube/kubevirt/grafana-pvc.yaml
kubectl apply -f kube/kubevirt/grafana-vm.yaml
kubectl apply -f kube/kubevirt/grafana-service.yaml
```

Verificacion de recursos:

```bash
kubectl get pvc grafana-data-pvc
kubectl get vm grafana-vm
kubectl get vmi
kubectl get svc grafana-service
kubectl get pods -A | rg -i 'virt|grafana'
```

---

## 5. Validacion funcional

### 5.1 Validacion de manifiestos

Se valido con dry-run cliente:

```bash
kubectl apply --dry-run=client \
  -f kube/kubevirt/grafana-pvc.yaml \
  -f kube/kubevirt/grafana-vm.yaml \
  -f kube/kubevirt/grafana-service.yaml
```

Resultado esperado:

```text
persistentvolumeclaim/grafana-data-pvc created (dry run)
virtualmachine.kubevirt.io/grafana-vm created (dry run)
service/grafana-service created (dry run)
```

### 5.2 Prueba de acceso web

```bash
kubectl port-forward svc/grafana-service 3000:80
```

Abrir:

```text
http://localhost:3000
```

Credenciales por defecto (si no se cambiaron):

- usuario: `admin`
- password: `admin`

### 5.3 Verificar datasource provisionado

En Grafana:

1. Ir a `Connections` -> `Data sources`.
2. Confirmar datasource `Valkey`.
3. Probar `Save & test`.

Resultado esperado:

```text
Data source is working
```

---

## 6. Integracion con Valkey y Consumer

Prerequisito:

- `valkey-service` debe estar activo y resolviendo dentro del cluster.

Con esta configuracion:

- consumer escribe metricas en Valkey,
- Grafana consulta Valkey por datasource Redis,
- dashboards pueden construirse sobre llaves y estructuras usadas por el consumer.

---

## 7. Troubleshooting rapido

### 7.1 La VM no inicia

```bash
kubectl describe vm grafana-vm
kubectl get events --sort-by=.lastTimestamp | tail -n 40
```

### 7.2 No aparece endpoint del Service

```bash
kubectl get vmi --show-labels
kubectl get endpoints grafana-service -o yaml
```

Validar etiqueta `app=grafana` en la VM.

### 7.3 Grafana no levanta dentro de la VM

```bash
virtctl console grafana-vm
sudo cloud-init status --long
sudo docker ps
sudo docker logs grafana-server --tail 120
```

### 7.4 Datasource Valkey no conecta

```bash
kubectl get svc valkey-service
kubectl get endpoints valkey-service -o yaml
```

Revisar que URL del datasource sea:

`valkey-service.default.svc.cluster.local:6379`

---

## 8. Estado actual

La implementacion de Grafana en KubeVirt queda lista para el flujo del Proyecto 3:

- persistencia habilitada con PVC,
- arranque automatico de Grafana en VM,
- exposicion interna por Service,
- datasource de Valkey provisionado al inicio,
- base preparada para crear dashboards obligatorios del proyecto.

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*
