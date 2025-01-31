#!/bin/bash

CONTAINER_APP="flask-container-app"
RESOURCE_GROUP="flask-container-rg"

# Get the service URL
SERVICE_URL=$(az containerapp show --name "$CONTAINER_APP" --resource-group "$RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" --output tsv)

# Check if the SERVICE_URL is empty
if [[ -z "$SERVICE_URL" || "$SERVICE_URL" == "None" ]]; then
  echo "ERROR: Service URL for $CONTAINER_APP is not found. Please check if the service exists and try again."
  exit 1
fi

# Wait for ingress to be ready
echo "NOTE: Waiting for the API to be reachable..."

while true; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://$SERVICE_URL/candidate/John%20Smith")

    if [[ "$HTTP_STATUS" == "200" ]]; then
        echo "NOTE: API is now reachable."
        break
    else
        echo "WARNING: API is not yet reachable (HTTP $HTTP_STATUS). Retrying..."
        sleep 30
    fi
done

# Move to the directory and run the test script
cd ./02-docker
SERVICE_URL="https://$SERVICE_URL"
echo "NOTE: Testing the Azure Container App Solution."
echo "NOTE: URL for Azure Container App is $SERVICE_URL/gtg?details=true"
./test_candidates.py "$SERVICE_URL"

cd ..
