# Introduction 
Cada pasta dentro do projeto é referente a uma imagem que foi criada com o Packer.

A pasta .azdevops contém o continuos integration do Packer, nós usamos este arquivo para criar a pipeline no Azure Devops.

# Getting Started Packer Microvix

1. Criar a cópia do ci-template.yml
   a. No template você precisa alterar dois principais valores que são:

- WORK_PATH: Path relativo aos arquivos do Packer.
- ManagedImagePrefix: nome da imagem que será gerada pelo packer e utilizada na Azure Compute Gallery.

2. Configurar os arquivos dentro do WORK_PATH.

3. Criar a pipeline no Azure DevOps, organizando ela dentro do diretório "Packer"

4. Rodar a pipeline. 