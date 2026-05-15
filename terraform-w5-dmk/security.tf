resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Private ALB security group for CloudFront VPC Origin"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "ECS task security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

resource "aws_security_group_rule" "alb_http_from_vpc_origin" {
  type              = "ingress"
  description       = "HTTP from CloudFront VPC Origin ENIs inside VPC"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
}

resource "aws_security_group_rule" "alb_http_from_cloudfront_prefix_list" {
  type              = "ingress"
  description       = "HTTP from CloudFront origin-facing managed prefix list"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  description              = "Forward HTTP to ECS tasks"
  security_group_id        = aws_security_group.alb.id
  from_port                = var.backend_container_port
  to_port                  = var.backend_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  description              = "Backend traffic from private ALB"
  security_group_id        = aws_security_group.ecs.id
  from_port                = var.backend_container_port
  to_port                  = var.backend_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "docdb" {
  name        = "${local.name_prefix}-docdb-sg"
  description = "DocumentDB access from ECS and DMS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MongoDB from ECS"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  ingress {
    description     = "MongoDB from DMS"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.dms.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-docdb-sg"
  }
}

resource "aws_security_group" "dms" {
  name        = "${local.name_prefix}-dms-sg"
  description = "DMS replication security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-dms-sg"
  }
}

resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-efs-sg"
  description = "EFS NFS access from ECS and ops-runner"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  ingress {
    description     = "NFS from ops-runner"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ops_runner.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${local.name_prefix}-efs-sg"
  }
}

resource "aws_security_group" "ops_runner" {
  name        = "${local.name_prefix}-ops-runner-sg"
  description = "Private ops-runner security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ops-runner-sg"
  }
}
