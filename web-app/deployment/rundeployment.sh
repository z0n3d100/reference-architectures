#!/usr/bin/env bash

# Creates the resource group that will contain all of our application resources
az group create --name "${RGNAME}" --location "${RGLOCATION}"

# Creates the storage account and public container for the example AD image used by application
az storage account create -n ${STORAGEACCNAME} -g ${RGNAME} -l ${RGLOCATION} --sku standard_LRS
az storage container create -n rsrcontainer --account-name ${STORAGEACCNAME} --public-access blob

# Download the sample AD image
wget ${DEPLOYMENT}Microsoft_Azure_logo_small.png

# Uploads image public container
az storage blob upload -c rsrcontainer -f Microsoft_Azure_logo_small.png -n Microsoft_Azure_logo_small.png --account-name ${STORAGEACCNAME}

# Grab the full URL to the image uplaoded 
resourceurl=`az storage account show -n ${STORAGEACCNAME} | jq -r .primaryEndpoints.blob`rsrcontainer/Microsoft_Azure_logo_small.png

# Creates the SQL Database Server and Database with the provided admin details
az sql server create -l "${RGLOCATION}" -g ${RGNAME} -n ${SQLSERVERNAME}  -u ${SQLADMINUSER} -p ${SQLADMINPASSWORD}
az sql db create -s ${SQLSERVERNAME} -n ${SQLSERVERDB} -g ${RGNAME}

# Set the firewall to allow ALL connections
az sql server firewall-rule create -g $RGNAME -s $SQLSERVERNAME  -n azureservices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Populate the schema in the database
connstring=`az sql db show-connection-string --server $SQLSERVERNAME --name $SQLSERVERDB --client ado.net`
connstring=$(echo ${connstring} | sed "s/<username>/${SQLADMINUSER}/g")
connstring=$(echo ${connstring} | sed "s/<password>/${SQLADMINPASSWORD}/g")
sqlcon="${connstring%\"}"
sqlcon="${sqlcon#\"}"

sqlcmd -S tcp:${SQLSERVERNAME}.database.windows.net,1433 -d ${SQLSERVERDB} -U ${SQLADMINUSER} -P ${SQLADMINPASSWORD} -N -l 30 -Q "CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT)"

# Deploy those resources found in the ARM template
az deployment group create --resource-group ${RGNAME} --template-uri ${DEPLOYMENT}webappdeploy.json --parameters VotingWeb_name=${DNSNAME} SqlConnectionString="$sqlcon"

# Create the CosmosDB Database and Container
cosmosacc=`az cosmosdb list -g ${RGNAME} | jq -r .[0].name`
az cosmosdb database create -d cacheDB -n ${cosmosacc} -g ${RGNAME}
az cosmosdb collection create --name ${cosmosacc} -c cacheContainer -g ${RGNAME} --db-name cacheDB --partition-key-path '/MessageType'