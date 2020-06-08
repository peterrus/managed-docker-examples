#!/usr/bin/env bash

source ./configuration.sh

# delete deployed services (containers)
ecs-cli compose --file docker-compose.yml `# source the main docker-compose.yml` \
                --file docker-compose.aws.yml   `# and override it with some AWS specifics` \
                service rm \
                --cluster-config $CLUSTER_CONFIG_NAME \
                --cluster $CLUSTER_NAME \
                --ecs-profile $PROFILE_NAME

# destroy the cluster
ecs-cli down    --force \
                --cluster-config $CLUSTER_CONFIG_NAME \
                --ecs-profile $PROFILE_NAME

# delete cloudformation stack created by the ecs-cli
aws cloudformation delete-stack \
    --stack-name amazon-ecs-cli-setup-$CLUSTER_NAME

# delete log groups
aws logs delete-log-group \
    --log-group-name $TASK_NAME

# delete ECR repositories
for service in $SERVICES_TO_DEPLOY
do
    # delete all images first (mandatory)
    IMAGES_TO_DELETE=$( aws ecr list-images --repository-name ${PROJECT_NAME}_${service} --query 'imageIds[*]' --output json )
    aws ecr batch-delete-image --repository-name ${PROJECT_NAME}_${service} --image-ids "$IMAGES_TO_DELETE" || true
    # delete repository
    aws ecr delete-repository --repository-name ${PROJECT_NAME}_${service}
done