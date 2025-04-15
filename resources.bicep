
@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)
// param baseName string = 'baadapp2025'
param baseName string

@description('Tags to be applied to all resources')
param tags object = {
  environment: 'DEV'
  project: 'BAAD-Bicep'
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    baseName: baseName
    tags: tags
  }
}

module containerRegistry './modules/containerRegistry.bicep' = {
  name: 'containerRegistry'
  params: {
    location: location
    baseName: baseName
    tags: tags
  }
}

