
@minLength(3)
@maxLength(24)
param name string = 'sajzaaltest001'
param language string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
param storageSKU string = 'Standard_LRS'

var containerName = 'images'

resource sacc 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: name
  location: language
  sku: {
    name: storageSKU
  }
  kind: 'StorageV2'
}

resource sacon 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${sacc.name}/default/${containerName}'
}
