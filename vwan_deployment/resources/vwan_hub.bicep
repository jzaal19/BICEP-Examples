param location string = resourceGroup().location
param hubname string

@description('Specifies the Virtual Hub Address Prefix.')
param hubaddressprefix string = '10.70.0.0/16'

@description('Virtual WAN ID')
param vwanid string

@description('Specifies the Virtual Hub SKU')
param hubtype string = 'Standard'

param tags object = {}

resource hub 'Microsoft.Network/virtualHubs@2021-03-01' = {
  name: hubname
  location: location
  tags: tags
  properties: {
    addressPrefix: hubaddressprefix
    sku: hubtype
    virtualWan: {
      id: vwanid
    }
  }
}

output id string = hub.id
output name string = hub.name
output vhubaddress string = hub.properties.addressPrefix
