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
  [bool] $setWebServerDefaults = $true,
  [bool] $purgeSites = $false

)

function start-WebEnvironmentBuilder {
  param (
    # General Settings
    [string]$siteName,
    [string]$sitePath,

    # Site and Pool Login
    [bool]$CustomIdentity = $false,
    [string]$CustomIdentityLogin,
    [string]$CustomIdentityPassowrd,

    # App Pool
    [bool]$appPool32Bits = $false,
    [string]$dotnetCLR = "v4.0", # Possible Values: "v4.0", "v2.0" or "" (its like No Mamaged Code)
    [string]$ManagedPipelineMode = "Integrated", # Possible Values: "Integrated" or "Classic"

    # Config - Site
    [bool]$setWebServerDefaults = $true,
    [bool]$customTestLogPathEnabled = $false,
    [string]$logsPath,

    # Purge Parametsr
    [bool]$PurgeDefaults = $true,
    [bool]$PurgeSites = $false,
    [bool]$PurgeSiteFolder = $false
  )

  import-module WebAdministration
  $AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

  #Dynamic variables
  $Bindings = "http/:80:${siteName}"

  # Purge Site
  if ($purgeSites) {

    Write-Output "###################################################################"
    Write-Output "###########################  DELETE   #############################"
    Write-Output "###########################  ACTION   #############################"
    Write-Output "########################### TRIGGERED #############################"
    Write-Output "###################################################################"

    write-output "Purging site: ${siteName}" 

    if ((Test-Path "IIS:\sites\$siteName") -eq $true) {
      # Delete site "Default Web Site"
      write-output "Purging site ${siteName}" 
      & $AppCmd delete site "${siteName}" | Out-Null 
      if ($PurgeSiteFolder) {
        write-output "Deleting site path ${sitePath}"
        remove-item -Path $sitePath -Force -Confirm:$false -Recurse
      }
    }
   
    if ((Test-Path "IIS:\AppPools\$siteName") -eq $true) {
      # Delete site "Default Web Site"
      write-output "Purging AppPool ${siteName}"
      & $AppCmd  delete AppPool "${siteName}" | Out-Null
    }
    Write-Output "###################################################################"
    Write-Output "###########################   END     #############################"
    Write-Output "###################################################################"
  }

  # Remove Defaults
  if ($PurgeDefaults) {
  
    if ((Test-Path "IIS:\sites\Default Web Site") -eq $true) {
      # Delete site "Default Web Site"
      & $AppCmd delete site "Default Web Site" | Out-Null
    }
    $AppPoolDft = @('Classic .NET AppPool', '.NET v2.0 Classic', '.NET v2.0', '.NET v4.5 Classic', '.NET v4.5', 'DefaultAppPool')
    foreach ($a in $AppPoolDft) {
      if ((Test-Path "IIS:\AppPools\$a") -eq $true) {
        # Application pool doesn't exist, create it...
        & $AppCmd  delete AppPool $a | Out-Null
      }
    }
  }


  if ((Test-Path "IIS:\AppPools\$siteName") -eq $False) {
    ## Application pool doesn't exist, create it...
    # PowerShell: New-Item -Path "IIS:\AppPools" -Name $siteName -Type AppPool
    & $AppCmd add apppool /name:$siteName /managedRuntimeVersion:$dotnetCLR /managedPipelineMode:$ManagedPipelineMode | Out-Null

    # Recycling Defaults
    & $AppCmd set AppPool $siteName /-recycling.periodicRestart.time | Out-Null
    & $AppCmd set AppPool $siteName /recycling.periodicRestart.time:"00:00:00" /commit:apphost | Out-Null
  }
  
  if ((Test-Path "IIS:\sites\$siteName") -eq $False) {
    # Create Site Directory
    $testSitePath = test-path -path $sitePath
    If ($testSitePath -eq $false) {
      new-item -type Directory -path $sitePath | Out-Null
    }

    # Site doesn't exist, create it...
    # PowerShell New-WebSite -Name $siteName -Port 80 -HostHeader $dnsFqdn -PhysicalPath $sitePath
    & $AppCmd add site /name:$siteName /physicalPath:$sitePath /bindings:$Bindings | Out-Null
    
    ## Adiciona um caracter slash / no final do nome do Site 
    $appPoolCombine = "${siteName}/"
    & $AppCmd set app "${appPoolCombine}" /applicationPool:$siteName | Out-Null
  }


  
  if ($Customidentity) {
    $identity = @{ identitytype = "SpecificUser"; username = "${CustomIdentityLogin}"; password = "${CustomIdentityPassowrd}" }
    Set-ItemProperty -Path "IIS:\AppPools\$appPool" -name "processModel" -value $identity | Out-Null
  }

  ## Application Pool Config 
  if ($appPool32Bits) {
    Set-ItemProperty -Path "IIS:\AppPools\$siteName" -name "enable32BitAppOnWin64" -value $true | Out-Null
    # Recycling Defaults - x86 AppPool process
    & $AppCmd set AppPool $siteName /recycling.periodicRestart.memory:'3481600' | Out-Null
    & $AppCmd set AppPool $siteName /recycling.periodicRestart.privateMemory:'2867200' /commit:apphost | Out-Null
  }
  else {
    # Recycling Defaults - x64 AppPool process
    # Private (RAM): 10GiB RAM
    # VirtualMemory (Memory) 25 GiB RAM
    & $AppCmd set AppPool $siteName /recycling.periodicRestart.memory:'26214400'  | Out-Null
    & $AppCmd set AppPool $siteName /recycling.periodicRestart.privateMemory:'10485760' /commit:apphost | Out-Null
  }
  
  if ($setWebServerDefaults) {
    # Server Config
    & $AppCmd unlock config /section:system.webServer/handlers | Out-Null
    & $AppCmd unlock config /section:system.webServer/modules | Out-Null
    & $AppCmd unlock config /section:system.webServer/asp | Out-Null

    if ($customTestLogPathEnabled) {
      $testLogPath = test-path -path $logsPath
      If ($testLogPath -eq $false) {
        new-item -type Directory -path $logsPath | Out-Null
      }
      ## SET LOGS CONFIG
      $LogValues = "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus" 
      $settings = @{ logFormat = "W3c"; enabled = $true; directory = $logsPath; period = "Hourly" ; localTimeRollover = "True" ; logExtFileFlags = "${logValues}" }
      Set-ItemProperty "IIS:\Sites\$siteName" -name "logFile" -value $settings | Out-Null
  
      ## Custom Headers
      #$logValuesCustom = @{logFieldName = 'X-Forwarded-For'; sourceName = 'X-Forwarded-For'; sourceType = 'RequestHeader' }
      #Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name="${siteName}"]/logFile/customFields" -name "." -value $logValuesCustom

    }
    else {
      ## SET LOGS CONFIG
      $LogValues = "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus" 
      $settings = @{ logFormat = "W3c"; enabled = $true; period = "Hourly" ; localTimeRollover = "True" ; logExtFileFlags = "${logValues}" }
      Set-ItemProperty "IIS:\Sites\$siteName" -name "logFile" -value $settings | Out-Null
  
      ## Custom Headers
      #$logValuesCustom = @{logFieldName = 'X-Forwarded-For'; sourceName = 'X-Forwarded-For'; sourceType = 'RequestHeader' }
      #Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name="${siteName}"]/logFile/customFields" -name "." -value $logValuesCustom

    }

    # ASP Classic Section "long live the King"

    & $AppCmd set config -section:system.webServer/asp /scriptErrorSentToBrowser:'True' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /errorsToNTLog:'True' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /EnableParentPaths:'True' /commit:apphost | Out-Null

    # TrackingID MS 2208240040004733 - MTA must be disabled. 
    # Alterar isso potencializará problemas de performance em magnitudes inimaginaveis
    & $AppCmd  set config -section:system.webServer/asp /comPlus.executeInMta:'False' /commit:apphost | Out-Null

    & $AppCmd set config -section:system.webServer/asp /Session.timeOut:'00:20:00' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /Limits.bufferingLimit:'10094304' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /Limits.maxRequestEntityAllowed:'2147483647' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /Limits.processorThreadMax:'400' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /Limits.scriptTimeout:'00:10:00' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /cache.scriptFileCacheSize:'0' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /cache.maxDiskTemplateCacheFiles:'0' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /cache.scriptEngineCacheMax:'0' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /cache.enableTypelibCache:'True' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/asp /cache.diskTemplateCacheDirectory:'c:\inetpub\temp\ASP Compiled Templates' /commit:apphost | Out-Null

    & $AppCmd set config -section:system.webServer/urlCompression /doDynamicCompression:'false' /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/httpCompression /minFileSizeForComp:2700 /commit:apphost | Out-Null
    & $AppCmd set config -section:system.webServer/httpCompression /maxDiskSpaceUsage:16000 /commit:apphost | Out-Null
  }

}

