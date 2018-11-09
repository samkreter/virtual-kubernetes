

export AZURE_RESOURCE_GROUP=frankenetes
export ACI_REGION=eastus
export AZURE_STORAGE_ACCOUNT=frankenetes

az group create -n $AZURE_RESOURCE_GROUP -l $ACI_REGION
az storage account create -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP

AZURE_STORAGE_KEY=$(az storage account keys list -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP --query '[0].value' -o tsv)

# Create the file shares
az storage share create -n etcd
az storage share create -n apiserver
az storage share create -n auth

#Set up Service Principle to access ACI
az ad sp create-for-rbac --name virtual-kubernetes -o table

# TODO: Create credentials file for aci and upload to the blob (credentials.json)
export AZURE_TENANT_ID=<Tenant>
export AZURE_CLIENT_ID=<AppId>
export AZURE_CLIENT_SECRET=<Password>


#TODO: generate the self sign certs and upload config to blob storage (cert.pem, key.pem)

#TODO: Upload the localhost kubeconfig so VK knows how to talk with the API server (kubeconfig)


#TODO: Deploy the container group


# Set up cluster/context info in a standalone file
kubectl config set-cluster virtualk8s --server=http://$API_SERVER_IP:6445 --kubeconfig=virtualk8s.kubeconfig
kubectl config set-context default --cluster=virtualk8s --kubeconfig=virtualk8s.kubeconfig
kubectl config use-context default --kubeconfig=virtualk8s.kubeconfig

# Use the kubeconfig & cross your fingers!
export KUBECONFIG=virtualk8s.kubeconfig
kubectl version
kubectl api-versions