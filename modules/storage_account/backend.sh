#!/bin/bash
# az login from the terminal first
# we must initialize the remote backend server separate from the tf scripts
# ./backend.sh to execute the script

RESOURCE_GROUP_NAME=tfstate-remotebackend
STORAGE_ACCOUNT_NAME=vmssdemobackendrichie
CONTAINER_NAME=tfstate

# create resource group
az group create --name $RESOURCE_GROUP_NAME --location eastus

# create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_ZRS --encryption-services blob

# create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME