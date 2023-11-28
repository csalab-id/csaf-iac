terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.37"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  # How to generate secret
  # $ az login
  # $ az ad sp create-for-rbac --name "SP-Terraform" --role contributor --scopes /subscriptions/000000xx-0000-0xx0-x000-0xx000xx0000 --sdk-auth
  # export ARM_SUBSCRIPTION_ID="yoursubscriptionid"
  # export ARM_TENANT_ID="yourtenantid"
  # export ARM_CLIENT_ID="yourclientid"
  # export ARM_CLIENT_SECRET="yourclientsecret"
  # subscription_id = "yoursubscriptionid"
  # tenant_id       = "yourtenantid"
  # client_id       = "yourclientid"
  # client_secret   = "yourclientsecret"
}

resource "azurerm_resource_group" "csaf" {
  name     = var.name
  location = var.location
}

resource "azurerm_virtual_machine" "csaf" {
  name                  = var.name
  resource_group_name   = azurerm_resource_group.csaf.name
  location              = azurerm_resource_group.csaf.location
  vm_size               = var.package
  network_interface_ids = [azurerm_network_interface.csaf.id]

  os_profile {
    computer_name  = var.name
    admin_username = "ubuntu"
    admin_password = "CSAF_Admin@"
    custom_data    = file("../startup.sh")
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = file("../csaf_rsa.pub")
    }
  }

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "22.04.202212140"
  }

  storage_os_disk {
    name                 = var.name
    caching              = "ReadWrite"
    disk_size_gb         = 100
    create_option        = "FromImage"
  }
}

resource "azurerm_network_interface" "csaf" {
  name                = var.name
  resource_group_name = azurerm_resource_group.csaf.name
  location            = azurerm_resource_group.csaf.location

  ip_configuration {
    name                          = var.name
    subnet_id                     = azurerm_subnet.csaf.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.csaf.id
  }
}

resource "azurerm_virtual_network" "csaf" {
  name                = var.name
  resource_group_name = azurerm_resource_group.csaf.name
  location            = azurerm_resource_group.csaf.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "csaf" {
  name                 = var.name
  resource_group_name  = azurerm_resource_group.csaf.name
  virtual_network_name = azurerm_virtual_network.csaf.name
  address_prefixes     = ["10.0.37.0/24"]
}

resource "azurerm_network_security_group" "csaf" {
  name                = var.name
  location            = azurerm_resource_group.csaf.location
  resource_group_name = azurerm_resource_group.csaf.name

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "csaf"
    description                = "Allow CSAF access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6080-8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "csaf" {
  network_interface_id      = azurerm_network_interface.csaf.id
  network_security_group_id = azurerm_network_security_group.csaf.id
}

resource "azurerm_public_ip" "csaf" {
  name                = var.name
  resource_group_name = azurerm_resource_group.csaf.name
  location            = azurerm_resource_group.csaf.location
  allocation_method   = "Dynamic"
}