# Auth VARS
variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}
variable "client_secret" {
  type    = string
  default = "${env("ARM_CLIENT_SECRET")}"
}
variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}
variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}

# Build Vars
variable "WorkingDirectory" {
  type    = string
  default = "${env("System_DefaultWorkingDirectory")}"
}
variable "build_resource_group_name" {
  type    = string
  default = "temp-packerBuild"
}
variable "managed_image_resource_group_name" {
  type    = string
}
variable "managed_image_prefix" {
  type    = string
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}

source "azure-arm" "build" {
  build_resource_group_name         = "${var.build_resource_group_name}"
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  subscription_id                   = "${var.subscription_id}"
  tenant_id                         = "${var.tenant_id}"
  vm_size                           = "${var.vm_size}"

  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "14.04.4-LTS"
  
  managed_image_name                 = "${var.managed_image_prefix}_${var.image_version}"
  managed_image_resource_group_name  = "${var.managed_image_resource_group_name}"
  managed_image_storage_account_type = "Premium_LRS"

  azure_tags = {
    environment 		  = "Packer"
    owner       		  = "Packer"
    Precisa_de_backup	= "Nao"
  }
}

# Builder: https://www.packer.io/docs/builders/azure/arm
build {
    sources = ["source.azure-arm.build"]

    provisioner "shell" {
        execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
        inline          = ["apt-get update", "apt-get upgrade -y", "apt-get -y install nginx", "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
        inline_shebang  = "/bin/sh -x"
    }

}
