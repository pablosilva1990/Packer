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
  [bool] $UseCustomUsername = $false,
  [bool] $isDev = $false,
  [bool] $PurgeDefaults = $true,
  [bool] $setWebServerDefaults = $true 

)
import-module WebAdministration
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

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
}


$microvixSiteLists = @(
  [pscustomobject]@{Name = "crm-app" ; }
  [pscustomobject]@{Name = "crm-api" ; }
  [pscustomobject]@{Name = "vendafacil" ; }
  [pscustomobject]@{Name = "estoque" ; }
  [pscustomobject]@{Name = "wms" ; }
  [pscustomobject]@{Name = "hubvaletrocas" ; }
  [pscustomobject]@{Name = "agendaservicos-app" ; }
  [pscustomobject]@{Name = "implantar" ; }
  [pscustomobject]@{Name = "erp-app" ; }
  [pscustomobject]@{Name = "recuperadorcupomfiscal" ; }
  [pscustomobject]@{Name = "" ; }
  [pscustomobject]@{Name = "" ; }
  [pscustomobject]@{Name = "" ; }

) 


if ($isDev) {
  $siteList = @(
    [pscustomobject]@{Name = "${hostname}" ; Bindings = "${hostname}-.${Domain}" }
    [pscustomobject]@{Name = "vendafacil" ; Bindings = "{hostname}-vendafacil-${envName}.${Domain}" }
    [pscustomobject]@{Name = "estoque" ; Bindings = "${hostname}-estoque-${envName}.${Domain}" }
    [pscustomobject]@{Name = "wms" ; Bindings = "${hostname}-wms-${envName}.${Domain}" }
  ) 
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

# defining Default Values 
$sitePath = "${pathWebSite}\${envName}"
write-Output "site path: ${sitePath}"



Foreach ($item in $siteList) {
  [string] $projectName = ($item).Name
  [string] $path = "${SitePath}\$projectName\"
  [string] $appName = ($item).Bindings

  #Dynamic variables
  $Bindings = "http/:80:${appName}"

  if ((Test-Path "IIS:\AppPools\$appName") -eq $False) {
    # Application pool doesn't exist, create it...
    #New-Item -Path "IIS:\AppPools" -Name $appName -Type AppPool
    & $AppCmd add apppool /name:$appName
  }
 
  if ((Test-Path "IIS:\sites\$appName") -eq $False) {
    # Site doesn't exist, create it...
    & $AppCmd add site /name:$appName /physicalPath:$path /bindings:$Bindings
  }

  # Adiciona um caracter slash / no final do nome do Site  
  & $AppCmd set app ($appName + "/") /applicationPool:$appName
  




  ##################### END BASIC #################################




  break 


  # Não usar o código abaixo



  $webSite = "teste3"
  $appPool = "testeAppPool2"
  $dnsFqdn = "website.local.net"
  $pathWebSite = "c:\temp\"
  $pathLogs = "c:\site\logs"

  $identity = @{ identitytype = "SpecificUser"; username = "My Username"; password = "My Password" }
  $settings = @{ logFormat = "W3c"; enabled = $true; directory = $pathLogs; period = "Daily"; }

  if ((Test-Path "IIS:\AppPools\$appPool") -eq $False) {
    # Application pool does not exist, create it...
    New-Item -Path "IIS:\AppPools" -Name $appPool -Type AppPool
  }
  Set-ItemProperty -Path "IIS:\AppPools\$appPool" -name "processModel" -value $identity
  Set-ItemProperty -Path "IIS:\AppPools\My Pool" -name "enable32BitAppOnWin64" -value $true

  if ((Test-Path "IIS:\Sites\$webSite") -eq $False) {
    # Site does not exist, create it...
    New-WebSite -Name $webSite -Port 80 -HostHeader $dnsFqdn -PhysicalPath $pathWebSite
  }

  Set-ItemProperty "IIS:\Sites\$webSite" -name "logFile" -value $settings

  if ((Test-Path "IIS:\Sites\$webSite\MyApp") -eq $False) {
    # App/virtual directory does not exist, create it...
    # ...
  }
