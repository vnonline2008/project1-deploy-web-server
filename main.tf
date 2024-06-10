provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.prefix
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    customize-tag = "${var.prefix}-az-virtual-network"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${var.server[count.index]}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.prefix}-backend-config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    customize-tag = "${var.prefix}-az-network-interface"
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-network-sgn"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    customize-tag = "${var.prefix}-az-network-security-group"
  }
}

resource "azurerm_network_security_rule" "allow-inbound-internal" {
  name                        = "inbound-internal"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "10.0.0.0/16"
  network_security_group_name = azurerm_network_security_group.main.name
  resource_group_name         = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "allow-outbound-internal" {
  name                        = "outbound-internal"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "10.0.0.0/16"
  network_security_group_name = azurerm_network_security_group.main.name
  resource_group_name         = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "deny-inbound-external" {
  name                        = "deny-inbound-external"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.main.name
  resource_group_name         = azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  count                           = var.vm_count
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  source_image_id                 = var.image_id
  disable_password_authentication = false
  availability_set_id             = azurerm_availability_set.main.id
  network_interface_ids = [
    element(azurerm_network_interface.main.*.id, count.index)
  ]
  os_disk {
    storage_account_type = var.storage_type
    caching              = "ReadWrite"
  }
  tags = {
    customize-tag = "${var.prefix}-az-vm"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip-for-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
  tags = {
    customize-tag = "${var.prefix}-az-public-ip"
  }
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  frontend_ip_configuration {
    name                 = "${var.prefix}-frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.main.id
  }
  tags = {
    customize-tag = "${var.prefix}-az-lb"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  ip_configuration_name   = "${var.prefix}-backend-config"
  count                   = var.vm_count
  network_interface_id    = element(azurerm_network_interface.main.*.id, count.index)
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-aset"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags = {
    customize-tag = "${var.prefix}-az-aset"
  }
}
