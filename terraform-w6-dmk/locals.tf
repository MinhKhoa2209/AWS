locals {
  name_prefix = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
  }

  public_subnet_cidrs      = ["10.60.0.0/24", "10.60.1.0/24"]
  firewall_subnet_cidrs    = ["10.60.10.0/24", "10.60.11.0/24"]
  private_app_subnet_cidrs = ["10.60.100.0/24", "10.60.101.0/24"]
  private_data_subnet_cidrs = [
    "10.60.200.0/24",
    "10.60.201.0/24"
  ]
}
