# modules/networking/main.tf

# Create Resource Group for networking resources
resource "azurerm_resource_group" "network_rg" {
  name     = "${var.prefix}-${var.environment}-network-rg"
  location = var.location
  tags     = var.tags
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${var.environment}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  tags                = var.tags
}

# Create AKS Subnet
resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.prefix}-${var.environment}-aks-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
  
  # Enable service endpoints for Azure services
  service_endpoints = [
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Storage"
  ]
}

# Create Database Subnet
resource "azurerm_subnet" "db_subnet" {
  name                 = "${var.prefix}-${var.environment}-db-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.db_subnet_cidr]
  
  # Add service endpoints for secure database access
  service_endpoints = ["Microsoft.Sql"]
  
  # Delegate subnet to PostgreSQL Flexible Server (if using Azure DB for PostgreSQL)
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Create Redis Subnet
resource "azurerm_subnet" "redis_subnet" {
  name                 = "${var.prefix}-${var.environment}-redis-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.redis_subnet_cidr]
  
  # Add service endpoints for Azure Cache for Redis
  service_endpoints = ["Microsoft.Cache"]
}

# Create Network Security Group for AKS
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.prefix}-${var.environment}-aks-nsg"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  tags                = var.tags
}

# Create Network Security Group for Database
resource "azurerm_network_security_group" "db_nsg" {
  name                = "${var.prefix}-${var.environment}-db-nsg"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  tags                = var.tags
}

# Associate NSGs with subnets
resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "db_nsg_association" {
  subnet_id                 = azurerm_subnet.db_subnet.id
  network_security_group_id = azurerm_network_security_group.db_nsg.id
}

# Create NSG rules for AKS
resource "azurerm_network_security_rule" "aks_https_inbound" {
  name                        = "AllowHTTPSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
}

# Create NSG rules for Database (restrict access to AKS subnet only)
resource "azurerm_network_security_rule" "db_aks_inbound" {
  name                        = "AllowAKSInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432" # PostgreSQL port
  source_address_prefix       = var.aks_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}

# Deny all other inbound traffic to Database
resource "azurerm_network_security_rule" "db_deny_inbound" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network_rg.name
  network_security_group_name = azurerm_network_security_group.db_nsg.name
}