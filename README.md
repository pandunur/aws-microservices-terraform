# AWS Microservices Infrastructure with Terraform

Infrastructure as Code (IaC) project for deploying a containerized microservices architecture on AWS using Terraform.

This repository manages the AWS infrastructure and ECS runtime configuration for a microservices application consisting of three services: `user-service`, `payment-service`, and `notification-service`.

The application source code is maintained separately in the [AWS Microservices Application repository](https://github.com/pandunur/aws-microservices-devops).

---

## Architecture

The infrastructure is designed around a public Application Load Balancer and private ECS Fargate tasks.

```text
                         Internet
                            |
                            v
                    +---------------+
                    |      ALB      |
                    |     :80       |
                    +-------+-------+
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
             /         /payments*    /notifications*
             |              |              |
             v              v              v
        +---------+    +---------+    +--------------+
        |  User   |    | Payment |    | Notification |
        |   TG    |    |   TG    |    |      TG     |
        +----+----+    +----+----+    +------+-------+
             |              |                 |
             +--------------+-----------------+
                            |
                            v
                 +----------------------+
                 |    ECS Fargate       |
                 |    Private Subnets  |
                 +----------------------+
                    |        |        |
                    v        v        v
                 User     Payment   Notification
                 Task      Task       Task
```

### Network Architecture

```text
VPC: 10.0.0.0/16

├── Public Subnet 1
│   └── ALB / NAT Gateway
│
├── Public Subnet 2
│   └── ALB
│
├── Private Subnet 1
│   └── ECS Fargate Tasks
│
└── Private Subnet 2
    └── ECS Fargate Tasks
```

The ECS tasks do not receive public IP addresses. Application traffic enters through the ALB, while private subnet resources use the NAT Gateway for outbound internet connectivity when required.

---

## Services Used

### AWS

* Amazon VPC
* Public and Private Subnets
* Internet Gateway
* NAT Gateway
* Application Load Balancer (ALB)
* Target Groups
* Amazon ECS
* AWS Fargate
* Amazon ECR
* AWS IAM
* Amazon CloudWatch Logs
* Security Groups

### Tools

* Terraform
* Docker
* AWS CLI
* Git / GitHub

---

## Microservices

The application contains three services:

| Service      | ALB Path          | Container Port | Health Check |
| ------------ | ----------------- | -------------: | ------------ |
| User         | `/`               |           8080 | `/health`    |
| Payment      | `/payments*`      |           8080 | `/health`    |
| Notification | `/notifications*` |           8080 | `/health`    |

All services run as ECS Fargate tasks in private subnets.

---

## Repository Structure

```text
aws-microservices-terraform/
│
├── README.md
├── .gitignore
├── terraform.tfvars.example
│
├── provider.tf
├── variables.tf
├── locals.tf
│
├── vpc.tf
├── security-groups.tf
├── ecr.tf
├── iam.tf
├── cloudwatch.tf
├── alb.tf
├── ecs.tf
│
└── outputs.tf
```

### Terraform Files

| File                       | Purpose                                         |
| -------------------------- | ----------------------------------------------- |
| `provider.tf`              | Terraform and AWS provider configuration        |
| `variables.tf`             | Input variable definitions                      |
| `locals.tf`                | Shared local values                             |
| `terraform.tfvars.example` | Example project configuration                   |
| `vpc.tf`                   | VPC, subnets, route tables, IGW and NAT Gateway |
| `security-groups.tf`       | ALB and ECS security groups                     |
| `ecr.tf`                   | ECR repositories for microservices              |
| `iam.tf`                   | ECS task execution IAM role                     |
| `cloudwatch.tf`            | CloudWatch log groups                           |
| `alb.tf`                   | ALB, target groups, listener and routing rules  |
| `ecs.tf`                   | ECS cluster, task definitions and ECS services  |
| `outputs.tf`               | Useful Terraform outputs                        |

---

## Infrastructure Design

### 1. VPC

The project uses a custom VPC:

```text
10.0.0.0/16
```

The VPC is divided into public and private subnets across two Availability Zones.

```text
Public:
10.0.1.0/24
10.0.2.0/24

Private:
10.0.3.0/24
10.0.4.0/24
```

### 2. Internet Access

Public subnets use an Internet Gateway for internet connectivity.

Private subnets use a NAT Gateway for outbound internet access.

```text
Private Subnet
      |
      v
Private Route Table
      |
      v
NAT Gateway
      |
      v
Internet Gateway
      |
      v
Internet
```

Only one NAT Gateway is used for this development project to keep the architecture simpler.

---

## Security

The security model follows a basic layered architecture.

### ALB Security Group

Allows:

```text
Internet → ALB :80
```

### ECS Security Group

Allows:

```text
ALB Security Group → ECS :8080
```

The ECS security group does not expose port `8080` directly to the internet.

Therefore:

```text
Internet
   |
   v
ALB :80
   |
   v
ECS :8080
```

rather than:

```text
Internet
   |
   X
ECS :8080
```

---

## Amazon ECR

Terraform creates one ECR repository for each microservice:

```text
aws-ms-dev-user-service
aws-ms-dev-payment-service
aws-ms-dev-notification-service
```

Image scanning on push is enabled.

The ECS task definitions reference the ECR repositories using the `latest` image tag:

```text
<ECR repository URL>:latest
```

Docker images are built and pushed separately from the Terraform infrastructure workflow.

---

## ECS Fargate

The project uses:

* ECS Cluster
* Fargate launch type
* `awsvpc` network mode
* Private subnets
* No public IP addresses
* One desired task per service
* Container port `8080`

Each service has its own:

* Task Definition
* ECS Service
* Target Group
* CloudWatch Log Group

---

## Application Load Balancer

The ALB listens on port `80` and uses path-based routing.

```text
/                  → user-service
/payments*         → payment-service
/notifications*    → notification-service
```

Each target group performs an HTTP health check against:

```text
/health
```

A healthy ECS task must return HTTP `200`.

---

## CloudWatch Logging

Each ECS service has its own CloudWatch log group.

```text
/ecs/aws-ms-dev/user
/ecs/aws-ms-dev/payment
/ecs/aws-ms-dev/notification
```

Log retention is configured for development use.

---

## IAM

ECS uses an **ECS Task Execution Role**.

The role allows ECS/Fargate to perform tasks such as:

* Pull container images from Amazon ECR
* Send container logs to CloudWatch Logs

The application does not currently require a separate ECS Task Role because the services do not need to access AWS APIs directly.

---

## Prerequisites

Before deploying this infrastructure, install and configure:

* Terraform >= 1.6
* AWS CLI
* Docker
* Git

Configure AWS CLI with credentials that have sufficient permissions to create the required resources.

Verify the AWS CLI configuration:

```bash
aws sts get-caller-identity
```

---

## Configuration

Create your local Terraform variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Review the configuration:

```bash
nano terraform.tfvars
```

The `terraform.tfvars` file is intentionally excluded from Git because local Terraform variable files may contain environment-specific configuration.

---

## Deploy Infrastructure

Initialize Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Review the execution plan:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

Confirm with:

```text
yes
```

---

## Build and Push Docker Images

After the ECR repositories have been created, build the application images and push them to ECR.

The application repository is maintained separately:

**Application Repository:**
https://github.com/pandunur/aws-microservices-devops

Example ECR workflow:

```bash
aws ecr get-login-password --region ap-southeast-3 | \
docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.ap-southeast-3.amazonaws.com
```

Then build, tag and push each service image.

Example:

```bash
docker build -t user-service ./user-service
```

```bash
docker tag user-service:latest \
<AWS_ACCOUNT_ID>.dkr.ecr.ap-southeast-3.amazonaws.com/aws-ms-dev-user-service:latest
```

```bash
docker push \
<AWS_ACCOUNT_ID>.dkr.ecr.ap-southeast-3.amazonaws.com/aws-ms-dev-user-service:latest
```

Repeat for `payment-service` and `notification-service`.

---

## Verification

Check ECS services:

```bash
aws ecs describe-services \
  --cluster aws-ms-dev-cluster \
  --services \
    aws-ms-dev-user-service \
    aws-ms-dev-payment-service \
    aws-ms-dev-notification-service \
  --region ap-southeast-3
```

The expected state is:

```text
desired = 1
running = 1
pending = 0
```

Check ALB target health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN> \
  --region ap-southeast-3
```

Expected:

```text
healthy
```

The application can then be accessed through the ALB DNS name.

---

## Terraform Outputs

Useful infrastructure information can be retrieved with:

```bash
terraform output
```

For example:

```bash
terraform output ecr_repository_urls
```

```bash
terraform output alb_dns_name
```

---

## Cleanup

Because this project is intended for hands-on learning, the infrastructure can be removed when it is no longer needed.

Run:

```bash
terraform destroy
```

Review the resources Terraform plans to remove and confirm:

```text
yes
```

This helps avoid unnecessary AWS charges from resources such as NAT Gateway and Application Load Balancer.

---

## What I Learned

This project provided hands-on practice with:

* Infrastructure as Code using Terraform
* AWS VPC networking
* Public vs private subnet architecture
* Route tables and NAT Gateway
* Security Group design
* Docker containerization
* Amazon ECR
* Amazon ECS and Fargate
* Application Load Balancer
* Path-based routing
* Target group health checks
* IAM roles
* CloudWatch container logging
* Terraform resource dependencies
* Troubleshooting AWS networking and container deployments

---

## Project Status

**Completed**

The infrastructure has been deployed and verified with:

* 3 microservices
* ECS Fargate
* Private subnets
* Application Load Balancer
* Path-based routing
* ECR
* CloudWatch Logs
* IAM
* Terraform-managed infrastructure

---

## Related Repository

### Application

Containerized microservices application:

https://github.com/pandunur/aws-microservices-devops

### Infrastructure

This repository:

https://github.com/pandunur/aws-microservices-terraform

---

## Author

**Pandu Nur**

Currently focused on building practical experience with AWS, Terraform, Docker, Linux, Git, CI/CD, and cloud-native infrastructure.
