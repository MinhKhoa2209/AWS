locals {
  name_prefix = "${var.project}-${var.environment}"
  project_path = replace(
    lower(local.name_prefix),
    "-",
    "/"
  )

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  public_subnet_cidrs      = slice(["10.60.0.0/24", "10.60.1.0/24"], 0, length(var.azs))
  firewall_subnet_cidrs    = var.enable_network_firewall ? slice(["10.60.10.0/24", "10.60.11.0/24"], 0, length(var.azs)) : []
  private_app_subnet_cidrs = slice(["10.60.100.0/24", "10.60.101.0/24"], 0, length(var.azs))
  private_data_subnet_cidrs = slice([
    "10.60.200.0/24",
    "10.60.201.0/24",
  ], 0, length(var.azs))
}
