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

variable "image_version" {
  type    = string
}

variable "vm_size" {
  type    = string
  default = "standard_F2s_v2"
}

variable "image_sku" {
  type    = string
  default = "20_04-lts-gen2"
}



source "azure-arm" "build" {
  build_resource_group_name         = "${var.build_resource_group_name}"
  os_type = "Linux"
  vm_size                           = "${var.vm_size}"

  # For Local use
  # use_azure_cli_auth = true
  
  # AUTH
  client_id                         = "${var.client_id}"
  client_secret                     = "${var.client_secret}"
  subscription_id                   = "${var.subscription_id}"
  tenant_id                         = "${var.tenant_id}"
  
  # Source Image
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "${var.image_sku}"

  # Destination Image  
  managed_image_name                 = "${var.managed_image_prefix}_${var.image_version}"
  managed_image_resource_group_name  = "${var.managed_image_resource_group_name}"
  managed_image_storage_account_type = "Premium_LRS"

  azure_tags = {
    environment = "Packer"
    owner = "Packer"
    Precisa_de_backup = "Nao"
  }
}

# Builder: https://www.packer.io/docs/builders/azure/arm
build {
    sources = ["source.azure-arm.build"]

    provisioner "file" {
      source = "./falcon-sensor.deb"
      destination = "/tmp/falcon-sensor.deb"
    }

    # Update and upgrade
    provisioner "shell" {
        execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
        inline          = [
          "cloud-init status --wait",
          "apt-get update",
          "apt-get upgrade -y"
        ]
        inline_shebang  = "/bin/sh -x"
    }

    provisioner "ansible" {
      ansible_env_vars = [ "ANSIBLE_HOST_KEY_CHECKING=False" ]

      ansible_ssh_extra_args = [                                                    
        "-oHostKeyAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"
      ]

      playbook_file = "./ansible/00-main.yaml"
    }
}