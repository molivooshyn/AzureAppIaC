@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

@description('Id of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Container Image')
param containerImage string

@description('Tags to be applied to all resources')
param tags object = {}

@description('Azure container registry name')
param acrName string


param acrUser string
param acrPass string

// Define names
var appName = '${baseName}-aca-baad-app'

// Obtain the container registry resource
resource acr 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' existing = {
  name: acrName
}

var acrLoginServer = acr.properties.loginServer


resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      secrets: [
        {
          name: '${acrName}-acr-secret'
          value: acrPass
        }
      ]
      ingress: {
        external: true
        targetPort: 3000
      }
      registries: [
        {
          server: acrLoginServer
          username: acrUser
          passwordSecretRef: '${acrName}-acr-secret'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'app'
          image:  '${acrLoginServer}/${containerImage}'
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 3000
              }
              periodSeconds: 10
              failureThreshold: 3
              initialDelaySeconds: 20
            }
          ]
          volumeMounts: [
            {
              volumeName: 'jss-editing-fs-volume'
              mountPath: '/mnt/jss-fs-volume'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 2
      }
      volumes: [
        {
          name: 'jss-editing-fs-volume'
          storageType: 'AzureFile'
          storageName: 'my-azure-files'
        }
      ]
    }
  }
}

output containerFqdn string = containerApp.properties.configuration.ingress.fqdn
