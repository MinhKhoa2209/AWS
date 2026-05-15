resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.azs[count.index]
  cidr_block              = local.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_subnet" "firewall" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = local.firewall_subnet_cidrs[count.index]

  tags = {
    Name = "${local.name_prefix}-firewall-${count.index + 1}"
    Tier = "firewall"
  }
}

resource "aws_subnet" "private_app" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = local.private_app_subnet_cidrs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-app-${count.index + 1}"
    Tier = "private-app"
  }
}

resource "aws_subnet" "private_data" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  availability_zone = var.azs[count.index]
  cidr_block        = local.private_data_subnet_cidrs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-data-${count.index + 1}"
    Tier = "private-data"
  }
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.name_prefix}-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-rtb-public"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "firewall" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${local.name_prefix}-rtb-firewall-${count.index + 1}"
  }
}

resource "aws_route_table_association" "firewall" {
  count          = 2
  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

resource "aws_route_table" "private_app" {
  count  = 2
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rtb-private-app-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

resource "aws_route_table" "private_data" {
  count  = 2
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rtb-private-data-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private_data" {
  count          = 2
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data[count.index].id
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/aws/vpc/${local.name_prefix}/flow-logs"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_iam_role" "flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs.arn}:*"
    }]
  })
}

resource "aws_flow_log" "vpc" {
  iam_role_arn             = aws_iam_role.flow_logs.arn
  log_destination          = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.main.id
  max_aggregation_interval = 60

  tags = {
    Name = "${local.name_prefix}-vpc-flow-logs"
  }
}
