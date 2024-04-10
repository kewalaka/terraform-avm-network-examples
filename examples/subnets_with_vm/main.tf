terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.94"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }

  }
}
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

#Importing the Azure naming module to ensure resources have unique CAF compliant names.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.1"
}

#Generating a random ID to be used for creating unique resource names.
resource "random_id" "rg_name" {
  byte_length = 8
}

#Creating a resource group with a unique name in the specified location.
resource "azurerm_resource_group" "example" {
  location = "AustraliaEast"
  name     = module.naming.resource_group.name_unique
}

locals {
  subnets = {
    # "snet-firewall-wan-${local.subnet_suffix}" = {
    #   address_prefixes = ["10.60.16.0/27"]
    # }
    "subnet1" = {
      address_prefixes = ["192.168.141.0/24"]
    }
    "subnet-${local.subnet_suffix}" = {
      address_prefixes = ["192.168.142.0/24"]
    }
    "subnet-another" = {
      address_prefixes = ["192.168.143.0/24"]
    }
  }
  vnet_name      = "vnet-${local.default_suffix}"
  default_suffix = "${var.appname}-${var.env_code}-${var.short_location_code}"
  subnet_suffix  = replace(local.vnet_name, "vnet-", "")
}
#Defining the first virtual network (vnet-1) with its subnets and settings.
module "vnet_1" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.1.4"
  resource_group_name = azurerm_resource_group.example.name

  subnets = local.subnets

  virtual_network_address_space = ["192.168.128.0/20"]
  location                      = azurerm_resource_group.example.location
  name                          = "accttest-vnet-peer"
  enable_telemetry              = false
}

resource "random_password" "random" {
  length = 16
}

module "testvm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.9.0"

  admin_username                     = "azureuser"
  admin_password                     = random_password.random.result
  disable_password_authentication    = false
  enable_telemetry                   = false
  encryption_at_host_enabled         = false
  generate_admin_password_or_ssh_key = false
  name                               = module.naming.virtual_machine.name_unique
  resource_group_name                = azurerm_resource_group.example.name
  virtualmachine_os_type             = "Linux"
  virtualmachine_sku_size            = "Standard_DS1_v2"
  zone                               = null

  network_interfaces = {
    network_interface_1 = {
      name = module.naming.network_interface.name_unique
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = module.vnet_1.subnets["subnet-${local.subnet_suffix}"].id
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

}
