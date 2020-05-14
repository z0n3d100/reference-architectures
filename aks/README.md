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
