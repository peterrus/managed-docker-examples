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
    docker tag ${COMPOSE_PROJECT_NAME}_webserver:latest ${ECR_URL_PREFIX}_${service}:latest
    docker push ${ECR_URL_PREFIX}_${service}:latest
done

# # deploy containers to cluster
ecs-cli compose --file docker-compose.yml `# source the main docker-compose.yml` \
                --file docker-compose.aws.yml   `# and override it with some AWS specifics` \
                up -u \
                --cluster-config $CLUSTER_CONFIG_NAME \
                --ecs-profile $PROFILE_NAME \

# Print container status
ecs-cli ps --cluster-config $CLUSTER_CONFIG_NAME --ecs-profile $PROFILE_NAME

# Get the public address for the newly created instance(s) and print them
echo "Deployment done, instance(s) can be reached at: "
aws ecs list-container-instances \
    --cluster aws-managed-docker-example --query "containerInstanceArns[*]" | \
        jq -c '.[]' | \
            xargs -L 1 aws ecs describe-container-instances \
                --cluster $CLUSTER_NAME \
                --query "containerInstances[0].ec2InstanceId" --container-instances | \
                    xargs aws ec2 describe-instances \
                        --query "Reservations[*].Instances[*].PublicDnsName" \
                        --instance-ids

