# Introduction 
Cada pasta dentro do projeto é referente a uma imagem que foi criada com o Packer.

A pasta .azdevops contém o continuos integration do Packer, nós usamos este arquivo para criar a pipeline no Azure Devops.

# Getting Started
1.	Software dependencies
* Dentro de cada pasta de imagens criadas precisa ter um arquivo *.pkr.hcl para que o Packer "leia" este arquivo e provisione com os scripts setados neste arquivo.
  * você pode usar um arquivo desse como base e editar para o seu uso.
* A pipeline pode ser criada com o arquivo "ci-packer" que está dentro da pasta .azdevops.
* O Agent Pool que irá executar precisa ter instalado:
  * Git
  * Packer
3.	Criação da Pipeline
* Selecione o arquivo da pasta .azdevops
* Coloque as seguintes variáveis na Pipeline:
    * WORK_PATH: Pasta que você criou no repositório
    * MANAGED_IMAGE_PREFIX: 
    * AZUREGALLERYNAME: "sharedgallery_microvix_production"
    * AZURE_GALLERY_MANAGEDIMAGE_PREFIX: 
    * AZURE_RESOURCE_GROUP_TEMPLATE: "mvxprd-templates"
    * CLIENT_ID:
    * CLIENT_SECRET:
    * SUBSCRIPTION_ID:
    * TENANT_ID:
# Build and Test
Para fazer o build da imagem você precisa rodar a pipeline.

# Contribute
1. Faça o clone do repositório.
2. Crie uma Branch.
3. Crie uma pasta do seu projeto.
4. Configure os arquivos necessários para criação da imagem.
5. Faça a pull request para a branch Main.