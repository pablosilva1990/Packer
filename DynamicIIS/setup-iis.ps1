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

# Predefined Values
$envName = "aceitacao"
$Domain = "microvix.com.br"
$isDev = $true
$envName = "gustavo"
$PurgeDefaults = $false

function start-WebEnvironmentBuilder {
  param (
    [string]$siteName,
    [string]$path,

    [bool]$CustomIdentity = $false,
    [string]$CustomIdentityLogin,
    [string]$CustomIdentityPassowrd,

    [bool]$appPool32Bits = $false

  )
  import-module WebAdministration
  write-output "entrou na function"
  #Dynamic variables
  $Bindings = "http/:80:${siteName}"


  if ((Test-Path "IIS:\AppPools\$siteName") -eq $False) {
    # Application pool doesn't exist, create it...
    # PowerShell: New-Item -Path "IIS:\AppPools" -Name $siteName -Type AppPool
    write-output "entrou na function 2"
    & $AppCmd add apppool /name:$siteName
  }
 
  if ((Test-Path "IIS:\sites\$siteName") -eq $False) {
    # Site doesn't exist, create it...
    # PowerShell New-WebSite -Name $siteName -Port 80 -HostHeader $dnsFqdn -PhysicalPath $path
    write-output "entrou na function 3"
    & $AppCmd add site /name:$siteName /physicalPath:$path /bindings:$Bindings
  }

  # Adiciona um caracter slash / no final do nome do Site 
  $appPoolCombine = "${siteName}/"
  & $AppCmd set app "${appPoolCombine}" /applicationPool:$siteName
  
  if ($Customidentity) {
    $identity = @{ identitytype = "SpecificUser"; username = "${CustomIdentityLogin}"; password = "${CustomIdentityPassowrd}" }
    Set-ItemProperty -Path "IIS:\AppPools\$appPool" -name "processModel" -value $identity
  }

  # Application Pool Config 
  if ($appPool32Bits) {
    Set-ItemProperty -Path "IIS:\AppPools\$siteName" -name "enable32BitAppOnWin64" -value $true
  }
  else {
    Set-ItemProperty -Path "IIS:\AppPools\$siteName" -name "enable32BitAppOnWin64" -value $false
  }
  
  ## SET LOGS CONFIG
  $LogValues = "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus" 
  $settings = @{ logFormat = "W3c"; enabled = $true; directory = $logsPath; period = "Hourly" ; localTimeRollover = "True" ; logExtFileFlags = "${logValues}" }
  Set-ItemProperty "IIS:\Sites\$siteName" -name "logFile" -value $settings

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

  $testLogPath = test-path -path $logsPath
  If ($testLogPath -eq $false) {
    new-item -type Directory -path $logsPath
  }

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

#Write-Output $allApps

if ($isDev) {
  # merge lists - When is Dev. The script will create a base site and all the webapps
  $allApps = & { 
    $microvixSites
    #$microvixAPIs
  }

  # Create  site with main server name
  $BindingPrimary = "${hostname}.${Domain}"
  start-WebEnvironmentBuilder -path "${path}" -siteName "${BindingPrimary}" 

  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    [string] $path = "${SitePath}\${projectName}\"
    $siteBinding = "${hostname}-${projectName}-${envName}.${Domain}"

    Write-Output $projectName
    Write-Output $path
    write-output $siteBinding

    start-WebEnvironmentBuilder -path "${path}" -siteName "${siteBinding}" 
    
  }
} 
else {

  # merge lists - When is not Dev. The script will create all sites needed
  $allApps = & { 
    $microvixSites
    $microvixAPIs
  }


  [string] $projectName = ($item).Name
  [string] $path = "${SitePath}\${projectName}\"
  $siteBinding = "${projectName}-${envName}.${Domain}"

  start-WebEnvironmentBuilder -projectName "${projectName}" -path "${path}" -bindings "${siteBinding}" -CustomIdentity $false 

}



