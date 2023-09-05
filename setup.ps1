$subscriptionName = "Production"

$apimName = "apim0000000000001"
$vnetName = "vnet-apim"
$apimSubnetName = "snet-apim"
$resourceGroupName = "rg-apim"
$location = "northeurope"

Login-AzAccount
Select-AzSubscription -SubscriptionName $subscriptionName

# Create a resource group
New-AzResourceGroup -Name $resourceGroupName -Location $location -Force

# Create an Azure network security group
$nsg = New-AzNetworkSecurityGroup `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Name "nsg-apim" -Force

# Read more details about NSG rules at https://aka.ms/apimvnet

# Create a network security group rule for port 443
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-HTTPS" `
    -Description "Allow HTTPS for Client communication to API Management" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange 443

# Enable port 3443
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-3443" `
    -Description "Allow 3443 for Azure Infrastructure Load Balancer" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 101 `
    -SourceAddressPrefix ApiManagement `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange 3443

# Enable port 6390
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-6390" `
    -Description "Allow 6390 for Azure Infrastructure Load Balancer" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 102 `
    -SourceAddressPrefix AzureLoadBalancer `
    -SourcePortRange * `
    -DestinationAddressPrefix VirtualNetwork `
    -DestinationPortRange 6390

# Enable outboung port 443 for Storage
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-Storage-Outbound" `
    -Description "Allow Storage Outbound" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Outbound `
    -Priority 200 `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix Storage `
    -DestinationPortRange 443

# Enable outboung port 1433 for SQL
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-SQL-Outbound" `
    -Description "Allow SQL Outbound" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Outbound `
    -Priority 201 `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix SQL `
    -DestinationPortRange 1433

# Enable outboung port 443 for Key Vault
$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "Allow-KeyVault-Outbound" `
    -Description "Allow Key Vault Outbound" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Outbound `
    -Priority 202 `
    -SourceAddressPrefix VirtualNetwork `
    -SourcePortRange * `
    -DestinationAddressPrefix AzureKeyVault `
    -DestinationPortRange 443

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
Test-NetConnection -ComputerName "$apimName.azure-api.net" -Port 6390

curl "https://$apimName.azure-api.net/"
curl "https://$apimName.azure-api.net/echo/resource?param1=sample"

# Remove the resource group
Remove-AzResourceGroup -Name $resourceGroupName -Force
