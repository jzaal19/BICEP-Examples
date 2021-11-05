param hubVnetConnectionName string

@description('VWAN Hub Name')
param vwanHubName string 

@description('vnet ID to connect')
param vnetId string

param rgName string = resourceGroup().name



resource hubvnetconnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-03-01' = {
  name: '${vwanHubName}/${hubVnetConnectionName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetId
    }
    routingConfiguration: {
      associatedRouteTable: {
        id:  '/subscriptions/6b2706a9-9214-4498-a42c-c19bb6852b59/resourceGroups/rg-global-network-p-001/providers/Microsoft.Network/virtualHubs/${vwanHubName}/hubRouteTables/defaultRouteTable'
      }
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
}

output id string = hubvnetconnection.id
output name string = hubvnetconnection.name
