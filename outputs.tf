output "ecr_repository_urls" {
  description = "ECR repository URLs for microservices"

  value = {
    for service, repository in aws_ecr_repository.service :
    service => repository.repository_url
  }
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"

  value = aws_iam_role.ecs_task_execution.arn
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log groups for microservices"

  value = {
    for service, log_group in aws_cloudwatch_log_group.service :
    service => log_group.name
  }
}
