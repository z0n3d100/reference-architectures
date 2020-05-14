### Prequisites

> Note: execute the following prequisite steps from VSCode for a better experience

1. provision [a regional hub and a spoke virtual networks](./secure-baseline/networking/network-deploy.azcli)
2. create [the BU 0001's app team secure AKS cluster (ID: A0008)](./secure-baseline/network-deploy.azcli)

### Deploy a basic workload

The following example creates the ASPNET Core Docker sample web app and an Ingress object to route to its service.

```bash
# Apply the contents
kubectl apply -f https://github.com/mspnp/reference-architectures/tree/fcp/aks-baseline/aks/secure-baseline/workload/aspnetapp.yaml
```

Now the ASPNET Core webapp sample is all setup. Wait until is ready to process requests running:

```bash
kubectl wait --namespace default \
  --for=condition=ready pod \
  --selector=app=aspnetapp \
  --timeout=90s
```

Test the web app

> open a browser and navigate to http://<APP_GATEWAY_PUBLIC_IP>
