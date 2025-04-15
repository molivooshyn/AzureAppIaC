@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string

@description('Tags to be applied to all resources')
param tags object = {}

// Define names
var storageAccountName = 'st${baseName}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}
resource storageAccounts_baystoreageaccount_name_default 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
resource Microsoft_Storage_storageAccounts_fileServices_storageAccounts_baystoreageaccount_name_default 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
resource Microsoft_Storage_storageAccounts_queueServices_storageAccounts_baystoreageaccount_name_default 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  parent: storageAccount
  name: 'default' 
  properties: {
    cors: {
      corsRules: []
    }
  }
}
resource Microsoft_Storage_storageAccounts_tableServices_storageAccounts_baystoreageaccount_name_default 'Microsoft.Storage/storageAccounts/tableServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}
resource storageAccounts_baystoreageaccount_name_default_jss_editing_fs 'Microsoft.Storage/storageAccounts/fileServices/shares@2024-01-01' = {
  parent: Microsoft_Storage_storageAccounts_fileServices_storageAccounts_baystoreageaccount_name_default
  name: 'jss-editing-fs' //TODO
  properties: {
    accessTier: 'Hot'
    shareQuota: 102400
    enabledProtocols: 'SMB'
  }
}
