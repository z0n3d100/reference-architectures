# Web application Deployment
Open an azure cloud shell from the portal.


#### Step 1 Create  the environment variables to run the deployment script.

Open an azure cloud shell and run below commands.

**Note: ** RGLOCATION should be in the right format. Some examples of valid locations are **westus, eastus, northeurope, westeurope, eastasia, southeastasia, northcentralus, southcentralus, centralus, eastus2, westus2, japaneast, japanwest, brazilsouth**. The DNSNAME and STORAGEACCNAME should be **unique and valid**. You will test uniqueness and validity of them after this step.
```
export DEPLOYMENT=https://raw.githubusercontent.com/mspnp/reference-architectures/carlos/webappra/web-app/deployment/
export RGNAME=resourceGroupName
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




#### Step 4 Enter the passwords for certificate and for the sql server administrator

**Note:** Sql administrator has a minimum password size of 8 characters minimum and other requirements. Check https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-2017 for Sql administrator password requirements


**Note:** The script will generate a self signed certificate for the application gateway. Self signed certificates  should only be used for testing purposes.

```
read -s CERTPASS
```
```
read -s SQLADMINPASSWORD
```

#### Step 5 From the azure cloud shell create a directory for deployment download the deployment script and run it

```
mkdir deployweb
cd deploywb
wget ${DEPLOYMENT}rundeployment.sh
```
```
.\rundeployment.sh
```
