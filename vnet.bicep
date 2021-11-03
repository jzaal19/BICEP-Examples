// ========== vnet.bicep ==========

// targetScope = 'resourceGroup'  -  default value

param virtualNetworkName string
param location string = resourceGroup().location

resource myvnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.241.0.0/24'
      ]
    } 
    subnets: [
      {
        name: 'snet-vnet-weu-d-standard-001'
        properties: {
          addressPrefix: '10.241.0.0/27'
        }
      }
    ]
  }
}
