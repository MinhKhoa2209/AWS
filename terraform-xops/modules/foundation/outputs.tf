output "kms_key_arn" {
  value = aws_kms_key.main.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "firewall_subnet_ids" {
  value = aws_subnet.firewall[*].id
}

output "private_app_subnet_ids" {
  value = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  value = aws_subnet.private_data[*].id
}

output "private_app_route_table_ids" {
  value = aws_route_table.private_app[*].id
}

output "private_data_route_table_ids" {
  value = aws_route_table.private_data[*].id
}

output "nat_eips_for_atlas_allowlist" {
  value = aws_eip.nat[*].public_ip
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "api_gateway_vpc_link_security_group_id" {
  value = aws_security_group.api_gateway_vpc_link.id
}

output "docdb_security_group_id" {
  value = aws_security_group.docdb.id
}

output "dms_security_group_id" {
  value = aws_security_group.dms.id
}

output "efs_security_group_id" {
  value = aws_security_group.efs.id
}

output "ops_runner_security_group_id" {
  value = aws_security_group.ops_runner.id
}

output "vpc_endpoints_security_group_id" {
  value = aws_security_group.vpc_endpoints.id
}
