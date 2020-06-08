# Azure Managed Docker Example (AppService, Container Registry, Azure Database For MySQL)

This example uses a combination of Bash, AWS cli, ECS cli and docker-compose to orchestrate the following:

- A backend container image is built and tagged (Containing a simple Python backend, see `backend/app.py`)
- A frontend container image is built and tagged (Containing static html and some javascript to do a GET request to the backend, see `frontend/index.html`)
- A resource group is created, containing:
  - An Azure Container Registry with the above images
  - An Azure Database for MySQL server with a single database
  - An AppService plan containing two AppService instances (One per container):
    - One instance runs the frontend container
    - One instance runs the backend container, some environment variables are being set on this instance, this instance also runs a SSH daemon for debugging inside the container.
    - Both instances redeploy their containers as soon as an updated image is pushed to the container registry

- A Nginx container is built, containing static HTML and pushed to ECR.
- An Elastic Container Service (ECS) cluster is created (Backed by 3 EC2 `t2.micro` instances, configurable).
- The Nginx container is deployed to the cluster and then scaled up evenly across the cluster.
- The addresses of the newly created endpoints are displayed so you can check out your new deployment.

## Files
- `docker-compose.yml` - Base docker-compose file which defines all services and their properties. Is only used for local running and building. Azure has no stable support for docker-compose yet (But it is in preview at this time of writing).
- `setup.sh` - Creates all resources on Azure.
- `teardown.sh` - Destroys all resources on Azure by deleting the resource group.
- `update.sh` - Rebuilds all Docker images and pushes them to the container registry, thus triggering a redeploy. This script can be wired up in your CI/CD pipeline.
- `ssh.sh` - Connects to the SSH daemon running inside the backend container. Useful for debugging. (See the [Azure Docs](https://docs.microsoft.com/en-us/azure/app-service/containers/configure-custom-container#enable-ssh))

## Usage
- Run `docker-compose up` locally to make sure everything builds and runs correctly.(`http://localhost:8080` and `http://localhost:8081` should be accessible).
- Make sure you have `az` and `jq` installed.
- Run `az login` and find the `id` of the subscription you want to use, put that `id` in `configuration.sh`
- Review the configuration in `configuration.sh`
- Provision Azure using `setup.sh`
- Play around (the setup script will give you a frontend url you can visit and a backend url you can use in the frontend).
- When you are done, deprovision all resources using `teardown.sh`
- You should not be charged for any services at this point (make sure to check though).
