$STORAGE_ACCOUNT_QUEUE="queue"
$STORAGE_ACCOUNT_CONTAINER="container"
$RESOURCE_GROUP="my-containerapps"
$LOCATION="canadacentral"
$CONTAINERAPPS_ENVIRONMENT="containerapps-env"
$STORAGE_ACCOUNT_CONTAINER="mycontainer"
$AZURE_STORAGE_ACCOUNT="yourstorage"

az login

Write-Host "====Install Extension===="

az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App

Write-Host "====Create Resource Group===="

az group create `
  --name $RESOURCE_GROUP `
  --location "$LOCATION"

Write-Host "====Create Container App ENV===="

az containerapp env create `
  --name $CONTAINERAPPS_ENVIRONMENT `
  --resource-group $RESOURCE_GROUP `
  --location "$LOCATION"

Write-Host "====Create Storage Account===="

az storage account create `
  --name $AZURE_STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --location "$LOCATION" `
  --sku Standard_RAGRS `
  --kind StorageV2

$AZURE_STORAGE_KEY=(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $AZURE_STORAGE_ACCOUNT --query '[0].value' --out tsv)
echo $AZURE_STORAGE_KEY

Write-Host "====Create Storage Container===="

az storage queue create -n $STORAGE_ACCOUNT_QUEUE --fail-on-exist --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY

Write-Host "====Create Stroge Queue===="

az storage container create -n $STORAGE_ACCOUNT_CONTAINER --fail-on-exist --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY

Write-Host "====Create Dapr Component===="
az containerapp env dapr-component set -g $RESOURCE_GROUP --name $CONTAINERAPPS_ENVIRONMENT --yaml .\redis.yaml --dapr-component-name redis

az containerapp env dapr-component set `
    --name $CONTAINERAPPS_ENVIRONMENT  --resource-group $RESOURCE_GROUP  `
    --dapr-component-name queueinput `
    --yaml input.yaml

az containerapp env dapr-component set `
    --name $CONTAINERAPPS_ENVIRONMENT  --resource-group $RESOURCE_GROUP  `
    --dapr-component-name bloboutput `
    --yaml output.yaml

az containerapp create `
   --name bindingtest `
   --resource-group $RESOURCE_GROUP `
   --environment $CONTAINERAPPS_ENVIRONMENT `
   --image kevin808/daprbinding-python:latest `
   --target-port 6000 `
   --ingress external  `
   --min-replicas 1 `
   --max-replicas 1 `
   --enable-dapr `
   --dapr-app-port 6000 `
   --dapr-app-id bindingtest 
