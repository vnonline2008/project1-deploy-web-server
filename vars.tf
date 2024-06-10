variable "prefix" {
  description = "prefix is used for all resources"
  default     = "tungtt44-project1"
}

variable "location" {
  description = "location's project 1"
  default     = "East US"
}

variable "admin_username" {
  description = "Admin username for VM"
  default     = "tungtt44"
}

variable "admin_password" {
  description = "Admin password for VM"
  default     = "TungTT$4"
}

variable "image_id" {
  description = "Image Id"
  default     = "/subscriptions/2faa86ab-15bd-4228-95f1-4c17f8d9f8f5/resourceGroups/tungtt44-project1-packer/providers/Microsoft.Compute/images/tungtt44-packer-image"
}

variable "vm_count" {
  description = "Number of VM"
  default     = "2"
}

variable "vm_size" {
  description = "Size of VM"
  default     = "Standard_D2s_v3"
}

variable "storage_type" {
  description = "Storage type of disk"
  default     = "Standard_LRS"
}

variable "server" {
  default = ["vm1", "vm2"]
}
