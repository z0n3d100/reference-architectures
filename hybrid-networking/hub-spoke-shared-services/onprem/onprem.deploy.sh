#!/bin/bash
while [ $# -gt 0 ]
do
  key="$1"
  case $key in
    -l|--location)
      LOCATION="$2"
      shift
      ;;
    -n|--netresourcegroup)
      RESOURCE_GROUP_NAME_NET="$2"
      shift
      ;;
    -a|--addsresourcegroup)
      RESOURCE_GROUP_NAME_ADDS="$2"
      shift
      ;;      
    -m|--mgmtresourcegroup)
      RESOURCE_GROUP_NAME_MGMT="$2"
      shift
      ;;
    -s|--subscription)
      SUBSCRIPTION_ID="$2"
      shift
      ;;
    *)
      ;;
  esac
  shift
done

BUILDINGBLOCKS_ROOT_URI="https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

echo
echo "Using ${BUILDINGBLOCKS_ROOT_URI} to locate templates"
echo "scripts=${SCRIPT_DIR}"
echo

# Set URIs for building block templates
VIRTUAL_NETWORK_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
MULTI_VMS_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
VPN_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"
EXTENSION_TEMPLATE_URI="${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json"

# Set URIs for ARM templates created for this solution (not building blocks)
ONPREM_VPN_TEMPLATE_FILE="${SCRIPT_DIR}/onprem.gateway.azuredeploy.json"

# Set URIs for parameter files
ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.virtualNetwork.parameters.json"
ONPREM_JB_VM_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.vm.parameters.json"
ONPREM_ADDS_VM_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.ad.vms.parameters.json"
ONPREM_ADDC1_EXTENSION_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.ad.dc1.extension.parameters.json"
ONPREM_ADDC2_EXTENSION_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.ad.dc2.extension.parameters.json"
ONPREM_VPN_GW_PARAMETERS_FILE="${SCRIPT_DIR}/onprem.gateway.parameters.json"

# Create the resource groups for the simulated on-prem environment, saving the output for later.
ONPREM_NETWORK_RESOURCE_GROUP_OUTPUT=$(az group create --name $RESOURCE_GROUP_NAME_NET --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1
ONPREM_ADDS_RESOURCE_GROUP_OUTPUT=$(az group create --name $RESOURCE_GROUP_NAME_ADDS --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1
ONPREM_MGMT_RESOURCE_GROUP_OUTPUT=$(az group create --name $RESOURCE_GROUP_NAME_MGMT --location $LOCATION --subscription $SUBSCRIPTION_ID --json) || exit 1

# Create the simulated on-prem virtual network
echo "Deploying on-prem simulated virtual network..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME_NET --name "ra-onprem-vnet-deployment" \
--template-uri $VIRTUAL_NETWORK_TEMPLATE_URI --parameters @$ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE 

# Create the simulated on-prem Ubuntu VM
echo "Deploying on-prem Ubuntu VM..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME_MGMT --name "ra-onprem-vm-jb-deployment" \
--template-uri $MULTI_VMS_TEMPLATE_URI --parameters @$ONPREM_JB_VM_PARAMETERS_FILE

# Create the simulated on-prem ADDS VMs
echo "Deploying on-prem ADDS VMs..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME_ADDS --name "ra-onprem-vm-adds-deployment" \
--template-uri $MULTI_VMS_TEMPLATE_URI --parameters @$ONPREM_ADDS_VM_PARAMETERS_FILE

# Configure DC1 as domain controller
echo "Deploying AD forest..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME_ADDS --name "ra-onprem-vm-dc1-adds-deployment" \
--template-uri $EXTENSION_TEMPLATE_URI --parameters @$ONPREM_ADDC1_EXTENSION_PARAMETERS_FILE

# Configure DC2 as domain controller
echo "Joining DC2 to forest..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME_ADDS --name "ra-onprem-vm-dc2-adds-deployment" \
--template-uri $EXTENSION_TEMPLATE_URI --parameters @$ONPREM_ADDC2_EXTENSION_PARAMETERS_FILE

# Install VPN gateway
echo "Deploying VPN gateway..."
az group deployment create --resource-group $RESOURCE_GROUP_NAME_NET --name "ra-onprem-vpn-gw-deployment" \
--template-file $ONPREM_VPN_TEMPLATE_FILE --parameters $ONPREM_VPN_GW_PARAMETERS_FILE