resource "aws_cloudwatch_log_group" "network_firewall" {
  name              = "/aws/network-firewall/${local.name_prefix}"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_networkfirewall_rule_group" "egress_domain_deny" {
  capacity = 100
  name     = "${local.name_prefix}-egress-domain-deny"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<-RULES
        drop tls $HOME_NET any -> $EXTERNAL_NET any (tls.sni; content:"example-blocked.invalid"; startswith; nocase; endswith; msg:"Blocked W5 DMK demo domain"; sid:2000001; rev:1;)
        pass tls $HOME_NET any -> $EXTERNAL_NET any (sid:2000002; rev:1;)
      RULES
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${local.name_prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_default_actions = [
      "aws:drop_established",
      "aws:alert_established"
    ]

    stateful_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.egress_domain_deny.arn
    }
  }
}

resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.name_prefix}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.main.id

  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall

    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  tags = {
    Name = "${local.name_prefix}-network-firewall"
  }
}

locals {
  firewall_endpoint_ids_by_az = {
    for sync_state in aws_networkfirewall_firewall.main.firewall_status[0].sync_states :
    sync_state.availability_zone => sync_state.attachment[0].endpoint_id
  }
}

resource "aws_route" "private_app_to_firewall" {
  count                  = 2
  route_table_id         = aws_route_table.private_app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_ids_by_az[var.azs[count.index]]

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}
