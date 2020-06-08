# Get this from 'az login'
export SUBSCRIPTION_NAME=<set_this>
export REGION='West Europe'

export STACK_NAME=azure-managed-docker-example

export BACKEND_CONTAINER=azdockerexample-backend
export FRONTEND_CONTAINER=azdockerexample-frontend

# Change this to something secure!
export DB_USERNAME=azdockerexample
export DB_PASSWORD=SuperRand0m-String!

# Do not edit beyond this line

# https://docs.microsoft.com/en-us/cli/azure/format-output-azure-cli?view=azure-cli-latest#set-the-default-output-format
export OUTPUT_FORMAT=none
export STACK_NAME_COMPATIBLE=`echo $STACK_NAME | sed -e 's/[^A-Za-z0-9]//g'`
