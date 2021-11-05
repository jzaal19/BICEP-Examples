
param vnetName string = 'ADM-AUE-PRD-VNET1'
param vnetAddressSpace string = '10.0.0.0/22'
param tags object = {}


resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    enableVmProtection: false
    enableDdosProtection: false
  }
}

output vnetNameOutput string = vnetName
output id string = vnet.id
