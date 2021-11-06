param location string = resourceGroup().location
param wanname string

@allowed([
  'Standard'
  'Basic'
])
@description('Specifies the type of Virtual WAN.')
param wantype string = 'Standard'

param tags object = {}

resource wan 'Microsoft.Network/virtualWans@2021-03-01' = {
  name: wanname
  location: location
  tags: tags
  properties: {
    type: wantype
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    allowVnetToVnetTraffic: true
    office365LocalBreakoutCategory: 'None'
  }
}

output id string = wan.id
output vwanname string = wan.name
