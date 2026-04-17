curl -sS -k https://34.73.45.51:5000/v2/_catalog

{"repositories":["golang"]}%   

➜  Proyecto3 git:(main) curl -s http:// 34.73.45.51:5000/v2/_catalog
Client sent an HTTP request to an HTTPS server.
➜  Proyecto3 git:(main) ✗ curl -s http://34.73.45.51:5000/v2/_catalog 
Client sent an HTTP request to an HTTPS server.
➜  Proyecto3 git:(main) ✗ curl -s https://34.73.45.51:5000/v2/_catalog
➜  Proyecto3 git:(main) ✗ curl -sS -k https://34.73.45.51:5000/v2/_catalog
{"repositories":["golang"]}%                                                                                              
➜  Proyecto3 git:(main) ✗ 
➜  Proyecto3 git:(main) ✗ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE    VERSION
gke-gke-kubevirt-cluster-default-pool-02c92b54-lq9n   Ready    <none>   2d6h   v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-05c9670c-bzsv   Ready    <none>   2d6h   v1.35.1-gke.1396002
gke-gke-kubevirt-cluster-default-pool-ff077238-gwt0   Ready    <none>   2d6h   v1.35.1-gke.1396002
➜  Proyecto3 git:(main) ✗ kubectl get pods -l app=rust-api
NAME                                  READY   STATUS    RESTARTS   AGE
rust-api-deployment-849c79b4d-z7tk6   1/1     Running   0          15m
➜  Proyecto3 git:(main) ✗ kubectl logs -l app=rust-api
API Rust escuchando en http://0.0.0.0:8080
➜  Proyecto3 git:(main) ✗ kubectl get hpa rust-api-hpa
NAME           REFERENCE                        TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
rust-api-hpa   Deployment/rust-api-deployment   cpu: 0%/30%   1         3         1          27m
➜  Proyecto3 git:(main) ✗ kubectl get gateway military-gateway
NAME               CLASS                            ADDRESS        PROGRAMMED   AGE
military-gateway   gke-l7-global-external-managed   34.54.104.14   True         46h
➜  Proyecto3 git:(main) ✗ curl -X POST http://34.54.104.14/reports \
     -H "Content-Type: application/json" \
     -d '{
           "country": "ESP",
           "warplanes_in_air": 42,
           "warships_in_water": 14,
           "timestamp": "2026-03-12T20:15:30Z"
         }'
fault filter abort%    