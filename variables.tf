variable "name" {
  default     = "vpn-wireguard-subspace"
  type        = string
  description = "Name used to tag and create resources"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet ids used to deploy subspace instances to"
}

variable "allowed_ips" {
  type = list(string)
  description = "List of IP CIDR Blocks used to create client wireguard AllowedIPs config"
}

variable "ssh_key_bucket" {
  type = string
  description = "Bucket to write SSH key to. The SSH key is used to connect to the wireguard instance via SSH"
}

variable "zone_id" {
  type = string
  description = "Zone ID to create the route53 records in. The records are used to create the wireguard endpoint and the internal alias for SSH"
}

variable "tags" {
  type    = map(string)
  default = {}
  description = "Extra tags used to tag resources with. Defaults to {}, in which case all resources are tagged with Name"
}

variable "instance_type" {
  type = string
  description = "Wireguard EC2 instance type. Controls CPU, Memory and Network resources"
}

variable "aws_region" {
  type = string
  description = "The AWS Region"
}

variable "volume_size" {
  type    = number
  default = 8
  description = "The EC2 Instance volume size"
}

variable "vpn_endpoint_url" {
  type = string
  description = "The endpoint url used to create the Wireguard config file"
}

variable "web_url" {
  type = string
  description = "The web application URL used to access the administration portal"
}

variable "internal_url" {
  type    = string
  default = null
  description = "The URL used to create an alias to the EC2 instance private IP"
}

# TODO: implement HA
variable "desired_instances" {
  default = 1
  type    = number
  description = "[WIP] used for high availability. Not implemented. This option has no effect"
}

variable "docker_image" {
  default = "subspacecommunity/subspace"
  type    = string
  description = "The docker image used to launch Subspace. Override this with another image repo (e.g. ECR) to control the version. Useful for not depending on dockerhub SLA and for custom patches"
}

variable "is_ecr_docker_image" {
  default = false
  type    = bool
  description = "Tells whether the docker_image comes from ECR. This will cause the EC2 instance to login to ECR using docker login before attempting to pull the image"
}

variable "ipv4_gateway" {
  default = "10.99.97.1"
  description = "The Wireguard VPN IPV4 gateway"
}

variable "ipv6_gateway" {
  default = "fd00::10:97:1"
  description = "The Wireguard VPN IPV6 gateway"
}

variable "disable_wireguard_dns" {
  default = false
  type    = bool
  description = "Disable tunnelling the DNS service over wireguard. Useful for supporting international clients (i.e. clients based on a region other than the EC2 region)."
}

variable "enable_ipv4_nat" {
  default = true
  type    = bool
  description = "Enables Wireguard IPv4 NAT"
}

variable "enable_ipv6_nat" {
  default = true
  type    = bool
  description = "Enables Wireguard IPv6 NAT"
}

variable "enable_cloudwatch_metrics" {
  default     = false
  type        = bool
  description = "Optional: enable swap, memory and disk metrics with cloudwatch agent"
}
