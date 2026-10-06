resource "aws_ecr_repository" "service" {
  for_each = local.services

  name                 = "${local.name_prefix}-${each.key}-service"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name    = "${local.name_prefix}-${each.key}-service"
    Service = each.key
  }
}
