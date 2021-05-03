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
