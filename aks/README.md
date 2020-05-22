### Prequisites

1. An Azure subscription. If you don't have an Azure subscription, you can create a [free account](https://azure.microsoft.com/free).
1. [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
1. provision [a regional hub and spoke virtual networks](./secure-baseline/networking/network-deploy.azcli)
> Note: execute this step from VSCode for a better experience
1. create [the BU 0001's app team secure AKS cluster (ID: A0008)](./secure-baseline/network-deploy.azcli)
> Note: execute this step from VSCode for a better experience
1. download the AKS credentails
   ``` bash
   az aks get-credentials -g rg-bu0001a0008 -n <cluster-name> --admin
   ```
### Generate a CA self-signed cert

> :warning:  WARNING
> Do not use the certificates created by these scripts for production. The certificates are provided for demonstration purposes only. For your production cluster, use your security best practices for digital certificates creation and lifetime management.
> Self-signed certificates are not trusted by default and they can be difficult to maintain. Also, they may use outdated hash and cipher suites that may not be strong. For better security, purchase a certificate signed by a well-known certificate authority.

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -out traefik-ingress-internal-bicycle-contoso-com-tls.crt \
        -keyout traefik-ingress-internal-bicycle-contoso-com-tls.key \
        -subj "/CN=*.bicycle.contoso.com/O=Contoso Bicycle"
```

### Manually deploy a basic workload

The following example creates the ASPNET Core Docker sample web app and an Ingress object to route to its service.

```bash
# Create application namespace
kubectl create ns a0008

# Create the traefik default certificate as secret: https://docs.traefik.io/https/tls/#user-defined
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: bicycle-contoso-com-tls-secret
  namespace: a0008
data:
  tls.crt: $(cat traefik-ingress-internal-bicycle-contoso-com-tls.crt | base64 -w 0)
  tls.key: $(cat traefik-ingress-internal-bicycle-contoso-com-tls.key | base64 -w 0)
type: kubernetes.io/tls
EOF

# Install Traefik ingress controller
kubectl apply -f https://raw.githubusercontent.com/mspnp/reference-architectures/master/aks/secure-baseline/traefik.yaml

# Check Traefik is handling HTTPS
kubectl -n a0008 run -i --rm --generator=run-pod/v1 --tty alpine --image=alpine -- sh
apk add openssl
echo | openssl s_client -showcerts -servername bicycle.contoso.com -connect traefik-ingress-service:443 2>/dev/null | openssl x509 -inform pem -noout -text
exit 0

# Apply the contents
kubectl apply -f https://raw.githubusercontent.com/mspnp/reference-architectures/master/aks/secure-baseline/aspnetapp.yaml

# the ASPNET Core webapp sample is all setup. Wait until is ready to process requests running:
kubectl wait --namespace a0008 \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=aspnetapp \
  --timeout=90s

# In this momment your Ingress Controller (Traefik) is reading your Ingress
# resource object configuration, updating its status and creating a router to
# fulfill the new exposed workloads route.
# Please take a look at this and notice that the Address is set with the Internal Load Balancer Ip from
# the configured subnet

kubectl get ingress aspnetapp-ingress -n a0008

# Validate router to the workload is configured, SSL offloading and redirect to Https schema

kubectl -n a0008 run -i --rm --generator=run-pod/v1 --tty alpine --image=alpine -- sh
apk add curl
curl --insecure -H Host:bu0001a0008-00.bicycle.contoso.com https://traefik-ingress-service
curl --insecure -H Host:bu0001a0008-00.bicycle.contoso.com http://traefik-ingress-service
exit 0
```

Test the web app

```bash
curl http://${APP_GATEWAY_PUBLIC_IP_FQDN}
```

> Note: alternatively open a browser and navite to http://${APP_GATEWAY_PUBLIC_IP_FQDN}
