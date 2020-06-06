### Configuration, TODO: split out to separate file

# Set to a profile you have configured earlier using 'ecs-cli configure profile'
export PROFILE_NAME='personal'
export REGION='eu-central-1'
export CLUSTER_NAME='aws-managed-docker-example'
# Set to a keypair you have created earlier (using 'aws ec2 create-key-pair --key-name docker-symfony-demo --query 'KeyMaterial' --output text > keypair.pem')
export KEYPAIR_NAME='aws-managed-docker-keypair'
export CLUSTER_SIZE=1
# don't make it too expensive, we're not rich. Or are we?
export EC2_INSTANCE_TYPE='t2.small'
# services to deploy, as defined in docker-compose, bash array
export SERVICES_TO_DEPLOY=( webserver )
### End configuration

export TASK_NAME=$CLUSTER_NAME-task
export CLUSTER_CONFIG_NAME=$CLUSTER_NAME-config
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export COMPOSE_PROJECT_NAME=$CLUSTER_NAME
export PROJECT_NAME=$CLUSTER_NAME