terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

#Variables in variables.tf
provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

# Web server
resource "esxi_guest" "webserver" {
  count      = 1
  guest_name = "webserver-${count.index + 1}"
  disk_store = "DS01"
  ovf_source = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
  memsize    = 1024
  numvcpus   = 1
  power      = "on"

  network_interfaces {
    virtual_network = "VM Network"
  }

  guestinfo = {
    "userdata"          = filebase64("cloud-config.yml")
    "userdata.encoding" = "base64"
  }
}







