variable "rg_name" {
  description = "the name of resources group"
  default = "kevinIAC-rg"
}

variable "vnet" {
  description = "virtual network"
  default = "kevinIAC.vnet"
}

variable "location" {
  description = "location"
  default = "australiaeast"
}

variable "subnet_names" {
  description = "the first subnet of virtual network"
  default = "subnet-kevin"
}

variable "subnet_cidrs" {
  description = "the subnet address range"
  default = "10.10.1.0/24"
}

variable "vm_name" {
  description = "VM name"
  default = "kevinIAC.vm"
}


variable "nic" {
  description = "network interface card"
  default = "kevinIAC-nic"
}