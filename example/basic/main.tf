module "vpn" {
  source           = "github.com/waycarbon/terraform-aws-subspace"
  region           = "us-east-1"
  zone_id          = data.aws_route53_zone.test.id
  allowed_ips      = [data.aws_vpc.default.cidr_block]
  instance_type    = "t2.micro"
  subnet_ids       = [data.aws_subnet.default.id]
  ssh_key_bucket   = data.aws_s3_bucket.ssh.bucket
  vpn_endpoint_url = "endpoint.${data.aws_route53_zone.test.name}"
  web_url          = data.aws_route53_zone.test.name
}

