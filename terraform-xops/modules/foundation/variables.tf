variable "name_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "nat_gateway_count" {
  type = number
}

variable "backend_container_port" {
  type = number
}

variable "enable_network_firewall" {
  type = bool
}

variable "enable_interface_vpc_endpoints" {
  type = bool
}

variable "enable_vpc_flow_logs" {
  type = bool
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "firewall_subnet_cidrs" {
  type = list(string)
}

variable "private_app_subnet_cidrs" {
  type = list(string)
}

variable "private_data_subnet_cidrs" {
  type = list(string)
}
