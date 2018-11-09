AZURE_RESOURCE_GROUP=frankenetes

# As of 2.0.25, you have to use 'export' for it to automagically set your storage acct
# https://github.com/Azure/azure-cli/issues/5358
export AZURE_STORAGE_ACCOUNT=frankenetes

az group create -n $AZURE_RESOURCE_GROUP -l eastus
az storage account create -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP

AZURE_STORAGE_KEY=$(az storage account keys list -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP --query '[0].value' -o tsv)

#ETCD
az storage share create -n etcd

#API Server
az storage share create -n apiserver

# Auth
az storage share create -n auth



#TODO: generate the self sign certs and upload config to blob storage


#TODO: Deploy the container group


# Set up cluster/context info in a standalone file
kubectl config set-cluster virtualk8s --server=http://$API_SERVER_IP:6445 --kubeconfig=virtualk8s.kubeconfig
kubectl config set-context default --cluster=virtualk8s --kubeconfig=virtualk8s.kubeconfig
kubectl config use-context default --kubeconfig=virtualk8s.kubeconfig

# Use the kubeconfig & cross your fingers!
export KUBECONFIG=virtualk8s.kubeconfig
kubectl version
kubectl api-versions