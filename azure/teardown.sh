#!/usr/bin/env bash

set -e

source ./configuration.sh

az group delete --name $STACK_NAME
