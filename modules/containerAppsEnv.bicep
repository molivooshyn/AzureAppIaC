@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

@description('Subnet resource ID for the Container App environment')
param infrastructureSubnetId string

@description('Name of the log analytics workspace')
param logAnalyticsWorkspaceName string = '${baseName}-log'

@description('Tags to be applied to all resources')
param tags object = {}

param storageAccount string

// Define names
var environmentName = '${baseName}-aca-env'

// Read Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Container Apps Environment
resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
      internal: true
    }
  }
}


resource storageAccountResource 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccount
}
var storageKeys = storageAccountResource.listKeys().keys
var storageAccountKey = storageKeys[0].value

resource managedEnvironments_bay2024nextjsContainerAppEnv_name_my_azure_files 'Microsoft.App/managedEnvironments/storages@2024-10-02-preview' = {
  parent: environment
  name: 'my-azure-files'
  properties: {
    azureFile: {
      accountName: storageAccount
      accountKey: storageAccountKey
      shareName: 'jss-editing-fs'
      accessMode: 'ReadWrite'
    }
  }
}

output containerAppsEnvironmentId string = environment.id
output containerAppsEnvironmentStaticIp string = environment.properties.staticIp
output containerAppsEnvironmentDefaultDomain string = environment.properties.defaultDomain
