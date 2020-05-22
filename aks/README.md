### Prequisites

> Note: execute the prequisite steps 1 and 2 from VSCode for a better experience

1. provision [a regional hub and spoke virtual networks](./secure-baseline/networking/network-deploy.azcli)
2. create [the BU 0001's app team secure AKS cluster (ID: A0008)](./secure-baseline/network-deploy.azcli)
3. download the AKS credentails
   ``` bash
   az aks get-credentials -g rg-bu0001a0008 -n <cluster-name> --admin
   ```
4. install Traefik
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/mspnp/reference-architectures/master/aks/secure-baseline/traefik.yaml
   ```
5. query the BU 0001's Azure Application Gateway Public Ip FQDN
   ``` bash
   export APP_GATEWAY_PUBLIC_IP_FQDN=$(az deployment group show --resource-group rg-enterprise-networking-spokes -n spoke-BU0001A0008 --query properties.outputs.appGatewayPublicIpFqdn.value -o tsv)
   ```

### Manually deploy a basic workload

The following example creates the ASPNET Core Docker sample web app and an Ingress object to route to its service.

```bash
# Create application namespace
kubectl create ns a0008

# Apply the contents
kubectl apply -f https://raw.githubusercontent.com/mspnp/reference-architectures/master/aks/secure-baseline/workload/aspnetapp.yaml
```

Now the ASPNET Core webapp sample is all setup. Wait until is ready to process requests running:

```bash
kubectl wait --namespace a0008 \
  --for=condition=ready pod \
  --selector=app=aspnetapp \
  --timeout=90s
```

Test the web app

```bash
curl http://${APP_GATEWAY_PUBLIC_IP_FQDN}
```

> Note: alternatively open a browser and navite to http://${APP_GATEWAY_PUBLIC_IP_FQDN}
