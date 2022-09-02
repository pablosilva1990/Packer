# create shared image gallery

$SHARED_G_Name = 'sharedgallery_microvix_production'
$RGName = 'mvxprd-templates'
$location = 'East US'
$tags = @{'Environment' = 'PROD'; 'Description' = 'Packer Image Builder' }
$imageDefName = "mvx_prod_erp"
$resourceGroup = New-AzResourceGroup -Name $RGname -Location $location -Tag $tags -Verbose

New-AzResourceGroup -Name temp-packerBuild -Location $location -Tag $tags -Verbose

$gallery = New-AzGallery `
    -GalleryName $SHARED_G_Name `
    -ResourceGroupName $RGName `
    -Location $location `
    -Description 'Shared Image Gallery for Packer build' `
    -Tag $tags `
    -Verbose

# Create the image definition
New-AzGalleryImageDefinition `
   -GalleryName $SHARED_G_Name `
   -ResourceGroupName $RGName `
   -Location $location `
   -Name $imageDefName `
   -HyperVGeneration v1 `
   -OsState generalized `
   -OsType Windows `
   -Publisher 'LinxMicrovix' `
   -Offer 'WindowsServer' `
   -Sku 'WinSrv2019'


# AZ CLI 
export GID=ENV-IMAGE
export SHARED_G_Name=sharedGallery-microvix-production
export RGName=mvxprd-images
export location=East US

# Base
az sig image-definition create --resource-group $RGName --gallery-name $SHARED_G_Name  --gallery-image-definition <my-ubuntu18> --publisher <company> --offer UbuntuServer --sku 18.04-LTS --os-type linux

# My exemple
az sig image-definition create --resource-group $RGName --gallery-name $SHARED_G_Name  --gallery-image-definition $GID --publisher Microsoft --offer WindowsServer --sku 2022-Datacenter --os-type Windows

# List Offers
az vm image list --offer MicrosoftWindowsServer --all