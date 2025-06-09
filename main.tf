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

provider "azurerm" {
  features {}
  subscription_id = "7c2cf771-1067-4e56-9047-4a218905ddaf"
}

#Variables in variables.tf
provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}


#resource group als data importeren zodat deze wel gebruikt kan worden, maar niet beheerd wordt door Terraform
data "azurerm_resource_group" "rg" {
  name = "s1190828"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "2bvnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "2bsubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  count               = 1
  name                = "2b-publicip-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  count               = 1
  name                = "iac-nic-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                           = 1
  name                            = "iac-vm-${count.index}"
  resource_group_name             = data.azurerm_resource_group.rg.name
  location                        = data.azurerm_resource_group.rg.location
  size                            = "Standard_B2ats_v2"
  admin_username                  = "iac"
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  admin_ssh_key {
    username   = "iac"
    public_key = file("~/.ssh/iac.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("cloud-config.yml", {
  testuser_pubkey = file("~/.ssh/testuser.pub")
}))
}

output "azure_vm_ips" {
  value = [for ip in azurerm_public_ip.pip : ip.ip_address]
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

#Generate Ansible inventoryfile (IP, user & SSH key) voor webservers en voegt ips toe aan known_hosts voor SSH toegang.
resource "null_resource" "generate_inventory_and_known_hosts" {
  provisioner "local-exec" {
    command = <<EOT
echo "[webserver]" > inventory.ini
%{for ip in esxi_guest.webserver[*].ip_address~}
echo "${ip} ansible_user=student ansible_ssh_private_key_file=~/.ssh/iac" >> inventory.ini
ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
%{endfor~}

echo "[azure]" >> inventory.ini
echo "${azurerm_public_ip.pip[0].ip_address} ansible_user=student ansible_ssh_private_key_file=~/.ssh/iac" >> inventory.ini
ssh-keyscan -H ${azurerm_public_ip.pip[0].ip_address} >> ~/.ssh/known_hosts
EOT
  }

  depends_on = [
    esxi_guest.webserver,
    azurerm_linux_virtual_machine.vm,
    azurerm_public_ip.pip
  ]
}