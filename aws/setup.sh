#!/usr/bin/env bash

set -e

source ./configuration.sh

# authenticate local docker daemon against ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# build all docker images locally
docker-compose build

export ECR_URL_PREFIX=$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${COMPOSE_PROJECT_NAME}

# tag and push them to ECR
for service in $SERVICES_TO_DEPLOY
do
    aws ecr create-repository \
        --repository-name ${PROJECT_NAME}_${service} \
        --image-scanning-configuration scanOnPush=true \
        --region $REGION

    docker tag ${COMPOSE_PROJECT_NAME}_webserver:latest ${ECR_URL_PREFIX}_${service}:latest
    docker push ${ECR_URL_PREFIX}_${service}:latest
done

# create cluster configuration
ecs-cli configure   --cluster $CLUSTER_NAME \
                    --default-launch-type EC2 \
                    --config-name $CLUSTER_CONFIG_NAME \
                    --region $REGION

# initialize cluster (creates EC2 instances)
ecs-cli up  --keypair $KEYPAIR_NAME \
            --capability-iam \
            --size $CLUSTER_SIZE \
            --instance-type $EC2_INSTANCE_TYPE \
            --cluster-config $CLUSTER_CONFIG_NAME \
            --ecs-profile $PROFILE_NAME

# wait until at least one instance is registered on the cluster
# https://github.com/aws/amazon-ecs-cli/issues/151
while [ "$(aws ecs describe-clusters --cluster=$CLUSTER_NAME | sed -n 's/^.*\"registeredContainerInstancesCount\"\: \(.*\),.*$/\1/p')" -lt 1 ]; do
    sleep 10
    echo "rechecking cluster status..."
done

# # deploy containers to cluster
ecs-cli compose --file docker-compose.yml `# source the main docker-compose.yml` \
                --file docker-compose.aws.yml   `# and override it with some AWS specifics` \
                up \
                --create-log-groups \
                --cluster-config $CLUSTER_CONFIG_NAME \
                --ecs-profile $PROFILE_NAME \