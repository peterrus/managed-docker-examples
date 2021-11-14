# Managed Docker Examples

This repository is mainly intended for my own reference but might be useful for others to build upon. All examples make use of (and provision) a container registry, so custom Docker images can be used.

Currently contains examples for the following providers:
- [AWS (ECS + EC2)](aws/) - Provisions an EC2 backed (3xt2.micro, configurable) ECS cluster and deploys Nginx containers with static HTML to it.
- [Azure (AppServices)](azure/) - Provisions two AppService instances (frontend and backend), deploys Nginx with static html and a Python+Flask backend to them.

Soon(tm):
- [GCP Serverless (Cloud Run)](#)
