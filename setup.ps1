$subscription_name = "Production"

$apimName = "apim0000000000020"
$vnetName = "vnet-apim"
$apimSubnetName = "snet-apim"
$resourceGroupName = "rg-apim2"
$location = "northeurope"

Login-AzAccount
Select-AzSubscription -SubscriptionName $subscription_name

# Create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# Create an Azure network security group
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name "nsg-apim"

# Read more details about NSG rules at https://aka.ms/apimvnet

# Create a network security group rule for port 443
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTPS" `
    -Description "Allow HTTPS" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 443

# Enable port 3443
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-3443" `
    -Description "Allow 3443" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 101 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3443

# Update the network security group
$nsg | Set-AzNetworkSecurityGroup

# Create a virtual network
$vnet = New-AzVirtualNetwork `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $vnetName `
    -AddressPrefix "10.0.0.0/16" -Force

# Create a subnet configuration
$apimSubnetConfig = Add-AzVirtualNetworkSubnetConfig `
    -Name $apimSubnetName `
    -AddressPrefix "10.0.0.0/24" `
    -NetworkSecurityGroup $nsg `
    -VirtualNetwork $vnet

# Create a subnet
$apimSubnetConfig | Set-AzVirtualNetwork

# Get the virtual network
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName

# Create a public IP address
$pip = New-AzPublicIpAddress `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name "pip-apim" `
    -AllocationMethod Static `
    -DomainNameLabel $apimName `
    -Force

# Create Premium Azure API Management instance attached to the virtual network
$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $vnet.Subnets[0].Id
  
New-AzApiManagement `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name $apimName `
    -Organization "Contoso" `
    -AdminEmail "admin@contoso.com" `
    -Sku Premium `
    -VirtualNetwork $apimVirtualNetwork `
    -VpnType External `
    -PublicIpAddressId $pip.Id -Verbose -Debug

# {
#   "error": {
#     "code": "InvalidParameters",
#     "message": "Invalid parameter: API Management service deployment into SubnetId 
#     `/subscriptions/<subscriptionid>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/vnet-apim/subnets/snet-apim` 
#     requires a Network Security Group to be associated with it. For recommended configuration and sample templates, please refer to aka.ms/apimvnet",
#     "details": null,
#     "innerError": null
#   }
# }

Test-NetConnection -ComputerName "$apimName.azure-api.net" -Port 443
Test-NetConnection -ComputerName "$apimName.azure-api.net" -Port 3443

# Remove the resource group
Remove-AzResourceGroup -Name $resourceGroupName -Force
