provider "azurerm" {
	version = "=1.27.0"
	subscription_id = "fcef4a9e-c865-4994-bfd1-0ff20b6a7c89"
	tenant_id = "11dbbfe2-89b8-4549-be10-cec364e59551"
}

resource "azurerm_resource_group" "rg" {
	name = "MeuGrupodeRecursosTF"
	location = "${var.location}"
	tags = {
		environment = "TF sandbox"
	}
}

resource "azurerm_virtual_network" "vnet" {
	name = "MinhaVnetTF"
	address_space = ["10.0.0.0/16"]
	location = "${var.location}"
	resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
	name = "MinhaSubnetTF"
	resource_group_name = "${azurerm_resource_group.rg.name}"
	virtual_network_name = "${azurerm_virtual_network.vnet.name}"
	address_prefix = "10.0.1.0/24"
}

resource "azurerm_public_ip" "publicip" {
	name = "MeuIPPublicoTF"
	location = "${var.location}"
	resource_group_name = "${azurerm_resource_group.rg.name}"
	allocation_method = "Static"
}

resource "azurerm_network_security_group" "nsg" {
	name = "MeuSGTF"
	location = "${var.location}"
	resource_group_name = "${azurerm_resource_group.rg.name}"

	security_rule {
		name = "SSH"
		priority = 1001
		direction = "Inbound"
		access = "Allow"
		protocol = "Tcp"
		source_port_range = "*"
		destination_port_range = "22"
		source_address_prefix = "*"
		destination_address_prefix = "*"
	}
}

resource "azurerm_network_interface" "nic" {
	name = "MeuNIC"
	location = "${var.location}"
	resource_group_name = "${azurerm_resource_group.rg.name}"
	network_security_group_id = "${azurerm_network_security_group.nsg.id}"

	ip_configuration {
		name = "MeuNICConfg"
		subnet_id = "${azurerm_subnet.subnet.id}"
		private_ip_address_allocation = "dynamic"
		public_ip_address_id = "${azurerm_public_ip.publicip.id}"
	}
}

resource "azurerm_virtual_machine" "vm" {
	name = "MinhaVMTF"
	location = "${var.location}"
	resource_group_name = "${azurerm_resource_group.rg.name}"
	network_interface_ids = ["${azurerm_network_interface.nic.id}"]
	vm_size = "Standard_DS1_v2"

	storage_os_disk {
		name = "DiscoDeSO"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Premium_LRS"
	}
	
	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04.0-LTS"
		version = "latest"
	}
	
	os_profile {
		computer_name = "MinhaVMTF"
		admin_username = "${var.username}"
		admin_password = "${var.password}"
	}
	
	os_profile_linux_config {
		disable_password_authentication = false
	}
	tags = {
		environment = "teste"
	}
}
