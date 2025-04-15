
@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)

param baseName string

param acrUser string
param acrPass string


@description('Tags to be applied to all resources')
param tags object = {
  environment: 'DEV'
  project: 'BAAD-Bicep'
}

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    baseName: baseName
    tags: tags
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    baseName: baseName
    tags: tags
  }
}

module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    location: location
    baseName: baseName
    tags: tags
  }
}

module containerAppsEnv './modules/containerAppsEnv.bicep' = {
  name: 'containerapps'
  params: {
    location: location
    baseName: baseName
    tags: tags
    storageAccount: 'st${baseName}'
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    infrastructureSubnetId: network.outputs.containerappsSubnetid
  }
}

module containerApp './modules/containerApp.bicep' = {
  name: 'containerApp'
  params: {
    location: location
    baseName: baseName
    tags: tags
    containerAppsEnvironmentId: containerAppsEnv.outputs.containerAppsEnvironmentId
    acrName: 'acr${baseName}'
    containerImage: 'bay2024-nextjs-app:latest'
    acrUser: acrUser
    acrPass: acrPass
  }
}

module privateLinkService './modules/privateLinkService.bicep' = {
  name: 'privatelink'
  params: {
    location: location
    baseName: baseName
    tags: tags
    vnetSubnetId: network.outputs.containerappsSubnetid
    containerAppsDefaultDomainName: containerAppsEnv.outputs.containerAppsEnvironmentDefaultDomain
  }
  dependsOn: [
    containerAppsEnv
  ]
}

module frontDoor './modules/frontdoor.bicep' = {
  name: 'frontdoor'
  params: {
    baseName: baseName
    location: location
    tags: tags
    privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
    frontDoorAppHostName: containerApp.outputs.containerFqdn
  }
  dependsOn: [
    containerApp
    privateLinkService
  ]
}

// Re-Read Private Link Service to get Pending Approval status
module readPrivateLinkService './modules/readPrivateEndpoint.bicep' = {
  name: 'readprivatelink'
  params: {
    privateLinkServiceName: privateLinkService.outputs.privateLinkServiceName
  }

  dependsOn: [
    frontDoor
  ]
}

// Prepare Output
var privateLinkEndpointConnectionId = readPrivateLinkService.outputs.privateLinkEndpointConnectionId
var fqdn = frontDoor.outputs.fqdn

// Outputs
output frontdoor_fqdn string = fqdn
output privateLinkEndpointConnectionId string = privateLinkEndpointConnectionId

output result object = {
  fqdn: fqdn
  privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
  privateLinkEndpointConnectionId: privateLinkEndpointConnectionId
}
