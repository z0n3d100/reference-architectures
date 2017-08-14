Param(
    [Parameter(Mandatory=$true)]
    [Alias('Subscription')]
    [string]$SUBSCRIPTION_ID,
    [Parameter(Mandatory=$true)]
    [Alias('VNetResourceGroup')]
    [string]$RESOURCE_GROUP_NAME_NET,
    [Parameter(Mandatory=$true)]
    [Alias('MgmtResourceGroup')]
    [string]$RESOURCE_GROUP_NAME_MGMT,
    [Parameter(Mandatory=$true)]
    [Alias('AddsResourceGroup')]
    [string]$RESOURCE_GROUP_NAME_ADDS,    
    [Parameter(Mandatory=$true)]
    [string]$LOCATION
)

$AzureSubscription = Get-AzureRmSubscription -SubscriptionId $SUBSCRIPTION_ID
Select-AzureRmSubscription -SubscriptionId $SUBSCRIPTION_ID

$BUILDINGBLOCKS_ROOT_URI = "https://raw.githubusercontent.com/mspnp/template-building-blocks/v1.0.0/"
$SCRIPT_DIR = $PSScriptRoot

"`n"
"Using $BUILDINGBLOCKS_ROOT_URI to locate templates"
"scripts = $SCRIPT_DIR"
"`n"

# Set URIs for template building blocks
$VIRTUAL_NETWORK_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
$MULTI_VMS_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
$VPN_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"
$EXTENSION_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json"

# Set URIs for templates developed for the RA (not building blcoks) 
$ONPREM_VPN_TEMPLATE_FILE = "${SCRIPT_DIR}/onprem.gateway.azuredeploy.json"

# Set file path for parameter files
$ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.virtualNetwork.parameters.json"
$ONPREM_VM_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.vm.parameters.json"
$ONPREM_ADDS_VM_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.ad.vms.parameters.json"
$ONPREM_ADDS_DC1_EXTENSION_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.ad.dc1.extension.parameters.json"
$ONPREM_ADDS_DC2_EXTENSION_PARAMETERS_FILE = "${SCRIPT_DIR}/onprem.ad.dc2.extension.parameters.json"

# Create the resource groups for the simulated on-prem environment, saving the output for later.
#New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME_NET -Location $LOCATION
New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME_MGMT -Location $LOCATION
#New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME_ADDS -Location $LOCATION

# Create the simulated on-prem virtual network
"Deploying on-prem simulated virtual network..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_NET `
#    -Name 'ra-onprem-vnet-deployment' `
#    -TemplateUri $VIRTUAL_NETWORK_TEMPLATE_URI `
#    -TemplateParameterFile $ONPREM_VIRTUAL_NETWORK_PARAMETERS_FILE

# Create the simulated on-prem Ubuntu jumpbox VM
"Deploying on-prem jumpbox VM..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_MGMT `
    -Name 'ra-onprem-jumpbox-vm-deployment' `
    -TemplateUri $MULTI_VMS_TEMPLATE_URI `
    -TemplateParameterFile $ONPREM_VM_PARAMETERS_FILE

# Create the simulated on-prem AD DS VMs
"Deploying on-prem AD DS VMs..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_ADDS `
#    -Name 'ra-onprem-adds-vm-deployment' `
#    -TemplateUri $MULTI_VMS_TEMPLATE_URI `
#    -TemplateParameterFile $ONPREM_ADDS_VM_PARAMETERS_FILE

# Create the simulated on-prem AD DS directory
"Deploying AD DS Forest..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_ADDS `
#    -Name 'ra-onprem-adds-forest-deployment' `
#    -TemplateUri $EXTENSION_TEMPLATE_URI `
#    -TemplateParameterFile $ONPREM_ADDS_DC1_EXTENSION_PARAMETERS_FILE

# Deploy AD DS on second AD server
#"Deploying AD DS on second AD server..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_ADDS `
#    -Name 'ra-onprem-adds-forest-deployment' `
#    -TemplateUri $EXTENSION_TEMPLATE_URI `
#    -TemplateParameterFile $ONPREM_ADDS_DC2_EXTENSION_PARAMETERS_FILE

# Install VPN gateway
#"Deploying VPN gateway..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_NET `
#    -Name 'ra-onprem-vpn-gw-deployment' `
#    -TemplateFile $ONPREM_VPN_TEMPLATE_FILE `
#    -TemplateParameterFile $ONPREM_VPN_GW_PARAMETERS_FILE