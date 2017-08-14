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

$VIRTUAL_NETWORK_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vnet-n-subnet/azuredeploy.json"
$MULTI_VMS_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/multi-vm-n-nic-m-storage/azuredeploy.json"
$VPN_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/vpn-gateway-vpn-connection/azuredeploy.json"
$EXTENSION_TEMPLATE_URI = "${BUILDINGBLOCKS_ROOT_URI}templates/buildingBlocks/virtualMachine-extensions/azuredeploy.json"

$HUB_VIRTUAL_NETWORK_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.virtualNetwork.parameters.json"
$HUB_VPN_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.gateway.parameters.json"
$HUB_JB_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.vm.parameters.json"
$HUB_ADDS_VM_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.ad.vms.parameters.json"
$HUB_ADDS_DC1_EXTENSION_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.ad.dc1.extension.parameters.json"
$HUB_ADDS_DC2_EXTENSION_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.ad.dc2.extension.parameters.json"
$HUB_FW_VM_PARAMETERS_FILE = "${SCRIPT_DIR}/hub.fw.vm.parameters.json"

# Create resource groups for the hub environment
#New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME_NET -Location $LOCATION
#New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME_MGMT -Location $LOCATION
New-AzureRmResourceGroup -Name $RESOURCE_GROUP_NAME_ADDS -Location $LOCATION

# Create the hub virtual network
"Deploying hub virtual network..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_NET `
#    -Name 'ra-hub-vnet-deployment' `
#    -TemplateUri $VIRTUAL_NETWORK_TEMPLATE_URI `
#    -TemplateParameterFile $HUB_VIRTUAL_NETWORK_PARAMETERS_FILE

# Create the jumpbox vm
"Deploying jumpbox..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_MGMT `
#    -Name 'ra-hub-jb-deployment' `
#    -TemplateUri $MULTI_VMS_TEMPLATE_URI `
#    -TemplateParameterFile $HUB_JB_PARAMETERS_FILE

# Create the vpn gateway and connection to onprem
"Deploying hub gateway and connection..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_NET `
#    -Name 'ra-hub-vpn-deployment' `
#    -TemplateUri $VPN_TEMPLATE_URI `
#    -TemplateParameterFile $HUB_VPN_PARAMETERS_FILE

# Create hub AD DS VMs
"Deploying hub AD DS VMs..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_ADDS `
#    -Name 'ra-hub-adds-vm-deployment' `
#    -TemplateUri $MULTI_VMS_TEMPLATE_URI `
#    -TemplateParameterFile $HUB_ADDS_VM_PARAMETERS_FILE

# Create hub AD DS directory
"Deploying AD DS Forest..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_ADDS `
#    -Name 'ra-hub-adds-forest-deployment' `
#    -TemplateUri $EXTENSION_TEMPLATE_URI `
#    -TemplateParameterFile $HUB_ADDS_DC1_EXTENSION_PARAMETERS_FILE

# Deploy AD DS on second AD server
"Deploying AD DS on second AD server..."
#New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_ADDS `
#    -Name 'ra-hub-adds-forest-deployment' `
#    -TemplateUri $EXTENSION_TEMPLATE_URI `
#    -TemplateParameterFile $HUB_ADDS_DC2_EXTENSION_PARAMETERS_FILE

# Create Ubuntu firewall
"Deploying Ubuntu firewall VM..."
New-AzureRmResourceGroupDeployment -ResourceGroupName $RESOURCE_GROUP_NAME_NET `
    -Name 'ra-hub-fw-vm-deployment' `
    -TemplateUri $MULTI_VMS_TEMPLATE_URI `
    -TemplateParameterFile $HUB_FW_VM_PARAMETERS_FILE