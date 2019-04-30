#!/usr/bin/env bash



openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048  -keyout gatewaycertkey.key -out gatewaycertrequest.csr -subj "/C=US/ST=WA/L=Redmond/O=Microsoft/OU=Gateway/CN=${FQN}.${RGLOCATION}.cloudapp.azure.com/emailAddress=email@email.com"

openssl pkcs12 -export -out gatewaycertificate.pfx -inkey gatewaycertkey.key -in gatewaycertrequest.csr -passout pass:${CERTPASS}


certdata=`base64 gatewaycertificate.pfx --wrap=0`

az group create --name "${RGNAME}" --location "${RGLOCATION}"

az storage account create -n ${STORAGEACCNAME} -g ${RGNAME} -l ${RGLOCATION} --sku standard_LRS

az storage container create -n rsrcontainer  --account-name ${STORAGEACCNAME} --public-access blob

wget https://ceapex.visualstudio.com/0ed5b4a0-21d8-4dc2-8b95-5fdb8449e2bd/_apis/git/repositories/24f3f15d-2961-4ebf-a35d-2146574b7976/Microsoft_Azure_logo_small.png

az storage blob upload -c rsrcontainer -f Microsoft_Azure_logo_small.png -n blobName --account-name ${STORAGEACCNAME}




read -s SQLADMINPASSWORD

az sql server create -l "${RGLOCATION}"  -g $RGNAME -n $SQLSERVERNAME  -u $SQLADMINUSER -p $SQLADMINPASSWORD

az sql db create -s $SQLSERVERNAME -n $SQLSERVERDB -g $RGNAME

connstring=`az sql db show-connection-string --server $SQLSERVERNAME --name $SQLSERVERDB --client ado.net`

connstring=$(echo $connstring | sed "s/<username>/${SQLADMINUSER}/g")
connstring=$(echo $connstring | sed "s/<password>/${SQLADMINPASSWORD}/g")

 az sql server firewall-rule create -g $RGNAME -s $SQLSERVERNAME  -n azureservices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

 sqlcmd -S tcp:${SQLSERVERNAME}.database.windows.net,1433 -d votingdb -U $SQLADMINUSER -P $SQLADMINPASSWORD -N -l 30 -Q "CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT)"
 
 