# Predefined Values
$envName = "aceitacao"
$Domain = "microvix.com.br"
$isDev = $true
$envName = "gustavo"
$pathWebSite = "c:\linx"

$microvixSites = @(
  [pscustomobject]@{Name = "crm" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; }
  [pscustomobject]@{Name = "vendafacil" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "" ; }
  [pscustomobject]@{Name = "erp-mvx" ; is32bits = $true ; adminRights = $true ; ManagedPipeline = "Classic" ; CLR = "v4.0" ; }
  [pscustomobject]@{Name = "erp-login" ; is32bits = $true ; adminRights = $true ; ManagedPipeline = "Classic" ; CLR = "" ; }
  #[pscustomobject]@{Name = "estoque" ; is32bits = $false ; adminRights = $false ; CLR = "" ;  }
  #[pscustomobject]@{Name = "wms" ; is32bits = $false ; adminRights = $false ; CLR = "" ; }
  #[pscustomobject]@{Name = "hubvaletrocas" ; is32bits = $false ; adminRights = $false }
  #[pscustomobject]@{Name = "agendaservicos" ; is32bits = $false ; adminRights = $false }
  #[pscustomobject]@{Name = "implantar" ; is32bits = $false ; adminRights = $false }
  #[pscustomobject]@{Name = "erp-webapp" ; is32bits = $false ; adminRights = $false }
  #[pscustomobject]@{Name = "recuperadorcupomfiscal" ; is32bits = $false ; adminRights = $false }
  #[pscustomobject]@{Name = "nfe4" ; is32bits = $false ; adminRights = $true }
)

