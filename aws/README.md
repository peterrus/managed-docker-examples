# AWS Managed Docker Example (ECS, EC2, ECR, Nginx)

This example uses a combination of Bash, AWS cli, ECS cli and docker-compose to orchestrate the following:

- An Elastic Container Registry (ECR) is created.
- A Nginx container is built, containing static HTML and pushed to ECR.
- An Elastic Container Service (ECS) cluster is created (Backed by 3 EC2 `t2.micro` instances, configurable).
- The Nginx container is deployed to the cluster and then scaled up evenly across the cluster.
- The addresses of the newly created endpoints are displayed so you can check out your new deployment.

## Files
- `docker-compose.yml` - Base docker-compose file which defines all services and their environment-independent properties.
- `docker-compose.override.yml` - Gets sounced by default when no explicit override is given. Used to easily run the stack locally by just using `docker-compose up`. No dependency to ECR.
- `docker-compose.aws.yml` - Contains overrides for the AWS environment (Logging configuration, exposed port, etc).
- `setup.sh` - Creates all resources on AWS.
- `teardown.sh` - Tries to destroy all resources on AWS. Use this to clean up after running this example.
- `update.sh` - Rebuilds all Docker images and pushed them to ECR, then triggers a redeploy. This script can be wired up in your CI/CD pipeline.

## Usage
- Run `docker-compose up` locally to make sure everything builds and runs correctly.(`http://localhost:8080` should be accessible).
- Make sure you have `aws`, `ecs-cli` and `jq` installed.
- Create a keypair (`aws ec2 create-key-pair --key-name aws-managed-docker-keypair --query 'KeyMaterial' --output text > aws-managed-docker-keypair.pem`)
- Review the configuration in `configuration.sh`
- Provision AWS using `setup.sh`
- Play around
- When you are done, deprovision (almost all) resources using `teardown.sh`
- You should not be charged for any services at this point (make sure to check though).


## Room for improvement (wip):

- Use proper IAM roles and permissions. I did write this with the assumption that you have authenticated AWS CLI and ECS CLI against AWS with a root account. You should **never** do this in production.
- Use something like Terraform or Cloudformation, because the CLI API might change and is not [declarative](https://www.upguard.com/articles/declarative-vs.-imperative-models-for-configuration-management).
- Put a load balancer in front of the EC2 instances so incoming traffic gets spread from a single ingress point.
- Use more aws-cli-native environment variables instead of making up my own.