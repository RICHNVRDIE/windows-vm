provider "azurerm" {
    features {}
}
resource "azurerm_resource_group" "rg2" {
  name     = "rg2"
  location = "West Europe"
}


resource "azurerm_public_ip" "myip2" {
  name                = "acceptanceTestPublicIp2"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  allocation_method   = "Dynamic"
}
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
}

resource "azurerm_subnet" "sub-net" {
  name                 = "sub-net"
  resource_group_name  = azurerm_resource_group.rg2.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "ex-nic" {
  name                = "ex-nic"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub-net.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.myip2.id
  }
}
resource "azurerm_network_interface_security_group_association" "nsg" {
  network_interface_id      = azurerm_network_interface.ex-nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name

  security_rule {
    name                       = "test123"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "8080"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_windows_virtual_machine" "win" {
  name                = "win"
  resource_group_name = azurerm_resource_group.rg2.name
  location            = azurerm_resource_group.rg2.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.ex-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "ex-windows" {
  name                 = "hostname"
  virtual_machine_id   = azurerm_windows_virtual_machine.win.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
 {
  "commandToExecute": "powershell Install-WindowsFeature -name Web-Server -IncludeManagementTools"
 }
SETTINGS

}




