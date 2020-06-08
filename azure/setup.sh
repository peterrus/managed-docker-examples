#!/usr/bin/env bash
set -e

source ./configuration.sh

echo "[W] Do not run this again before deleting the whole resource group first. This script is not idempotent."

echo "[I] Building and tagging backend image"
docker build backend -t $BACKEND_CONTAINER:latest
docker tag $BACKEND_CONTAINER:latest $STACK_NAME_COMPATIBLE.azurecr.io/$BACKEND_CONTAINER:latest

echo "[I] Building and tagging frontend image"
docker build frontend -t $FRONTEND_CONTAINER:latest
docker tag $FRONTEND_CONTAINER:latest $STACK_NAME_COMPATIBLE.azurecr.io/$FRONTEND_CONTAINER:latest

echo "[I] Logging into Azure"
az account set --subscription $SUBSCRIPTION_NAME --output $OUTPUT_FORMAT

echo "[I] Creating Resourcegroup in region"
az group create --name $STACK_NAME --location "$REGION" --output $OUTPUT_FORMAT

echo "[I] Creating container registry on Azure"
az acr create --name $STACK_NAME_COMPATIBLE --resource-group $STACK_NAME --sku Basic --admin-enabled true --output $OUTPUT_FORMAT

echo "[I] Logging local docker into container registry"
az acr credential show --name $STACK_NAME_COMPATIBLE | jq .passwords[0].value -r | docker login --password-stdin $STACK_NAME_COMPATIBLE.azurecr.io --username $STACK_NAME_COMPATIBLE

echo "[I] Pushing backend image to container registry"
docker push $STACK_NAME_COMPATIBLE.azurecr.io/$BACKEND_CONTAINER:latest

echo "[I] Pushing frontend image to container registry"
docker push $STACK_NAME_COMPATIBLE.azurecr.io/$FRONTEND_CONTAINER:latest

echo "[I] Creating MySQL server and database"
az mysql server create --resource-group $STACK_NAME --name $STACK_NAME-db-server --admin-user $DB_USERNAME --admin-password $DB_PASSWORD --backup-retention 31 --ssl-enforcement Enabled --storage-size 5120 --auto-grow Disabled --sku-name B_Gen5_1 --output $OUTPUT_FORMAT
az mysql server firewall-rule create --resource-group $STACK_NAME --server $STACK_NAME-db-server --name "AllowAllWindowsAzureIps" --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --output $OUTPUT_FORMAT
az mysql db create --resource-group $STACK_NAME --server-name $STACK_NAME-db-server --name $STACK_NAME_COMPATIBLE --output $OUTPUT_FORMAT
# Optional delete lock for db. Prevents accidental deletion
#az lock create --resource-group $STACK_NAME --resource $STACK_NAME-db-server --name $STACK_NAME-db-server-lock --lock-type CanNotDelete --resource-type Microsoft.DBforMySQL/servers --output $OUTPUT_FORMAT

echo "[I] Creating AppService Plan"
az appservice plan create --name $STACK_NAME-appserviceplan --resource-group $STACK_NAME --sku B1 --is-linux --output $OUTPUT_FORMAT

echo "[I] Creating backend AppService"
az webapp create --resource-group $STACK_NAME --plan $STACK_NAME-appserviceplan --name $STACK_NAME-backend --deployment-container-image-name $STACK_NAME_COMPATIBLE.azurecr.io/$STACK_NAME-backend:latest --output $OUTPUT_FORMAT
az webapp config container set --name $STACK_NAME-backend --resource-group $STACK_NAME --docker-custom-image-name $STACK_NAME_COMPATIBLE.azurecr.io/$BACKEND_CONTAINER:latest --docker-registry-server-url https://$STACK_NAME_COMPATIBLE.azurecr.io --docker-registry-server-user $STACK_NAME_COMPATIBLE --docker-registry-server-password `az acr credential show --name $STACK_NAME_COMPATIBLE | jq .passwords[0].value -r` --output $OUTPUT_FORMAT
az webapp config set --name $STACK_NAME-backend --resource-group $STACK_NAME --always-on true --output $OUTPUT_FORMAT
az webapp log config --docker-container-logging filesystem --web-server-logging filesystem --resource-group $STACK_NAME --name $STACK_NAME-backend --output $OUTPUT_FORMAT

echo "[I] Enabling automatic redeploy on registry push for backend AppService"
az webapp deployment container config -e true --resource-group $STACK_NAME --name $STACK_NAME-backend --output $OUTPUT_FORMAT
az acr webhook create -n backendpush -r $STACK_NAME_COMPATIBLE --uri `az webapp deployment container config -e true --resource-group $STACK_NAME --name $STACK_NAME-backend | jq -r .CI_CD_URL` --actions push --scope "$BACKEND_CONTAINER:latest" --output $OUTPUT_FORMAT

echo "[I] Setting environment variables on backend AppService"
az webapp config appsettings set --resource-group $STACK_NAME --name $STACK_NAME-backend --output $OUTPUT_FORMAT --settings \
    DATABASE_URL="mysql://$DB_USERNAME@$STACK_NAME-db-server:$DB_PASSWORD@$STACK_NAME-db-server.mysql.database.azure.com/$STACK_NAME_COMPATIBLE?ssl_ca=BaltimoreCyberTrustRoot.crt.pem" \
    WEBSITES_PORT=80 \
    FLASK_APP=app.py \
    FLASK_ENV=production

echo "[I] Creating frontend AppService"
az webapp create --resource-group $STACK_NAME --plan $STACK_NAME-appserviceplan --name $STACK_NAME-frontend --deployment-container-image-name $STACK_NAME_COMPATIBLE.azurecr.io/$STACK_NAME-frontend:latest --output $OUTPUT_FORMAT
az webapp config container set --name $STACK_NAME-frontend --resource-group $STACK_NAME --docker-custom-image-name $STACK_NAME_COMPATIBLE.azurecr.io/$FRONTEND_CONTAINER:latest --docker-registry-server-url https://$STACK_NAME_COMPATIBLE.azurecr.io --docker-registry-server-user $STACK_NAME_COMPATIBLE --docker-registry-server-password `az acr credential show --name $STACK_NAME_COMPATIBLE | jq .passwords[0].value -r` --output $OUTPUT_FORMAT

echo "[I] Enabling automatic redeploy on registry push for frontend AppService"
az webapp deployment container config -e true --resource-group $STACK_NAME --name $STACK_NAME-frontend --output $OUTPUT_FORMAT
az acr webhook create -n frontendpush -r $STACK_NAME_COMPATIBLE --uri `az webapp deployment container config -e true --resource-group $STACK_NAME --name $STACK_NAME-frontend | jq -r .CI_CD_URL` --actions push --scope "$FRONTEND_CONTAINER:latest" --output $OUTPUT_FORMAT

echo "[I] Setting APP_URL to frontend on backend AppService"
az webapp config appsettings set --resource-group $STACK_NAME --name $STACK_NAME-backend --output $OUTPUT_FORMAT --settings \
    APP_URL=`az webapp show --resource-group $STACK_NAME --name $STACK_NAME-frontend | jq -r .defaultHostName`

echo "[I] Done"
echo "[I] Frontend can be reached at (port 80):"
az webapp show --resource-group $STACK_NAME --name $STACK_NAME-frontend | jq -r .defaultHostName
echo "[I] Backend can be reached at (port 80):"
az webapp show --resource-group $STACK_NAME --name $STACK_NAME-backend | jq -r .defaultHostName
