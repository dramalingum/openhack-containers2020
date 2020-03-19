
# Deploy KV FlexVolume to exiting cluster
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-keyvault-flexvol/master/deployment/kv-flexvol-installer.yaml

# Validate it's working
kubectl get pods -n kv

# Using keyvault-flexvolume in a cluster with pod security policy enabled, so creatng the following policy that enables the spec required for keyvault-flexvolume to work -
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-keyvault-flexvol/master/deployment/kv-flexvol-psp.yaml

# Add service principal credentials as Kubernetes secrets accessible by the Key Vault FlexVolume driver.

SPN_ID="1380b4e6-7cf9-4ffc-b083-4f9943d36134"
SPN_SECRET="1a79ab28-c7ad-4fe0-93eb-cfce1625d5a1"

kubectl create secret generic kvcreds --from-literal clientid=$SPN_ID --from-literal clientsecret=SPN_SECRET --type=azure/kv

# Ensurng this service principal has all the required permissions to access content in the Key Vault instance.

KV_NAME="T1VeyVault"
az role assignment create --role Reader --assignee $SPN_ID --scope /subscriptions/91ae9c19-2591-4c54-9c4a-4bb90338d474/resourcegroups/teamResources/providers/Microsoft.KeyVault/vaults/T1VeyVault

# Returned...
#{
#  "canDelegate": null,
#  "id": "/subscriptions/91ae9c19-2591-4c54-9c4a-4bb90338d474/resourcegroups/teamResources/providers/Microsoft.KeyVault/vaults/T1VeyVault/providers/Microsoft.Authorization/roleAssignments/64846ae3-80a7-4890-9058-e2d00acbfb02",
#  "name": "64846ae3-80a7-4890-9058-e2d00acbfb02",
#  "principalId": "46a0748b-f839-4ee4-8a44-b74f8a239136",
#  "principalType": "ServicePrincipal",
#  "resourceGroup": "teamResources",
#  "roleDefinitionId": "/subscriptions/91ae9c19-2591-4c54-9c4a-4bb90338d474/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7",
#  "scope": "/subscriptions/91ae9c19-2591-4c54-9c4a-4bb90338d474/resourcegroups/teamResources/providers/Microsoft.KeyVault/vaults/T1VeyVault",
#  "type": "Microsoft.Authorization/roleAssignments"
#}

# Assign key vault permissions to your service principal
az keyvault set-policy -n $KV_NAME --key-permissions get --spn $SPN_ID
az keyvault set-policy -n $KV_NAME --secret-permissions get --spn $SPN_ID
az keyvault set-policy -n $KV_NAME --certificate-permissions get --spn $SPN_ID


