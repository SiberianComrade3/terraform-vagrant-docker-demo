# Connection/Auth
variable "user_name" {
  description = "Used to initiate Provider OpenStack: 'user_name'"
}

variable "sel_account" {
  description = "Numeric ID as in my.selectel.ru"
}

variable "user_password" {
  description = "Used to initiate Provider OpenStack: 'password'"
}

variable "sel_token" {
  description = "Used to initiate Provider Selectel: 'token'"
}

variable "project_id" {
  description = "Used to initiate Provider OpenStack: 'tenant_id'"
}

variable "os_auth_url" {
  default     = "https://api.selvpc.ru/identity/v3"
  description = "Used to initiate Provider OpenStack: 'auth_url'"
}

variable "proctor_ip" {
  description = "External (public) IP address with mask /32 to verify the solution. Use 'curl ifconfig.ru' to find yours."
  type        = string
  default     = "127.0.0.2"
}


# openstack image list --public
variable "linux_image_name" {
  default = "Ubuntu 20.04 LTS 64-bit"
  type    = string
  validation {
    condition     = can(index(["Ubuntu 18.04 LTS 64-bit", "Ubuntu 20.04 LTS 64-bit", "Debian 9 (Stretch) 64-bit", "Debian 10 (Buster) 64-bit", "Debian 11 (Bullseye) 64-bit"], var.linux_image_name) >= 0)
    error_message = "Invalid image. Run 'openstack image list --public' to get list of available images."
  }
}

# Type of the network volume that the server is created from
# Verify: penstack volume type list
variable "volume_type" {
  default     = "basic.ru-3b"
  description = "Network volume type as in 'openstack volume type list'"
  type        = string
  validation {
    condition     = can(index(["fast.ru-3b", "fast.ru-3a", "universal.ru-3b", "universal.ru-3a", "basic.ru-3a", "basic.ru-3b"], var.volume_type) >= 0)
    error_message = "Invalid Network Volume type, consult 'openstack volume type list'."
  }
}

# Network
variable "subnet_cidr" {
  default = "10.209.035.0/24"
}

# https://kb.selectel.ru/docs/cloud/servers/about/locations/
variable "region" {
  default = "ru-3"
  type    = string
  validation {
    condition     = can(index(["ru-1", "ru-2", "ru-3"], var.region) >= 0)
    error_message = "Invalid Region, consult 'openstack region list'."
  }
}

# https://kb.selectel.ru/docs/cloud/servers/about/locations/
variable "server_zone" {
  default = "ru-3b"
  type    = string
  validation {
    condition     = can(index(["ru-1a", "ru-1b", "ru-1c", "ru-2a", "ru-2b", "ru-2c", "ru-3a", "ru-3b"], var.server_zone) >= 0)
    error_message = "Invalid Availability Zone."
  }
}

variable "router_name" {
  default = "tf_router_1"
}

# SSL/TLS
variable "tls_subject" {
  default = {
    common_name         = "host.astralinux.ru"
    organization        = "SX, Z-Level LLC"
    organizational_unit = "Terraform"
    country             = "RU"
    postal_code         = "127000"
  }
}

variable "ssh_private_key" {
  default = "id_rsa"
}

# Vagrant image
variable "vagrant_image_name" {
  default = "ubuntu2004"
}
variable "vagrant_image_version" {
  default = "3.6.12"
}
