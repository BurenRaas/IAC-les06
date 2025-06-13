terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

#Web server op esx
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

output "webserver_ips" {
  value = [for vm in esxi_guest.webserver : vm.ip_address]
}


#Generate Ansible inventoryfile (IP, user & SSH key) voor webservers en voegt ips toe aan known_hosts voor SSH toegang.
resource "null_resource" "generate_inventory_and_known_hosts" {
  provisioner "local-exec" {
    command = <<EOT
echo "[webserver]" > inventory.ini
%{for ip in esxi_guest.webserver[*].ip_address~}
echo "${ip} ansible_user=student ansible_ssh_private_key_file=~/.ssh/iac" >> inventory.ini
ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
%{endfor~}

EOT
  }


}