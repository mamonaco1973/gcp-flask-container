#!/bin/bash

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Navigate to the 01-gar directory
cd "01-gar" 
echo "NOTE: Building GAR Repository."

if [ ! -d ".terraform" ]; then
    terraform init
fi
terraform apply -auto-approve

# Return to the parent directory
cd ..

# Navigate to the 02-docker directory

cd "02-docker"
echo "NOTE: Building flask container with Docker."

#RESOURCE_GROUP="flask-container-rg"
#ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[?starts_with(name, 'flaskapp')].name | [0]" --output tsv)
#az acr login --name $ACR_NAME
#ACR_REPOSITORY="${ACR_NAME}.azurecr.io/flask-app"
#IMAGE_TAG="flask-app-rc1"
#docker build -t ${ACR_REPOSITORY}:${IMAGE_TAG} . --push

cd ..

# Navigate to the 03-cloudrun directory
cd 03-cloudrun
echo "NOTE: Deploying flask container with cloud run."

if [ ! -d ".terraform" ]; then
    terraform init
fi
terraform apply -auto-approve

# Return to the parent directory
cd ..

# Execute the validation script

#./validate.sh


