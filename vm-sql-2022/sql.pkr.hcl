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
}
variable "managed_image_resource_group_name" {
  type    = string
}
variable "managed_image_prefix" {
  type    = string
}

variable "gallery_managed_image_prefix" {
  type = string
}

variable "gallery_name" {
  type    = string
  default = "SHAREDGALLERY-IMAGES"
}
variable "image_version" {
  type    = string
  default = "1.0.0"
}

variable "vm_offer" {
  type    = string
}

variable "vm_sku" {
  type    = string
}



source "azure-arm" "build" {

  build_resource_group_name         = "${var.build_resource_group_name}"
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  subscription_id                   = "${var.subscription_id}"
  tenant_id                         = "${var.tenant_id}"
  vm_size                           = "standard_F2s_v2"
  communicator                      = "winrm"
  image_publisher                   = "MicrosoftSQLServer"
  image_offer                       = "${var.vm_offer}"
  image_sku                         = "${var.vm_sku}"
  os_type                           = "Windows"
  winrm_insecure                    = true
  winrm_timeout                     = "5m"
  winrm_use_ssl                     = true
  winrm_username                    = "packer"

  shared_image_gallery_destination {
      subscription = "${var.subscription_id}"
      resource_group = "${var.managed_image_resource_group_name}"
      gallery_name = "${var.gallery_name}"
      image_name = "${var.managed_image_prefix}"
      image_version = "${var.image_version}"
      replication_regions = ["eastus"]
      #storage_account_type = "Standard_LRS"
  }

  managed_image_name                 = "${var.managed_image_prefix}"
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

  provisioner "powershell" {
    inline = [
      " # NOTE: the following *3* lines are only needed if the you have installed the Guest Agent.",
      "  while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "  while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }"
      ]
  }

  provisioner "powershell" {
    script = "sql-base.ps1"
  }

  provisioner "powershell" {
    script = "base-srv-mvx.ps1"
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'restarted.'}\""
  }

  provisioner "powershell" {
    script = "sysprep.ps1"
    max_retries = 2
  }

}
