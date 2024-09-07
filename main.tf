resource "azurerm_resource_group" "rg" {

  name     = var.rg_name
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  
  name                = "kevinIAC.vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
  }
  
# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_names
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "kevinIAC-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

#create network security group for VM and allow RDP and HTTP traffic
resource "azurerm_network_security_group" "nsg" {
  name                = "kevinIAC.nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# NSG Rule to allow RDP (Remote Desktop Protocol)
resource "azurerm_network_security_rule" "nsg_rule_rdp" {
  name                        = "allow-rdp"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.nsg.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#create network interface
resource "azurerm_network_interface" "nic" {
  name                = "kevinIAC-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}


# Create Windows virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "kevinIAC.VM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Aspire2Aspire2"
  computer_name       = "KevinVM"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}


# Create DNS zone 
resource "azurerm_private_dns_zone" "mysql_dnslink" {
  name                = "kevinIAC.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnsdomain" {
  name                  = "kevinVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dnslink.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.rg.name
}

# Azure MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "kevin-mysqlfs-iac601"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  administrator_login = "mysqladmin"
  administrator_password = "Aspire2Aspire2"
  sku_name            = "GP_Standard_D2ds_v4"  # SKU (service level)
  version             = "8.0.21"               # MySQL Version
  backup_retention_days = 7                    # Backup Retention days
  zone                = "1"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.dnsdomain]

}