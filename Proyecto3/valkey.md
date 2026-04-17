# Implementacion de Valkey sobre KubeVirt para Proyecto3

Este documento registra la implementacion realizada para desplegar **Valkey** en una **VM de KubeVirt** dentro del cluster GKE, con almacenamiento persistente y acceso interno desde los pods del proyecto.

---

## 1. Objetivo

Implementar el componente de persistencia del flujo principal:

- ejecutar Valkey dentro de una VM administrada por KubeVirt,
- asegurar persistencia de datos con un PVC dedicado,
- exponer Valkey mediante un Service interno (`ClusterIP`) para que el consumer pueda escribir metricas.

---

## 2. Arquitectura aplicada

Componentes usados:

1. `PersistentVolumeClaim` para datos (`5Gi`, `ReadWriteOnce`).
2. `VirtualMachine` de KubeVirt con Ubuntu 22.04.
3. `cloud-init` para instalar Docker y levantar contenedor `valkey/valkey`.
4. `Service` interno `valkey-service` en puerto `6379`.

Flujo de acceso:

`Go Consumer (pod) -> valkey-service:6379 -> VM valkey-vm -> contenedor Valkey`

---

## 3. Manifiestos implementados

Archivos:

- `kube/kubevirt/valkey-pvc.yaml`
- `kube/kubevirt/valkey-vm.yaml`
- `kube/kubevirt/valkey-service.yaml`

### 3.1 PVC de datos

Se definio un PVC para persistencia:

- nombre: `valkey-data-pvc`
- capacidad: `5Gi`
- modo: `ReadWriteOnce`

### 3.2 VM de Valkey

La VM `valkey-vm` se configuro con:

- `running: true`
- etiqueta `app: valkey` para seleccion por Service
- interfaz de red con puerto `6379` expuesto
- disco de datos persistente con serial estable `valkeydata`

### 3.3 Provisionamiento con cloud-init

En `cloud-init` se implemento flujo idempotente:

1. instalar `docker.io` y habilitar servicio Docker,
2. detectar disco persistente por ruta estable `/dev/disk/by-id/virtio-valkeydata`,
3. crear filesystem solo si no existe,
4. montar en `/var/lib/valkey-data`,
5. registrar montaje en `/etc/fstab`,
6. levantar contenedor Valkey con:
   - puerto `6379:6379`
   - volumen `/var/lib/valkey-data:/data`
   - `--appendonly yes`
   - `--restart unless-stopped`

### 3.4 Service interno

Se configuro `valkey-service` como `ClusterIP`:

- puerto de servicio: `6379`
- `targetPort: valkey` (nombre del puerto declarado en la interfaz de la VM)
- selector: `app: valkey`

---

## 4. Comandos de despliegue

```bash
kubectl apply -f kube/kubevirt/valkey-pvc.yaml
kubectl apply -f kube/kubevirt/valkey-vm.yaml
kubectl apply -f kube/kubevirt/valkey-service.yaml
```

Verificacion de recursos:

```bash
kubectl get pvc valkey-data-pvc
kubectl get vm valkey-vm
kubectl get vmi
kubectl get svc valkey-service
kubectl get pods -A | rg -i 'virt|valkey'
```

---

## 5. Validacion funcional

### 5.1 Validacion de manifiestos

Se valido con dry-run cliente:

```bash
kubectl apply --dry-run=client \
  -f kube/kubevirt/valkey-pvc.yaml \
  -f kube/kubevirt/valkey-vm.yaml \
  -f kube/kubevirt/valkey-service.yaml
```

Resultado esperado:

```text
persistentvolumeclaim/valkey-data-pvc created (dry run)
virtualmachine.kubevirt.io/valkey-vm created (dry run)
service/valkey-service created (dry run)
```

### 5.2 Prueba de conectividad desde cluster

```bash
kubectl run valkey-test --rm -it --image=redis:7 -- sh
redis-cli -h valkey-service -p 6379 ping
```

Resultado esperado:

```text
PONG
```

### 5.3 Prueba de lectura/escritura

```bash
redis-cli -h valkey-service -p 6379 set test:key ok
redis-cli -h valkey-service -p 6379 get test:key
```

Resultado esperado:

```text
OK
ok
```

---

## 6. Integracion con Consumer

El consumer de RabbitMQ debe usar:

- `VALKEY_ADDR=valkey-service.default.svc.cluster.local:6379`

Con esta configuracion, cada mensaje procesado se almacena en las estructuras de Valkey utilizadas para estadisticas y dashboards.

---

## 7. Troubleshooting rapido

### 7.1 La VM no inicia

```bash
kubectl describe vm valkey-vm
kubectl get events --sort-by=.lastTimestamp | tail -n 40
```

### 7.2 No aparece el Service endpoint

```bash
kubectl get vmi --show-labels
kubectl get endpoints valkey-service -o yaml
```

Validar que la VM tenga etiqueta `app=valkey`.

### 7.3 Valkey no responde

Revisar cloud-init/estado dentro de la VM:

```bash
virtctl console valkey-vm
sudo cloud-init status --long
sudo docker ps
sudo docker logs valkey-server --tail 100
```

### 7.4 Problemas con disco persistente

```bash
lsblk
cat /etc/fstab
mount | rg valkey-data
```

---

## 8. Estado actual

La implementacion de Valkey en KubeVirt queda lista para el flujo del Proyecto 3:

- persistencia habilitada con PVC,
- arranque automatico de Valkey en VM,
- exposicion interna por Service,
- conectividad preparada para consumer y futuras consultas desde Grafana.

---

*Ultima actualizacion: 17/04/2026*  
*Proyecto: Proyecto3_202300625*
