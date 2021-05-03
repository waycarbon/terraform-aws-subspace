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
      wireguard_allowed_ips           = var.allowed_ips
      wireguard_subspace_docker_image = var.docker_image
      is_ecr_docker_image             = var.is_ecr_docker_image
      wireguard_subspace_http_host    = aws_route53_record.web.fqdn
      wireguard_endpoint_host         = aws_route53_record.endpoint.fqdn
      wireguard_backup_bucket_name    = aws_s3_bucket.backup.bucket
      eip_id                          = aws_eip.this.id
    }
  ))
}

resource "aws_autoscaling_group" "this" {
  name = var.name

  desired_capacity    = var.desired_instances
  max_size            = var.desired_instances + 1
  min_size            = 0
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.instance.id
    version = "$Latest"
  }
}