# Project Context

## Project Overview
This is a DevOps demo project that demonstrates infrastructure as code using Terraform for AWS resources.
I'm a devops/cloud engineer that had a very long break from work and I'm trying to refresh my memory and infrastructure as code skills by creating a personal demo project on AWS using terraform.
This project is for my personal use but it should immitate prodaction level ready architecture but without any redundent hyper scaling features, to save personal costs.

## Project Structure
- `terraform/modules/` - Reusable Terraform modules
  - `loadbalancer/` - AWS Application Load Balancer module
- `terraform/envs/` - Environment-specific configurations
  - `prod/` - Production environment
    - `albs/` - Load balancer configuration for production

## Terraform Architecture
- **Modules**: Self-contained, reusable infrastructure components with all necessary variables
- **Environments**: Environment-specific implementations that call modules with minimal, essential variables only
- **Design Principles**:
  - Keep configurations thin and minimal
  - Only include essential variables at the environment level
  - Modules should be flexible and accept all possible configuration options
  - Environment implementations should pass only what's necessary

## Current State
The project currently includes:
- A load balancer module that supports VPC configuration, target groups, listeners, and attachments
- A production environment setup ready to deploy a basic ALB without specific attachments

## Project Goals
I need to have a complete AWS Infrastructure as code solution for hosting a highly available application on EKS with multiple nodes, different services, monitoring, etc.
I need this project to be built step by step in purpose of learning, but at the end this project should be fine tunned and presentable on a tech interview.
