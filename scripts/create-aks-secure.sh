:

aksname="aks-prod"

# Create the Azure AD application
serverApplicationId=$(az ad app create \
    --display-name "${aksname}Server" \
    --identifier-uris "https://${aksname}Server" \
    --query appId -o tsv)

# Update the application group memebership claims
az ad app update --id $serverApplicationId --set groupMembershipClaims=All

# Create a service principal for the Azure AD application
az ad sp create --id $serverApplicationId

# Get the service principal secret
serverApplicationSecret=$(az ad sp credential reset \
    --name $serverApplicationId \
    --credential-description "AKSPassword" \
    --query password -o tsv)
echo $serverApplicationSecret

az ad app permission add \
    --id $serverApplicationId \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

az ad app permission grant --id $serverApplicationId --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $serverApplicationId

clientApplicationId=$(az ad app create \
    --display-name "${aksname}Client" \
    --native-app \
    --reply-urls "https://${aksname}Client" \
    --query appId -o tsv)
echo $clientApplicationId

az ad sp create --id $clientApplicationId

oAuthPermissionId=$(az ad app show --id $serverApplicationId --query "oauth2Permissions[0].id" -o tsv)

az ad app permission add --id $clientApplicationId --api $serverApplicationId --api-permissions ${oAuthPermissionId}=Scope
az ad app permission grant --id $clientApplicationId --api $serverApplicationId

RGRP=teamResources

tenantId=$(az account show --query tenantId -o tsv)
echo $tenantId

az ad sp create-for-rbac --skip-assignment --name AKSProdSP


az network vnet subnet list --resource-group $RGRP --vnet-name vnet --query "[1].id" --output tsv


#

RGRP=teamResources
vmsubnetid="/subscriptions/91ae9c19-2591-4c54-9c4a-4bb90338d474/resourceGroups/teamResources/providers/Microsoft.Network/virtualNetworks/vnet/subnets/aks-subnet"

SPN_ID="a13472ec-0632-4792-8606-677044e1084f"
SPN_SECRET="c741bb1a-d6e1-4d14-8b03-f57e27484d06"

SNET_ID="/subscriptions/91ae9c19-2591-4c54-9c4a-4bb90338d474/resourceGroups/teamResources/providers/Microsoft.Network/virtualNetworks/vnet/subnets/aks-subnet"

az role assignment create --assignee $SPN_ID --scope $SNET_ID --role Contributor

echo $serverApplicationId
echo $serverApplicationSecret
echo $clientApplicationId
echo $tenantId

az aks create \
    --resource-group $RGRP \
    --name $aksname \
    --node-count 1 \
    --network-plugin azure \
    --vnet-subnet-id $vmsubnetid \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 172.38.0.10 \
    --service-cidr 172.38.0.0/16 \
    --generate-ssh-keys \
    --aad-server-app-id $serverApplicationId \
    --aad-server-app-secret $serverApplicationSecret \
    --aad-client-app-id $clientApplicationId \
    --aad-tenant-id $tenantId \
    --service-principal $SPN_ID \
    --client-secret $SPN_SECRET



# RBAC

#To get cluster admin creds (--admin). Normally gets cluster user creds
az aks get-credentials --resource-group $RGRP --name $aksname --admin

#Get my upn
az ad signed-in-user show --query userPrincipalName -o tsv

# Update the aad-role-bindings.yml - add UPN
kubectl apply -f basic-azure-ad-binding.yaml

#Get creds from the new cluster based ob the role bindings
az aks get-credentials --resource-group $RGRP --name $aksname --overwrite-existing

#Test
kubectl get pods --all-namespaces





