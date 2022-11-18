<#
 .Synopsis

 .Description

 .Parameter pathWebSite
  Path Windows do site 

  .Parameter dnsHostFqdn
  Informe o DNS para configuracao so site

  .Parameter UseCustomUsername

  .PARAMETER envName 
  Esse parametro pode ser aceitacao, prod, rc, hom, etc 
  Pode usar para simbolizar um nome de portal também. Ex: 9090

 .Example
 .\script-iis.ps1 -slot 9040 -domain microvix.com.br -hostname expdevops

#>
param (
  [string] $pathWebSite = "c:\linx",
  [string] $HostName = "expdevops",
  [string] $envName = "aceitacao",
  [string] $Domain = "microvix.com.br",
  [string] $logsPath = "c:\site\logs",
  [bool] $UseCustomUsername = $false,
  [bool] $isDev = $false,
  [bool] $PurgeDefaults = $true,
  [bool] $setWebServerDefaults = $true

)
import-module WebAdministration
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

function start-WebEnvironmentBuilder {
  param (
    [string]$appName,
    [string]$path,

    [bool]$CustomIdentity = $false,
    [string]$CustomIdentityLogin,
    [string]$CustomIdentityPassowrd,

    [bool]$appPool32Bits = $false

  )


  #Dynamic variables
  $Bindings = "http/:80:${appName}"

  if ((Test-Path "IIS:\AppPools\$appName") -eq $False) {
    # Application pool doesn't exist, create it...
    # PowerShell: New-Item -Path "IIS:\AppPools" -Name $appName -Type AppPool
    & $AppCmd add apppool /name:$appName
  }
 
  if ((Test-Path "IIS:\sites\$appName") -eq $False) {
    # Site doesn't exist, create it...
    # PowerShell New-WebSite -Name $webSite -Port 80 -HostHeader $dnsFqdn -PhysicalPath $pathWebSite
    & $AppCmd add site /name:$appName /physicalPath:$path /bindings:$Bindings
  }

  # Adiciona um caracter slash / no final do nome do Site  
  & $AppCmd set app ($appName + "/") /applicationPool:$appName
  
  if ($Customidentity) {
    $identity = @{ identitytype = "SpecificUser"; username = "${CustomIdentityLogin}"; password = "${CustomIdentityPassowrd}" }
    Set-ItemProperty -Path "IIS:\AppPools\$appPool" -name "processModel" -value $identity
  }

  # Application Pool Config 
  if ($appPool32Bits) {
    Set-ItemProperty -Path "IIS:\AppPools\My Pool" -name "enable32BitAppOnWin64" -value $true
  }
  

  
}


# Remove Defaults
if ($PurgeDefaults) {
  
  if ((Test-Path "IIS:\sites\Default Web Site") -eq $true) {
    # Delete site "Default Web Site"
    & $AppCmd delete site "Default Web Site"
  }
  $AppPoolDft = @('Classic .NET AppPool', '.NET v2.0 Classic', '.NET v2.0', '.NET v4.5 Classic', '.NET v4.5', 'DefaultAppPool')
  foreach ($a in $AppPoolDft) {
    if ((Test-Path "IIS:\AppPools\$a") -eq $true) {
      # Application pool doesn't exist, create it...
      & $AppCmd  delete AppPool $a
    }
  }
}

if ($setWebServerDefaults) {
  # Server Config
  & $AppCmd unlock config /section:system.webServer/handlers
  & $AppCmd unlock config /section:system.webServer/modules
  & $AppCmd unlock config /section:system.webServer/asp

  if (test-path -path $logsPath = $false) {
    new-item -type Directory -path $logsPath
  }

  # SET LOGS CONFIG
  $settings = @{ logFormat = "W3c"; enabled = $true; directory = $logsPath; period = "Hourly"; }
  Set-ItemProperty "IIS:\Sites\$webSite" -name "logFile" -value $settings
}

$microvixSites = @(
  [pscustomobject]@{Name = "crm-app" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "crm-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "vendafacil" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "estoque" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "wms" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "hubvaletrocas" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "agendaservicos-app" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "implantar" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "erp-app" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "recuperadorcupomfiscal" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "nfe4-app" ; is32bits = "false" ; adminRights = "true" }

) 

$microvixAPIs = @(
  [pscustomobject]@{Name = "erpadmin" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "crm-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "otico-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "lgpdterceiros-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "agendaservicos-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "cobranca-linx-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "cobranca-extrator-catalogo-digital-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "fastpass-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "faturamentoservicosterceiros-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "imagensprodutos-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "relatorio-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "servicos-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "terceiros-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "giftcard-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "erpcore-api" ; is32bits = "false" ; adminRights = "false" }
  [pscustomobject]@{Name = "nfe-api" ; is32bits = "false" ; adminRights = "true" }

)
# merge lists
$allApps = & { 
  $microvixSites
  $microvixAPIs
}

Write-Output $allApps

if ($isDev) {
  # Create  site with main server name
  $BindingPrimary = "${hostname}.${Domain}"
  start-WebEnvironmentBuilder -projectName "${hostname}" -path "${path}"-bindings "${BindingPrimary}" -CustomIdentity $false 

  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    [string] $appName = ($item).Bindings
    [string] $path = "${SitePath}\${projectName}\"
    $siteBinding = "{hostname}-${projectName}-${envName}.${Domain}"

    start-WebEnvironmentBuilder -projectName "${projectName}" -path "${path}" -bindings "${siteBinding}" -CustomIdentity $false 
    

  }
} 
else {
  $siteList = @(
    [pscustomobject]@{Name = "crm" ; Bindings = "$($sitelist[0].name)-${envName}.${Domain}" }
    [pscustomobject]@{Name = "vendafacil" ; Bindings = "$($sitelist[1].name)-${envName}.${Domain}" }
    [pscustomobject]@{Name = "estoque" ; Bindings = "$($sitelist[2].name)-${envName}.${Domain}" }
    [pscustomobject]@{Name = "wms" ; Bindings = "$($sitelist[3].name)-${envName}.${Domain}" }
    [pscustomobject]@{Name = "hubvaletrocas" ; Bindings = "$($sitelist[4].name)-${envName}.${Domain}" }
    [pscustomobject]@{Name = "agendaservicos" ; Bindings = "$($sitelist[5].name)-${envName}.${Domain}" }
    [pscustomobject]@{Name = "implantar" ; Bindings = "$($sitelist[6].name)-${envName}.${Domain}" }
  ) 
}



