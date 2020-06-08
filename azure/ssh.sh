#!/usr/bin/env bash

set -e

source ./configuration.sh

az webapp ssh --resource-group $STACK_NAME --name $STACK_NAME-backend