$microvixAPIs = @(
  [pscustomobject]@{Name = "erpadmin" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "crm-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "otico-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "lgpdterceiros-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "agendaservicos-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "cobranca-linx-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "cobranca-extrator-catalogo-digital-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "fastpass-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "faturamentoservicosterceiros-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "imagensprodutos-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "relatorio-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "servicos-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "terceiros-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "giftcard-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "erpcore-api" ; is32bits = $false ; adminRights = $false }
  [pscustomobject]@{Name = "nfe-api" ; is32bits = $false ; adminRights = $true }

)

#Write-Output $allApps

if ($isDev) {
  # merge lists - When is Dev. The script will create a base site and all the webapps
  $allApps = & { 
    $microvixSites
    #$microvixAPIs
  }
  [string] $projectName = "API"
  [string] $path = "${pathWebSite}\${projectName}"
  # Create  site with main server name
  $BindingPrimary = "${hostname}.${Domain}"
  Write-Output @("
  Dev Default Site 
      Site name: ${projectName}
      Site Path is: ${path} 
      Binding: ${BindingPrimary}
  ")
  start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${BindingPrimary}" 

  foreach ($item in $allApps) {

    [string] $projectName = ($item).Name
    [string] $path = "${pathWebSite}\${projectName}"
    
    # Dynamic Vars
    $siteBinding = "${hostname}-${projectName}-${envName}.${Domain}"

    Write-Output @("
    Microvix Web: ${projectName}
      Site Path is: ${path} 
      Binding: ${siteBinding}
      32bits: $($item.is32bits)
      .NET CLR: $($item.CLR)
      ManagedPipeline: $($item.ManagedPipeline)
    ")

    # $ConfigCustomIdentity = If ($condition) { "true" } Else { "false" }

    start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${siteBinding}" -appPool32Bits $item.is32bits -dotnetCLR $item.CLR -ManagedPipelineMode $item.ManagedPipeline -PurgeSites $true
    
  }
} 
else {
  # merge lists - When is not Dev. The script will create all sites needed
  $allApps = & { 
    $microvixSites
    $microvixAPIs
  }

  [string] $projectName = ($item).Name
  [string] $path = "${pathWebSite}\${projectName}"
  $siteBinding = "${projectName}-${envName}.${Domain}"
  
  start-WebEnvironmentBuilder -projectName "${projectName}" -sitePath "${path}" -bindings "${siteBinding}" -CustomIdentity $false 

}



