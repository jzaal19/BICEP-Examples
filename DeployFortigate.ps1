Login-AzAccount

# Set subscription context
Set-AzContext -Subscription "huisman-general-d-001"

# Create Resourcegroup for Fortigate Next Gen Firewall Deployment
New-AzResourceGroup -Name "rg-sas-fortigate-0451-d-001" -Location "Southeast Asia" -Tag @{applicationType="Network"; environment="d"; costcenter="0451"}

# Deploy Fortigate Next Gen Firewall HA Active-Active
$pwd_secure_string = Read-Host "Enter a Password" -AsSecureString
New-AzResourceGroupDeployment -TemplateFile "fortigate.json"  `
    -Name "DeployFortigateNextGenFW_HA_Active_Active" -TemplateParameterFile "fortigate-parametersCN.json"  `
    -ResourceGroupName "rg-sas-fortigate-0451-d-001" `
    -adminPassword $pwd_secure_string

# Create vWAN virtual Hub VNET Connection
$rgName = "rg-global-network-p-001"
$virtualHubName = "vwan-vhub-sas-p-001"
Set-AzContext -Subscription "huisman-general-d-001"
$remoteVirtualNetwork = Get-AzVirtualNetwork -Name "vnet-sas-d-fortigate-001" -ResourceGroupName "rg-sas-fortigate-0451-d-001"
Set-AzContext -Subscription "huisman-general-p-001"
$rt1 = Get-AzVHubRouteTable -ResourceGroupName $rgName -VirtualHubName $virtualHubName -Name "defaultRouteTable"
#$rt2 = Get-AzVHubRouteTable -ResourceGroupName $rgName -VirtualHubName $virtualHubName -Name "noneRouteTable"
$route1 = New-AzStaticRoute -Name "route1" -AddressPrefix @("10.240.88.0/24", "10.240.89.0/24") -NextHopIpAddress "10.240.84.68"
$routingconfig = New-AzRoutingConfiguration -AssociatedRouteTable $rt1.Id -Label @("default") -Id @($rt1.Id) -StaticRoute @($route1)
New-AzVirtualHubVnetConnection -ResourceGroupName $rgName -VirtualHubName $virtualHubName -Name "vwan-vhub-sas-p-001-to-vnet-sas-d-fortigate-001" -RemoteVirtualNetwork $remoteVirtualNetwork -RoutingConfiguration $routingconfig

###### Add Route to VNET COnnection #############
# Route Name: NVAFWVNETS
# Destination type: CIDR
# Destination prefix: 10.240.80.0/20
# Next Hop: vwan-vhub-sas-p-001-to-vnet-sas-d-fortigate-001

# Create VM to Fortigate Internal Subnet to access mgmt and add statis route
$VMLocalAdminUser = "huismanadm"
$VMLocalAdminSecurePassword = Read-Host "Enter a Password" -AsSecureString
$LocationName = "southeastasia"
$ResourceGroupName = "rg-sas-fortigate-0451-d-001"
$ComputerName = "az-sas01-d-fg01"
$VMName = "vm-az-sas01-d-fg01"
$VMSize = "Standard_B2s"

$NetworkName = "vnet-sas-d-fortigate-001"
$NICName = "nic-lan-vm-az-sas01-d-fg01-001"

$Vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[1].Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose

# Create Spoke VNETs
Set-AzContext -Subscription "huisman-general-d-001"
$protectedSubnet1  = New-AzVirtualNetworkSubnetConfig -Name "snet-vnet-sas-d-spoke-001-protected-001"  -AddressPrefix "10.240.88.0/27"
$remoteVirtualNetwork1 = New-AzVirtualNetwork -Name "vnet-sas-d-spoke-001" -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix "10.240.88.0/24" -Subnet $protectedSubnet1
$protectedSubnet2  = New-AzVirtualNetworkSubnetConfig -Name "snet-vnet-sas-d-spoke-002-protected-001"  -AddressPrefix "10.240.89.0/27"
$remoteVirtualNetwork2 = New-AzVirtualNetwork -Name "vnet-sas-d-spoke-002" -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix "10.240.89.0/24" -Subnet $protectedSubnet2

# Create UDR
$RouteTableName = “rt-snet-vnet-sas-d-spoke-001-protected-001-routetonva-001”
$RouteTable = New-AzRouteTable  -Name $RouteTableName -ResourceGroupName $ResourceGroupName -Location $LocationName
$RouteTable | Add-AzRouteConfig -Name "RouteToNVA" -AddressPrefix "0.0.0.0/0" -NextHopType VirtualAppliance -NextHopIpAddress "10.240.84.68" | Set-AzRouteTable
# $RouteTable | Add-AzRouteConfig -Name "BypassNVA" -AddressPrefix "10.240.84.71/32" -NextHopType VirtualNetworkGateway | Set-AzRouteTable
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $remoteVirtualNetwork1 -Name $protectedSubnet1.Name -AddressPrefix $protectedSubnet1.AddressPrefix -RouteTableId $RouteTable.Id | Set-AzVirtualNetwork
# Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $remoteVirtualNetwork1 -Name $protectedSubnet1.Name -AddressPrefix $protectedSubnet1.AddressPrefix -RouteTableId $null | Set-AzVirtualNetwork

# Create VNET Peerings
Set-AzContext -Subscription "huisman-general-d-001"
$NetworkName = "vnet-sas-d-fortigate-001"
$ResourceGroupName = "rg-sas-fortigate-0451-d-001"
$Vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName
Add-AzVirtualNetworkPeering -Name "vnet-sas-d-fortigate-001-to-vnet-sas-d-spoke-001" -VirtualNetwork $Vnet -RemoteVirtualNetworkId $remoteVirtualNetwork1.Id
Add-AzVirtualNetworkPeering -Name "vnet-sas-d-spoke-001-to-vnet-sas-d-fortigate-001" -VirtualNetwork $remoteVirtualNetwork1 -RemoteVirtualNetworkId $Vnet.Id
Get-AzVirtualNetworkPeering -ResourceGroupName $ResourceGroupName -VirtualNetworkName $NetworkName | Select-Object PeeringState

Add-AzVirtualNetworkPeering -Name "vnet-sas-d-fortigate-001-to-vnet-sas-d-spoke-002" -VirtualNetwork $Vnet -RemoteVirtualNetworkId $remoteVirtualNetwork2.Id
Add-AzVirtualNetworkPeering -Name "vnet-sas-d-spoke-002-to-vnet-sas-d-fortigate-001" -VirtualNetwork $remoteVirtualNetwork2 -RemoteVirtualNetworkId $Vnet.Id
Get-AzVirtualNetworkPeering -ResourceGroupName $ResourceGroupName -VirtualNetworkName $NetworkName | Select-Object PeeringState

# Add routes to Fortigate (CLI)
<# config router static
edit 6
set dst 10.80.0.0 255.255.0.0
set gateway 10.240.84.65
set device "port2"
set comment "vwan-vhub-sas-p-001"
end
config router static
edit 6
set dst 10.81.0.0 255.255.0.0
set gateway 10.240.84.65
set device "port2"
set comment "vnet-sas-p-production-001"
end
config router static
edit 7
set dst 10.87.0.0 255.255.0.0
set gateway 10.240.84.65
set device "port2"
set comment "vnet-sas-a-acceptation-001"
end
config router static
edit 8
set dst 10.88.0.0 255.255.0.0
set gateway 10.240.84.65
set device "port2"
set comment "vnet-sas-t-test-001"
end
config router static
edit 9
set dst 10.89.0.0 255.255.0.0
set gateway 10.240.84.65
set device "port2"
set comment "vnet-sas-d-development-001"
end

config router static
edit 10
set dst 10.240.88.0 255.255.255.0
set gateway 10.240.84.65
set device "port2"
set comment "vnet-sas-d-spoke-001"
end
config router static
edit 11
set dst 10.240.89.0 255.255.255.0
set gateway 10.240.84.65
set device "port2"
set comment "vnet-sas-d-spoke-002"
end #>

# Create Firewall Policy to allow VNET2VNET traffic
<# config firewall policy
    edit 1
        set name "V2V Traffic"
        set uuid 52d7b364-3da6-51ec-6112-95d5efbb0cb6
        set srcintf "port2"
        set dstintf "port2"
        set action accept
        set srcaddr "all"
        set dstaddr "all"
        set schedule "always"
        set service "RDP"
        set logtraffic all
        set nat enable
    next
end #>

# Create VM to Fortigate Internal Subnet to access mgmt and add statis route
$VMLocalAdminUser = "huismanadm"
$VMLocalAdminSecurePassword = Read-Host "Enter a Password" -AsSecureString
$LocationName = "southeastasia"
$ResourceGroupName = "rg-sas-fortigate-0451-d-001"
$ComputerName = "az-sas01-d-fg02"
$VMName = "vm-az-sas01-d-fg02"
$VMSize = "Standard_B2s"

$NetworkName = "vnet-sas-d-spoke-001"
$NICName = "nic-lan-vm-az-sas01-d-fg02-001"

$Vnet = Get-AzVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName
$NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id

$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2019-Datacenter' -Version latest

New-AzVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose