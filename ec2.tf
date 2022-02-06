resource "aws_eip" "this" {
  tags = merge({ Name = var.name }, var.tags)
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_s3_bucket_object" "this" {
  bucket  = var.ssh_key_bucket
  key     = "${var.name}.pem"
  content = tls_private_key.this.private_key_pem
}

resource "aws_key_pair" "this" {
  key_name   = var.name
  public_key = tls_private_key.this.public_key_openssh
}

resource "aws_launch_template" "instance" {
  name = var.name

  disable_api_termination = true
  instance_type           = var.instance_type
  vpc_security_group_ids  = [aws_security_group.wireguard.id]
  image_id                = data.aws_ami.amazon_linux_2.image_id
  key_name                = aws_key_pair.this.key_name

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
      iops                  = 3000
      throughput            = 125
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge({ Name = var.name }, var.tags)
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge({ Name = var.name }, var.tags)
  }

  user_data = base64encode(templatefile(
    "${path.module}/templates/user-data.sh.tpl",
    {
      aws_region                      = var.aws_region
      aws_account_id                  = data.aws_caller_identity.current.account_id
      eip_id                          = aws_eip.this.id
      is_ecr_docker_image             = var.is_ecr_docker_image
      wireguard_allowed_ips           = var.allowed_ips
      wireguard_subspace_docker_image = var.docker_image
      wireguard_ipv4_gateway          = var.ipv4_gateway
      wireguard_ipv6_gateway          = var.ipv6_gateway
      wireguard_disable_dns           = var.disable_wireguard_dns
      subspace_ipv4_nat_enabled       = var.enable_ipv4_nat
      subspace_ipv6_nat_enabled       = var.enable_ipv6_nat
      wireguard_subspace_http_host    = aws_route53_record.web.fqdn
      wireguard_endpoint_host         = aws_route53_record.endpoint.fqdn
      wireguard_backup_bucket_name    = aws_s3_bucket.backup.bucket
      enable-cloudwatch-metrics       = var.enable_cloudwatch_metrics
      subspace_config                 = local.subspace_config
    }
  ))
}

resource "aws_autoscaling_group" "this" {
  name = var.name
  # TODO: implement HA
  #  desired_capacity    = var.desired_instances
  #  max_size            = var.desired_instances + 1
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.instance.id
    version = "$Latest"
  }
}
