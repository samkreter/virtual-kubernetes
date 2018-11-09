Full Tutorial
https://www.noelbundick.com/posts/frankenetes-running-the-kubernetes-control-plane-on-azure-container-instances/


AZURE_RESOURCE_GROUP=frankenetes

# As of 2.0.25, you have to use 'export' for it to automagically set your storage acct
# https://github.com/Azure/azure-cli/issues/5358
export AZURE_STORAGE_ACCOUNT=frankenetes

az group create -n $AZURE_RESOURCE_GROUP -l eastus
az storage account create -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP

AZURE_STORAGE_KEY=$(az storage account keys list -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP --query '[0].value' -o tsv)


#ETCD
az storage share create -n etcd

az container create -g $AZURE_RESOURCE_GROUP \
  --name etcd \
  --image quay.io/coreos/etcd:v3.2.8 \
  --azure-file-volume-account-name $AZURE_STORAGE_ACCOUNT \
  --azure-file-volume-account-key $AZURE_STORAGE_KEY \
  --azure-file-volume-share-name etcd \
  --azure-file-volume-mount-path /etcd \
  --ports 2379 2389 \
  --ip-address public \
  --command-line '/usr/local/bin/etcd --name=aci --data-dir=/etcd/data --wal-dir=/etcd-wal --listen-client-urls=http://0.0.0.0:2379 --advertise-client-urls=http://frankenetes-etcd.noelbundick.com:2379'

export ETCD_IP="40.112.49.44"

#API Server
az storage share create -n apiserver


az container create -g $AZURE_RESOURCE_GROUP \
  --name apiserver \
  --image gcr.io/google-containers/hyperkube-amd64:v1.9.2 \
  --azure-file-volume-account-name $AZURE_STORAGE_ACCOUNT \
  --azure-file-volume-account-key $AZURE_STORAGE_KEY \
  --azure-file-volume-share-name apiserver \
  --azure-file-volume-mount-path /apiserverdata \
  --ports 6445 \
  --ip-address public \
  --command-line '/apiserver  --advertise-address=0.0.0.0 --allow-privileged=true --apiserver-count=1 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/apiserverdata/log/audit.log --authorization-mode=Node,RBAC --bind-address=0.0.0.0 --etcd-servers=http://$ETCD_IP:2379 --runtime-config=api/all --v=2 --runtime-config=admissionregistration.k8s.io/v1alpha1 --enable-swagger-ui=true --event-ttl=1h --service-node-port-range=30000-32767 --insecure-bind-address=0.0.0.0 --insecure-port 6445'

export API_SERVER_IP="40.114.28.143"

# Controller Manager
az container create -g $AZURE_RESOURCE_GROUP \
  --name controllermanager \
  --image gcr.io/google-containers/hyperkube-amd64:v1.9.2 \
  --command-line '/controller-manager --address=0.0.0.0 --cluster-cidr=10.200.0.0/16 --cluster-name=kubernetes --leader-elect=true --master=http://http://$API_SERVER_IP:6445 --service-cluster-ip-range=10.32.0.0/24 --v=2'

# SCheduler
az container create -g $AZURE_RESOURCE_GROUP \
  --name scheduler \
  --image gcr.io/google-containers/hyperkube-amd64:v1.9.2 \
  --command-line '/scheduler --leader-elect=true --master=http://$API_SERVER_IP:6445 --v=2'


# Set up cluster/context info in a standalone file
kubectl config set-cluster frankenetes --server=http://$API_SERVER_IP:6445 --kubeconfig=frankenetes.kubeconfig
kubectl config set-context default --cluster=frankenetes --kubeconfig=frankenetes.kubeconfig
kubectl config use-context default --kubeconfig=frankenetes.kubeconfig

# Use the kubeconfig & cross your fingers!
export KUBECONFIG=frankenetes.kubeconfig
kubectl version
kubectl api-versions