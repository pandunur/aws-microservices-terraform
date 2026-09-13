variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-3"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "aws-ms"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "services" {
  description = "Microservices configuration"
  type = map(object({
    path         = string
    health_check = string
  }))
}
