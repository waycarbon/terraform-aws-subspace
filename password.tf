variable "admin_user_email" {
  type        = string
  default     = null
  description = "Creates pre-configured admin user with the provider email and a random password"
}

module "validate_email" {
  source  = "rhythmictech/errorcheck/terraform"
  version = "1.0.0"

  count = (
    var.admin_user_email != null
    ? 1
    : 0
  )
  assert        = length(regexall("(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+$)", var.admin_user_email)) > 0
  error_message = "The email provider for the admin account is invalid: ${var.admin_user_email} "
}

resource "random_password" "this" {
  count = (
    var.admin_user_email != null
    ? 1
    : 0
  )
  length      = 20
  special     = true
  min_lower   = 2
  min_numeric = 2
  min_special = 2
  min_upper   = 2
}

locals {
  hashed_password_base64 = (
    var.admin_user_email != null
    ? base64encode(bcrypt(random_password.this.result, 10))
    : null
  )
}
