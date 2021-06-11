variable "name" {
  default = "vpn-wireguard-subspace"
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_ips" {
  type = list(string)
}

variable "ssh_key_bucket" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "instance_type" {
  type = string
}

variable "region" {
  type = string
}

variable "volume_size" {
  type    = number
  default = 8
}

variable "vpn_endpoint_url" {
  type = string
}

variable "web_url" {
  type = string
}

variable "internal_url" {
  type    = string
  default = null
}

variable "desired_instances" {
  default = 1
  type    = number
}

variable "docker_image" {
  default = "subspacecommunity/subspace"
  type    = string
}

variable "is_ecr_docker_image" {
  default = false
  type    = bool
}

variable "ipv4_gateway" {
  default = "10.99.97.1"
}

variable "ipv6_gateway" {
  default = "fd00::10:97:1"
}

variable "disable_wireguard_dns" {
  default = false
  type    = bool
}

variable "enable_cloudwatch_metrics" {
  default = false
  type    = bool
  description = "Optional: enable swap, memory and disk metrics with cloudwatch agent"
}
