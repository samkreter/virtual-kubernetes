# Virtual Kubernetes (Serverless Kubernetes?)

What if I was to tell you that you can have a working Kubernetes cluster up and running within 1 minute completely from scratch and that has unlimitied resources to spawn pods too AND you only pay per second for exactly what resource you use. Yep, this is how to run a working Kubernetes cluster completely on Azure Container Instance. I'm talking everything from the kube-apiserver to the virtual nodes. If you're excited lets get started.

Forgot to mention, the entire setup can happend online within [Azure Cloud Shell](shell.azure.com)

## Prerequisites

- An Azure subscription. Get a [free trial here](https://azure.microsoft.com/en-us/free/)!

## Getting Started

### Setting Up the Persistant Storage

Open either a terminal with the Azure CLI installed or check out [CloudShell](https://shell.azu
re.com/) for a ready-to-go option

First, lets set up some environment variables to make these commands nicer to copy and paste

```sh
export AZURE_RESOURCE_GROUP=<myResourceGroup>
export AZURE_REGION=<eastus>
export AZURE_STORAGE_ACCOUNT=<mystroageaccount> #This must be all lower case or numbers, no special characters
```

1. Create a resource group to hold everything

    az group create -n $AZURE_RESOURCE_GROUP -l $AZURE_REGION

2. Create an Azure Storage Account and get the access key

    az storage account create -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP

    AZURE_STORAGE_KEY=$(az storage account keys list -n $AZURE_STORAGE_ACCOUNT -g $AZURE_RESOURCE_GROUP --query '[0].value' -o tsv)

3. Create the 3 files shares we are going to need.

    az storage share create -n etcd
    az storage share create -n apiserver
    az storage share create -n auth

### Create the ACI credentials file

1. Create an Azure Service Principle so that Virtual Kubelet will be able to create ACIs 

    az ad sp create-for-rbac --name virtual-kubernetes -o table

2. Use the output from the previous command to fill in the values for credentials.json. (tenantId, appId = clientId, password = clientSecret)

3. TODO: Upload to the file share (credentials.json)


### Add the Self Signed Certificate

1. Generate the self signed certificate vk will use when setting up its listening server

    openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem

2. TODO: upload to the file share (cert.pem, key.pem)

### Upload the Kubeconfig for VK

1. TODO: Upload template to fileshare

### Deploy!!

Now we can simple use the ACI yaml file to deploy it

    az container create -g $AZURE_RESOURCE_GROUP -n virtual-k8s -f ./deploy/all-deploy.yaml
