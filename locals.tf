locals {
  name_prefix = "${var.project_name}-${var.environment}"

  services = var.services
}
