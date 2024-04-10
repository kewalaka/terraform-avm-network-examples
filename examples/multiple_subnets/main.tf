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
    "subnet0" = {
      address_prefixes = ["192.168.140.0/24"]
    }
    "subnet1" = {
      address_prefixes = ["192.168.141.0/24"]
    }
    "subnet-${local.subnet_suffix}" = {
      address_prefixes = ["192.168.142.0/24"]
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
