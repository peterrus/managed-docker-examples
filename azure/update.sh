#!/usr/bin/env bash

set -e

source ./configuration.sh

echo "[I] Logging into Azure and setting region"
az account set --subscription $SUBSCRIPTION_NAME --output $OUTPUT_FORMAT
az group create --name $STACK_NAME --location "$REGION" --output $OUTPUT_FORMAT 

echo "[I] Building and tagging backend image"
docker build backend -t $BACKEND_CONTAINER:latest
docker tag $BACKEND_CONTAINER:latest $STACK_NAME_COMPATIBLE.azurecr.io/$BACKEND_CONTAINER:latest

echo "[I] Building and tagging frontend image"
docker build frontend -t $FRONTEND_CONTAINER:latest
docker tag $FRONTEND_CONTAINER:latest $STACK_NAME_COMPATIBLE.azurecr.io/$FRONTEND_CONTAINER:latest

echo "[I] Pushing backend image to container registry"
docker push $STACK_NAME_COMPATIBLE.azurecr.io/$BACKEND_CONTAINER:latest

echo "[I] Pushing frontend image to container registry"
docker push $STACK_NAME_COMPATIBLE.azurecr.io/$FRONTEND_CONTAINER:latest

echo "[I] Done"
echo "[I] Frontend can be reached at (port 80):"
az webapp show --resource-group $STACK_NAME --name $STACK_NAME-frontend | jq -r .defaultHostName
echo "[I] Backend can be reached at (port 80):"
az webapp show --resource-group $STACK_NAME --name $STACK_NAME-backend | jq -r .defaultHostName