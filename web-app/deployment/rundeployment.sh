#!/usr/bin/env bash

az group create --name "${RGNAME}" --location "${RGLOCATION}"

openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048  -keyout gatewaycertkey.key -out gatewaycertrequest.csr -subj "/C=US/ST=WA/L=Redmond/O=Microsoft/OU=Gateway/CN=${DNSNAME}.${RGLOCATION}.cloudapp.azure.com/emailAddress=email@email.com"

openssl pkcs12 -export -out gatewaycertificate.pfx -inkey gatewaycertkey.key -in gatewaycertrequest.csr -passout pass:${CERTPASS}


certdata=`base64 gatewaycertificate.pfx --wrap=0`



az storage account create -n ${STORAGEACCNAME} -g ${RGNAME} -l ${RGLOCATION} --sku standard_LRS

az storage container create -n rsrcontainer  --account-name ${STORAGEACCNAME} --public-access blob

wget ${DEPLOYMENT}Microsoft_Azure_logo_small.png

az storage blob upload -c rsrcontainer -f Microsoft_Azure_logo_small.png -n Microsoft_Azure_logo_small.png --account-name ${STORAGEACCNAME}


resourceurl=`az storage account show -n ${STORAGEACCNAME} | jq -r .primaryEndpoints.blob`rsrcontainer/Microsoft_Azure_logo_small.png




az sql server create -l "${RGLOCATION}"  -g $RGNAME -n $SQLSERVERNAME  -u $SQLADMINUSER -p $SQLADMINPASSWORD

az sql db create -s $SQLSERVERNAME -n $SQLSERVERDB -g $RGNAME

connstring=`az sql db show-connection-string --server $SQLSERVERNAME --name $SQLSERVERDB --client ado.net`

connstring=$(echo $connstring | sed "s/<username>/${SQLADMINUSER}/g")
connstring=$(echo $connstring | sed "s/<password>/${SQLADMINPASSWORD}/g")

az sql server firewall-rule create -g $RGNAME -s $SQLSERVERNAME  -n azureservices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

sqlcmd -S tcp:${SQLSERVERNAME}.database.windows.net,1433 -d votingdb -U $SQLADMINUSER -P $SQLADMINPASSWORD -N -l 30 -Q "CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT)"
 
az group deployment create --resource-group $RGNAME --template-uri ${DEPLOYMENT}webappdeploy.json --parameters VotingWeb_name=${DNSNAME} SqlConnectionString="${connstring}" certData=${certdata} certPassword=${CERTPASS}

cosmosacc=`az cosmosdb list -g ${RGNAME} | jq -r .[0].name`

az cosmosdb database create -d cacheDB -n ${cosmosacc} -g ${RGNAME}

az cosmosdb collection create --name ${cosmosacc} -c cacheContainer -g ${RGNAME} --db-name cacheDB --partition-key-path '/MessageType'
