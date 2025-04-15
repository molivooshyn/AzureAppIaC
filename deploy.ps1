
# Habilitar salida detallada de errores
$ErrorActionPreference = "Stop"

######################################
## Define Variables
$BASE_NAME = "baadscript"
$LOCATION = "westus2"
######################################

## Resource Group & Deployment
$RESOURCE_GROUP_NAME = "$BASE_NAME-rg"
$DEPLOYMENT_NAME = "$BASE_NAME-deployment-$(Get-Date -UFormat %s)"

## Register Providers
az provider register --wait --namespace Microsoft.App
az provider register --wait --namespace Microsoft.ContainerService
az provider register --wait --namespace Microsoft.Cdn

## Create Resource Group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
Write-Host "Resource Group created: $RESOURCE_GROUP_NAME"

# Deploy Container Registry
$result = az deployment group create --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME --template-file prerequisites.bicep --parameters baseName=$BASE_NAME --query properties.outputs.result --output json
Write-Host "Container Registry created"

# Deploying app image
Write-Host "Deploying image to acr"
Start-Sleep -Seconds 300
Write-Host "Image deployed to acr"

# Verify existing image tag
$tag = az acr repository show-tags `
  --name acrbaadscript `
  --repository bay2024-nextjs-app `
  --query "[?@=='latest']" `
  --output tsv

Write-Host "Image tag found: $tag"

$acrUser=az acr credential show --name acrbaadscript --query username -o tsv
$acrPass=az acr credential show --name acrbaadscript --query "passwords[0].value" -o tsv

Write-Host "ACR Credentials obtained"
Write-Host "Deploying implementation..."

$result = az deployment group create --resource-group $RESOURCE_GROUP_NAME --name $DEPLOYMENT_NAME --template-file main.bicep --parameters baseName=$BASE_NAME acrUser=$acrUser acrPass=$acrPass --query properties.outputs.result --output json
$resultObject = $result | ConvertFrom-Json

$PRIVATE_LINK_ENDPOINT_CONNECTION_ID = $resultObject.value.privateLinkEndpointConnectionId
$FQDN = $resultObject.value.fqdn
$PRIVATE_LINK_SERVICE_ID = $resultObject.value.privateLinkServiceId

# FALLBACK: Private Link Service approval
# if (-not $PRIVATE_LINK_ENDPOINT_CONNECTION_ID) {
#     Write-Host "Failed to get privateLinkEndpointConnectionId"
#     while (-not $PRIVATE_LINK_ENDPOINT_CONNECTION_ID) {
#         Write-Host "- retrying..."
#         $PRIVATE_LINK_ENDPOINT_CONNECTION_ID = az network private-endpoint-connection list --id $PRIVATE_LINK_SERVICE_ID --query "[0].id" -o tsv
#         Start-Sleep -Seconds 5
#     }
# }

## Approve Private Link Service
Write-Host "Private link endpoint connection ID: $PRIVATE_LINK_ENDPOINT_CONNECTION_ID"
az network private-endpoint-connection approve --id $PRIVATE_LINK_ENDPOINT_CONNECTION_ID --description "(Frontdoor) Approved by CI/CD"

Write-Host "...Deployment FINISHED!"
Write-Host "Please wait a few minutes until endpoint is established..."
Write-Host "--- FrontDoor FQDN: https://$FQDN ---"



