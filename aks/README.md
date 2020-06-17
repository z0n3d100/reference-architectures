### Prequisites

1. An Azure subscription. If you don't have an Azure subscription, you can create a [free account](https://azure.microsoft.com/free).
1. [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
1. Install kubectl 1.18 or later
   ```bash
   sudo az aks install-cli

   # ensure you got a version 1.18 or greater
   kubectl version --client
   ```
1. [Register the AAD-V2 feature for AKS-managed Azure AD](https://docs.microsoft.com/en-us/azure/aks/managed-aad#before-you-begin)
1. Provision [a regional hub and spoke virtual networks](./secure-baseline/networking/network-deploy.azcli)
   > Note: execute this step from VSCode for a better experience
1. Generate a CA self-signed cert

   > :warning: WARNING
   > Do not use the certificates created by these scripts for production. The certificates are provided for demonstration purposes only. For your production cluster, use your security best practices for digital certificates creation and lifetime management.
   > Self-signed certificates are not trusted by default and they can be difficult to maintain. Also, they may use outdated hash and cipher suites that may not be strong. For better security, purchase a certificate signed by a well-known certificate authority.

   Cluster Certificate - AKS Internal Load Balancer

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
         -out traefik-ingress-internal-aks-ingress-contoso-com-tls.crt \
         -keyout traefik-ingress-internal-aks-ingress-contoso-com-tls.key \
         -subj "/CN=*.aks-ingress.contoso.com/O=Contoso Aks Ingress" && \
   rootCertWilcardIngressController=$(cat traefik-ingress-internal-aks-ingress-contoso-com-tls.crt | base64 -w 0)
   ```

   App Gateway Certificate

   ```bash
   openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -out appgw.crt \
          -keyout appgw.key \
          -subj "/CN=app.bicycle.contoso.com/O=Contoso Bicycle" && \
   openssl pkcs12 -export -out appgw.pfx -in appgw.crt -inkey appgw.key -passout pass: && \
   appGatewayListernerCertificate=$(cat appgw.pfx | base64 -w 0)
   ```

1. create [the BU 0001's app team secure AKS cluster (ID: A0008)](./secure-baseline/cluster-deploy.azcli)
   > Note: execute this step from VSCode for a better experience

### Manually deploy the Ingress Controller and a basic workload

The following example creates the Ingress Controller (Traefik),
the ASPNET Core Docker sample web app and an Ingress object to route to its service.

```bash
# Ensure Flux has created the following namespace and then press Ctrl-C
kubectl get ns a0008 -w

# Create the traefik default certificate as secret
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: bicycle-contoso-com-tls-secret
  namespace: a0008
data:
  tls.crt: $(cat traefik-ingress-internal-aks-ingress-contoso-com-tls.crt | base64 -w 0)
  tls.key: $(cat traefik-ingress-internal-aks-ingress-contoso-com-tls.key | base64 -w 0)
type: kubernetes.io/tls
EOF

# Install Traefik ingress controller
kubectl apply -f https://raw.githubusercontent.com/mspnp/reference-architectures/master/aks/workload/traefik.yaml

# Wait for Traefik to be ready
kubectl wait --namespace a0008 \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=traefik-ingress-ilb \
  --timeout=90s

# Check Traefik is handling HTTPS
kubectl -n a0008 run -i --rm --generator=run-pod/v1 --tty alpine --image=alpine -- sh
echo '10.240.4.4 hello.aks-ingress.contoso.com' | tee -a /etc/hosts
apk add openssl
echo | openssl s_client -showcerts -servername hello.aks-ingress.contoso.com -connect hello.aks-ingress.contoso.com:443 2>/dev/null | openssl x509 -inform pem -noout -text
exit 0

# Install the ASPNET core sample web app
kubectl apply -f https://raw.githubusercontent.com/mspnp/reference-architectures/master/aks/workload/aspnetapp.yaml

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

# Validate the router to the workload is configured, SSL offloading and allowing only known Ips
# Please notice only the Azure Application Gateway is whitelisted as known client for
# the workload's router. Therefore, please expect a Http 403 response
# as a way to probe the router has been properly configured

kubectl -n a0008 run -i --rm --generator=run-pod/v1 --tty curl --image=curlimages/curl -- sh
curl --insecure -k -I --resolve bu0001a0008-00.aks-ingress.contoso.com:443:10.240.4.4 https://bu0001a0008-00.aks-ingress.contoso.com
exit 0
```

### Test the web app

```bash
# query the BU 0001's Azure Application Gateway Public Ip

export APPGW_PUBLIC_IP=$(az deployment group show --resource-group rg-enterprise-networking-spokes -n spoke-BU0001A0008 --query properties.outputs.appGwPublicIpAddress.value -o tsv)
```

1. Map the Azure Application Gateway public ip address to the application domain names. To do that, please open your hosts file (C:\windows\system32\drivers\etc\hosts or /etc/hosts) and add the following record in local host file:
   \${APPGW_PUBLIC_IP} app.bicycle.contoso.com

1. In your browser navigate the site anyway (A warning will be present)
   https://app.bicycle.contoso.com/
