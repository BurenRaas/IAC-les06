variable "esxi_hostname" {
  default = "192.168.20.14"
}

variable "esxi_hostport" {
  default = "22"
}

variable "esxi_hostssl" {
  default = "443"
}

variable "esxi_username" {
  default = "root"
}

variable "esxi_password" {
  default   = "s1190828!"
  sensitive = true
}


variable "vmIP" {
  default = "192.168.20.14/24"
}

variable "vmGateway" {
  default = "192.168.20.1"
}

