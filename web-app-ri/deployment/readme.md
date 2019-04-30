# Web application Deployment
Open an azure cloud shell from the portal.


#### Step 1 Create  the environment variables to run the deployment script
The RGLOCATION should be in the right format. Some examples of valid locations are **westus, eastus, northeurope, westeurope, eastasia, southeastasia, northcentralus, southcentralus, centralus, eastus2, westus2, japaneast, japanwest, brazilsouth**. The DNSNAME and STORAGEACCNAME should be **unique**. You will test them after this step.


```
export RGLOCATION=yourLocation
export SQLSERVERNAME=yourSqlServerName
export SQLSERVERDB=yousqlSqlServerDb
export SQLADMINUSER=yoursqlAdminUser
export DNSNAME=uniquednsnameOfGateway
export STORAGEACCNAME=yourstorageaccountName
```

#### Step 2 Check if the dns name of gateway is available and is valid

Enter the bellow commands. If the Dns name is not valid or not available go back and change the DNSNAME value.

```
token=`az account get-access-token | jq -r .accessToken`

curl -H "Authorization: Bearer ${token}" "https://management.azure.com/subscriptions/d0d422cd-e446-42aa-a2e2-e88806508d3b/providers/Microsoft.Network/locations/${RGLOCATION}/CheckDnsNameAvailability?domainNameLabel=${DNSNAME}&api-version=2018-11-01"
```

#### Step 3 Check if storage account name is valid and is available

Enter the below command. If the storage account is not available or not valid go back on step 1 and change the STORAGEACCNAME value.

```
az storage account check-name -n ${STORAGEACCNAME}
```





2. Enter the password for certificate and for the sql server admin

###### Note: enter passwords for certificate and sql server admin and hit enter

```
read -s CERTPASS
read -s SQLADMINPASSWORD
```

az storage account check-name -n votingweb

## Option 1
run the deployment script

```
.\deploy.sh
```

## Option 2
run below manual steps

### Step 1: Generate the self signed certificate for usage with application gateway

###### Note: self signed certificates should only be used for testing purposes.

Open an Azure bash cloud shell and execute the following commands



1. Generates the certificate request and the private key

```

mkdir deploymentwebapp
cd deploymentwebapp

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048  -keyout gatewaycertkey.key -out gatewaycertrequest.csr -subj "/C=US/ST=WA/L=Redmond/O=Microsoft/OU=Gateway/CN=${FQN}.${RGLOCATION}.cloudapp.azure.com/emailAddress=email@email.com"
```
2.Generates the certificate pfx file


certificate is generated

```
openssl pkcs12 -export -out gatewaycertificate.pfx -inkey gatewaycertkey.key -in gatewaycertrequest.csr -passout pass:${CERTPASS}
```

### Step 2: Deploy Sql server, Sql database and creates table for the application

1. Creates azure resource group and sets the sql server name, sql server database name and sql admin user

```
az group create --name "${RGNAME}" --location "${RGLOCATION}"
```

###### Note: enter sql admin password and hit enter
```
read -s SQLADMINPASSWORD
```

creates sql server sql database and gets the connection string
```
 az sql server create -l "${RGLOCATION}"  -g "${RGNAME}" -n "${SQLSERVERNAME}"  -u "${SQLADMINUSER}" -p "${SQLADMINPASSWORD}"

 az sql db create -s $SQLSERVERNAME -n $SQLSERVERDB -g $RGNAME

 connstring=`az sql db show-connection-string --server $SQLSERVERNAME --name $SQLSERVERDB --client ado.net`

 connstring=$(echo $connstring | sed "s/<username>/${SQLADMINUSER}/g")
 connstring=$(echo $connstring | sed "s/<password>/${SQLADMINPASSWORD}/g")

```
opens the firewall for azure services
```
  az sql server firewall-rule create -g $RGNAME -s $SQLSERVERNAME  -n azureservices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
```
creates the database table
```
sqlcmd -S tcp:${SQLSERVERNAME}.database.windows.net,1433 -d votingdb -U $SQLADMINUSER -P $SQLADMINPASSWORD -N -l 30 -Q "CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT)"
```
