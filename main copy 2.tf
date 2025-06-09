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
  count        = 1
  guest_name   = "webserver-${count.index + 1}"
  disk_store   = "DS01"
  ovf_source   = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
  memsize      = 2048
  numvcpus     = 1
  power        = "on"

  network_interfaces {
    virtual_network = "VM Network"
  }

  guestinfo = {
    "userdata"          = filebase64("cloud-config.yml")
    "userdata.encoding" = "base64"
  }
}

#DB server
resource "esxi_guest" "databaseserver" {
  guest_name   = "databaseserver"
  disk_store   = "DS01"
  ovf_source   = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.ova"
  memsize      = 2048
  numvcpus     = 1
  power        = "on"

  network_interfaces {
    virtual_network = "VM Network"
  }
    guestinfo = {
    "userdata"          = filebase64("cloud-config.yml")
    "userdata.encoding" = "base64"
  }
}


#Generate Ansible inventoryfile (IP, user & SSH key) voor webservers en databaseserver en voegt ips toe aan known_hosts voor SSH toegang.
resource "null_resource" "generate_inventory_and_known_hosts" {
  provisioner "local-exec" {
    command = <<EOT
echo "[webserver]" > inventory.ini
%{ for ip in esxi_guest.webserver[*].ip_address ~}
echo "${ip} ansible_user=student ansible_ssh_private_key_file=~/.ssh/iac" >> inventory.ini
ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
%{ endfor ~}

echo "" >> inventory.ini
echo "[databaseserver]" >> inventory.ini
echo "${esxi_guest.databaseserver.ip_address} ansible_user=student ansible_ssh_private_key_file=~/.ssh/iac" >> inventory.ini
ssh-keyscan -H ${esxi_guest.databaseserver.ip_address} >> ~/.ssh/known_hosts
EOT
  }

  depends_on = [
    esxi_guest.webserver,
    esxi_guest.databaseserver
  ]
}



