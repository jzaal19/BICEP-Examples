// az deployment sub create -f .\vwan_deployment.bicep -p .\vwan_deployment.parameters.json -l westeurope -c -o json

targetScope = 'subscription'

@description('vWAN Region Details Array')
param vWANRegionDetails array 

@description('Tags object to be applied on the resources')
param tags object 

@allowed([
  'p'
  'a'
  't'
  'd'
])
@description('Short code for the Environment to be used in the resource naming. Eg: p for Production')
param environment string = 'p'

// resources
resource rg0 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-global-network-${environment}-001'
  location: vWANRegionDetails[0].regionAzureLocation
  tags: tags
}

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = [for (region, i) in vWANRegionDetails: {
  name: 'rg-${region.regionShortName}-network-${tags.costcenter}-${environment}-001'
  location: '${region.regionAzureLocation}'
  tags: tags
}]

resource rgfw 'Microsoft.Resources/resourceGroups@2020-06-01' = [for (region, i) in vWANRegionDetails: {
  name: 'rg-${region.regionShortName}-firewall-${tags.costcenter}-${environment}-001'
  location: '${region.regionAzureLocation}'
  tags: tags
}]

/* module vnets './resources/vNet_simple_no_snets.bicep' = [for (region, i) in vWANRegionDetails: {
  name: 'vnet${i+1}'
  scope: rg[i]
  params: {
    vnetName: 'vnet-${region.regionShortName}-${environment}-firewall-001'
    vnetAddressSpace: region.regionNvaVnetAddressSpace
    tags: tags 
  }
}] */

resource kv 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: 'kv-deploy-p'
  scope: resourceGroup('17a430a4-b126-44e3-ac2c-e2da167eb708', 'rg-weu-security-0451-p-001' )
}

module fortigates './resources/fortigate.bicep' = [for (region, i) in vWANRegionDetails:{
  name: 'fortigate-${region.regionShortName}'
  scope: rgfw[i]
  params: {
    adminPassword: kv.getSecret('fortigateDeployAdminPassword')
    fortiGateNamePrefix: 'nva-fw-${region.regionShortName}-${environment}'
    adminUsername: 'huismanadm'
    instanceType: 'Standard_F4s'
    acceleratedNetworking: true
    publicIPNewOrExisting: 'new'
    publicIPName: 'pip-nva-fw-${region.regionShortName}-${environment}-001'
    publicIPResourceGroup: 'rg-${region.regionShortName}-fortigate-${tags.costcenter}-${environment}-001'
    vnetNewOrExisting: 'new'
    vnetName: 'vnet-${region.regionShortName}-${environment}-fortigate-001'
    vnetResourceGroup: 'rg-${region.regionShortName}-firewall-${tags.costcenter}-${environment}-001'
    vnetAddressPrefix: region.regionNvaVnetAddressSpace
    subnet1Name: 'snet-vnet-${region.regionShortName}-${environment}-external-001'
    subnet1Prefix: region.regionNvaVnetSubnet1AddressSpace
    subnet1StartAddress: region.regionNvaVnetSubnet1StartAddress
    subnet2Name: 'snet-vnet-${region.regionShortName}-${environment}-internal-001'
    subnet2Prefix: region.regionNvaVnetSubnet2AddressSpace
    subnet2StartAddress: region.regionNvaVnetSubnet2StartAddress
    subnet3Name: 'snet-vnet-${region.regionShortName}-${environment}-protected-001'
    subnet3Prefix: region.regionNvaVnetSubnet3AddressSpace
    fortiManager: 'no'
    location: region.regionAzureLocation
  }
}]
