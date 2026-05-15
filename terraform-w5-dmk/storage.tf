resource "aws_efs_file_system" "shared" {
  creation_token = "${local.name_prefix}-shared"
  encrypted      = true
  kms_key_id     = aws_kms_key.main.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.name_prefix}-shared-efs"
  }
}

resource "aws_efs_mount_target" "shared" {
  count           = 2
  file_system_id  = aws_efs_file_system.shared.id
  subnet_id       = aws_subnet.private_app[count.index].id
  security_groups = [aws_security_group.efs.id]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "ops_runner" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ops_runner_instance_type
  subnet_id                   = aws_subnet.private_app[0].id
  vpc_security_group_ids      = [aws_security_group.ops_runner.id]
  iam_instance_profile        = aws_iam_instance_profile.ops_runner.name
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
    kms_key_id  = aws_kms_key.main.arn
  }

  user_data = templatefile("${path.module}/templates/ops-runner-user-data.sh.tftpl", {
    efs_id     = aws_efs_file_system.shared.id
    aws_region = var.aws_region
  })

  tags = {
    Name = "${local.name_prefix}-ops-runner"
  }

  depends_on = [aws_efs_mount_target.shared]
}
