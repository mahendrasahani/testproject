

provider "azurerm" {
    subscription_id = "1bad0787-63c6-48e4-a4f0-64a3b2c3eed3"
    client_id       = "50b7c88f-5bb7-4d27-977e-b1ad91be06e3"
    client_secret   = "M0g8Q~Yg6DR1uT4Xvc5_Dqrdt0_pvMQEJh5ZXdcM"
    tenant_id       = "d6d3dc26-7929-45fa-a1fe-784587666cd7"
  features {}
}

resource "azurerm_resource_group" "test_rg" {
  name     = "terraform_resource"
  location = "South India"
}

variable "network_name" {
  type = string
  default = "test_network"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.network_name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test_rg.location
  resource_group_name = azurerm_resource_group.test_rg.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.test_rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.network_name}-nic"
  location            = azurerm_resource_group.test_rg.location
  resource_group_name = azurerm_resource_group.test_rg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "test-vm"
  location              = azurerm_resource_group.test_rg.location
  resource_group_name   = azurerm_resource_group.test_rg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "testserver"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}