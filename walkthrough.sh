

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

#Auth
#       cert.pem
#       key.pem
#       credentials.json
#       kubeconfig


# Generate the self sign certs and upload config to file share (cert.pem, key.pem)
openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem

az storage file upload \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --share-name "auth" \
    --source "./cert.pem" \
    --path "cert.pem"

az storage file upload \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --share-name "auth" \
    --source "./key.pem" \
    --path "key.pem"

# Upload the service principle credentials so that virtual kublet can create aci instances
az storage file upload \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --share-name "auth" \
    --source "./credentials.json" \
    --path "credentials.json"

# Upload the localhost kubeconfig so VK knows how to talk with the API server (kubeconfig)
az storage file upload \
    --account-name $AZURE_STORAGE_ACCOUNT \
    --account-key $AZURE_STORAGE_KEY \
    --share-name "auth" \
    --source "./kubeconfig" \
    --path "kubeconfig"


#TODO: Deploy the container group


# Set up cluster/context info in a standalone file
kubectl config set-cluster virtualk8s --server=http://$API_SERVER_IP:6445 --kubeconfig=virtualk8s.kubeconfig
kubectl config set-context default --cluster=virtualk8s --kubeconfig=virtualk8s.kubeconfig
kubectl config use-context default --kubeconfig=virtualk8s.kubeconfig

# Use the kubeconfig & cross your fingers!
export KUBECONFIG=virtualk8s.kubeconfig
kubectl version
kubectl api-versions