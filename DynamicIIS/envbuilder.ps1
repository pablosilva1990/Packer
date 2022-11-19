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

 .Example Microvix DEV
 $SecurePassword = ConvertTo-SecureString "Pa$$w0rdMicrovixSitesIIS" -AsPlainText -Force
 .\envbuilder.ps1 -envName 9040 -domain microvix.com.br -hostname expclientes -pathWebSite "c:\linx" -webLogin "linxsaas\svc.vmdev" -webPassword $SecurePassword -isDev $true
 
 .Example Microvix Web Server 
 .\envbuilder.ps1 -envName aceitacao -domain microvix.com.br -hostname expclientes -pathWebSite "c:\linx" -webLogin "linxsaas\svc.vmaceitacao" -webPassword $SecurePassword
#>
param (
  [string] $pathWebSite = "c:\linx",
  [string] $HostName ,
  [string] $envName ,
  [string] $Domain ,
  [string] $logsPath = "c:\site\logs",
  [bool] $UseCustomUsername = $false,
  [bool] $isDev = $false,
  [bool] $PurgeDefaults = $true,
  [bool] $setWebServerDefaults = $true,
  [bool] $purgeSites = $false,
  [string]$WebLogin,
  [securestring]$WebPassword

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
    [string]$startup = "OnDemand",

    # Config - Site
    [bool]$setWebServerDefaults = $true,
    [bool]$customTestLogPathEnabled = $false,
    [string]$logsPath,
    [bool]$ASPClassicConfig = $true,

    #Security
    [bool]$configRequestFiltering = $false,

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

    write-output "Purging site: ${siteName}" 

    if ((Test-Path "IIS:\sites\$siteName") -eq $true) {
      # Delete site "Default Web Site"
      write-output "Purging site ${siteName}" 
      & $AppCmd delete site "${siteName}" | Out-Null 
      if ($PurgeSiteFolder) {
        remove-item -Path $sitePath -Force -Confirm:$false -Recurse
      }
    }
   
    if ((Test-Path "IIS:\AppPools\$siteName") -eq $true) {
      # Delete site "Default Web Site"
      & $AppCmd  delete AppPool "${siteName}" | Out-Null
    }
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

    # Process Model 
    & $AppCmd set AppPool $siteName /processModel.idleTimeout:'01:00:00' /commit:apphost | Out-Null
    & $AppCmd set AppPool $siteName /processModel.pingResponseTime:'00:00:15' /commit:apphost | Out-Null
    & $AppCmd set AppPool $siteName /processModel.pingInterval:'00:00:30' /commit:apphost | Out-Null
    & $AppCmd set AppPool $siteName /processModel.shutdownTimeLimit:'00:00:30' /commit:apphost | Out-Null
    & $AppCmd set AppPool $siteName /processModel.startupTimeLimit:'00:00:30' /commit:apphost | Out-Null

    # start Mode 
    & $AppCmd set AppPool $siteName /startmode:"${startup}" /commit:apphost | Out-Null

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

    if (($isDev) -and ($siteName -like "*erp-mvx*")) {
      $PrivateDir = "C:\linx\${siteName}\private"
      If ((Test-Path $PrivateDir) -eq $false) {
        new-item -type Directory -path $PrivateDir | Out-Null
      }
      & $AppCmd  set config  -section:system.applicationHost/sites /+"[name='${siteName}'].[path='/'].[path='/Private', physicalPath='${PrivateDir}']" /commit:apphost | out-null
    }

  }
  
  if ($Customidentity) {
    $identity = @{ identitytype = "SpecificUser"; username = "${CustomIdentityLogin}"; password = "${CustomIdentityPassowrd}" }
    Set-ItemProperty -Path "IIS:\AppPools\$siteName" -name "processModel" -value $identity | Out-Null
    & $AppCmd set AppPool $appPool /processModel.LoadUserProfile:'true' /commit:apphost | Out-Null
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
      $LogValues = "Date, Time, ClientIP, UserName, SiteName, ComputerName, ServerIP, Method, UriStem, UriQuery, HttpStatus, Win32Status, BytesSent, BytesRecv, TimeTaken, ServerPort, UserAgent, Cookie, Referer, ProtocolVersion, Host, HttpSubStatus" 
      $settings = @{ logFormat = "W3c"; enabled = $true; directory = $logsPath; period = "Hourly" ; localTimeRollover = "True" ; logExtFileFlags = "${logValues}" }
      Set-ItemProperty "IIS:\Sites\$siteName" -name "logFile" -value $settings | Out-Null
  
      ## Custom Headers
      #$logValuesCustom = @{logFieldName = 'X-Forwarded-For'; sourceName = 'X-Forwarded-For'; sourceType = 'RequestHeader' }
      #Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name="${siteName}"]/logFile/customFields" -name "." -value $logValuesCustom

    }
    else {
      ## SET LOGS CONFIG
      $LogValues = "Date, Time, ClientIP, UserName, SiteName, ComputerName, ServerIP, Method, UriStem, UriQuery, HttpStatus, Win32Status, BytesSent, BytesRecv, TimeTaken, ServerPort, UserAgent, Cookie, Referer, ProtocolVersion, Host, HttpSubStatus" 
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

  if ($configRequestFiltering) {
    # SYSUSERS
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysusers', scanUrl='True', scanQueryString='True', scanAllRaw='False']" /commit:apphost | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysusers'].denyStrings.[string='sysusers']" /commit:apphost | out-null

    # SQLMAP
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sqlmap', scanUrl='True', scanQueryString='True', scanAllRaw='False']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sqlmap'].scanHeaders.[requestHeader='User-agent']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sqlmap'].denyStrings.[string='sqlmap']" | out-null

    # internet-crawlers
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers', scanUrl='False', scanQueryString='False', scanAllRaw='False']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].scanHeaders.[requestHeader='User-Agent']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='python']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='got']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='rest-client']" | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='mechanize']" | out-null

    # sysdatabases
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysdatabases', scanUrl='True', scanQueryString='True', scanAllRaw='False']" /commit:apphost | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysdatabases'].denyStrings.[string='sysdatabases']" /commit:apphost | out-null

    # information_schema
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='information_schema', scanUrl='True', scanQueryString='True', scanAllRaw='False']" /commit:apphost | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='information_schema'].denyStrings.[string='information_schema']" /commit:apphost | out-null

    # sysobjects
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysobjects', scanUrl='True', scanQueryString='True', scanAllRaw='False']" /commit:apphost | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysobjects'].denyStrings.[string='sysobjects']" /commit:apphost | out-null

    # table_schema
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='table_schema', scanUrl='True', scanQueryString='True', scanAllRaw='False']" /commit:apphost | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='table_schema'].denyStrings.[string='table_schema']" /commit:apphost | out-null

    # db_name
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='db_name', scanUrl='True', scanQueryString='True', scanAllRaw='False']" /commit:apphost | out-null
    & $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='db_name'].denyStrings.[string='DB_NAME%28']" /commit:apphost | out-null

    # RequestLimit
    & $AppCmd set config -section:system.webServer/security/requestFiltering /requestLimits.maxAllowedContentLength:'524288000' /commit:apphost | out-null 
  }


}


$microvixSites = @(
  [pscustomobject]@{Name = "crm" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "vendafacil" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "erp-mvx" ; is32bits = $true ; adminRights = $true ; ManagedPipeline = "Classic" ; CLR = "v4.0" ; type = "APP" ; login = $WebLogin; password = $WebPassword ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "erp-login" ; is32bits = $true ; adminRights = $true ; ManagedPipeline = "Classic" ; CLR = "" ; type = "APP" ; login = $WebLogin; password = $WebPassword ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "estoque" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "wms" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "hubvaletrocas" ; is32bits = $false ; ManagedPipeline = "Integrated" ; adminRights = $false ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "agendaservicos" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "implantar" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "erp-webapp" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "recuperadorcupomfiscal" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "APP" ; startupMode = "OnDemand" }
  [pscustomobject]@{Name = "nfe4" ; is32bits = $false ; adminRights = $true ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "APP" ; login = $WebLogin; password = $WebPassword ; startupMode = "OnDemand" }
)

$microvixAPIs = @(
  [pscustomobject]@{Name = "erpadmin" ; is32bits = $false ; adminRights = $false ; type = "API" ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "crm-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "otico-api" ; is32bits = $false ; adminRights = $false ; type = "API" ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "lgpdterceiros-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "agendaservicos-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "cobranca-linx-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "cobranca-extrator-catalogo-digital-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "fastpass-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "faturamentoservicosterceiros-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "imagensprodutos-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "relatorio-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "servicos-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "terceiros-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "giftcard-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "erpcore-api" ; is32bits = $false ; adminRights = $false ; type = "API"; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "nfe-api" ; is32bits = $false ; adminRights = $true ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "API"; login = $WebLogin; password = $WebPassword ; startupMode = "AlwaysRunning" }
  [pscustomobject]@{Name = "admfinanceiro" ; is32bits = $false ; adminRights = $false ; ManagedPipeline = "Integrated" ; CLR = "v4.0" ; type = "API" ; startupMode = "AlwaysRunning" }

)


if ($isDev) {

  [string] $projectName = "API"
  # Create  site with main server name
  $BindingPrimary = "${hostname}-${projectName}.${Domain}"
  [string] $path = "${pathWebSite}\${BindingPrimary}"

  # Verbose
  Write-Output @("
  Dev Default Site 
      Site name: ${projectName}
      Site Path is: ${path} 
      Binding: ${BindingPrimary}
  ")
  
  start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${BindingPrimary}" `
    -startup "OnDemand" `
    -dotnetCLR "" `
    -appPool32Bits $true `
    -PurgeSites $true

  # merge lists - When is Dev. The script will create a base site and all the webapps
  $allApps = & { 
    $microvixSites
  }

  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    # Dynamic Vars
    $siteBinding = "${hostname}-${projectName}-${envName}.${Domain}"
    $path = "${pathWebSite}\${siteBinding}"


    Write-Output @("
    Microvix Web: ${projectName}
      Site Path is: ${path} 
      Binding: ${siteBinding}
      32bits: $($item.is32bits)
      .NET CLR: $($item.CLR)
      ManagedPipeline: $($item.ManagedPipeline)
    ")

    If ($($item.adminRights)) { 
      start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${siteBinding}" `
        -startup "$($item.startupMode)"`
        -appPool32Bits $item.is32bits `
        -dotnetCLR $item.CLR `
        -ManagedPipelineMode $item.ManagedPipeline `
        -PurgeSites $true `
        -CustomIdentity $True `
        -CustomIdentityLogin $($item.login) `
        -CustomIdentityPassowrd $($item.password)
    }      
    Else { 
      start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${siteBinding}" `
        -startup "$($item.startupMode)" `
        -appPool32Bits $item.is32bits `
        -dotnetCLR $item.CLR `
        -ManagedPipelineMode $item.ManagedPipeline `
        -PurgeSites $true 
    }
    
  }
} 
else {
  # merge lists - When is not Dev. The script will create all sites needed
  $allApps = & { 
    $microvixSites
    $microvixAPIs
  }

  [string] $projectName = ($item).Name
  $siteBinding = "${projectName}-${envName}.${Domain}"
  $path = "${pathWebSite}\${siteBinding}"
  
  If ($($item.adminRights)) { 
    start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${siteBinding}" `
      -startup "$($item.startupMode)" `
      -appPool32Bits $item.is32bits `
      -dotnetCLR $item.CLR `
      -ManagedPipelineMode $item.ManagedPipeline `
      -PurgeSites $true `
      -CustomIdentity $True `
      -CustomIdentityLogin $($item.login) `
      -CustomIdentityPassowrd $($item.password)
  }      
  Else { 
    start-WebEnvironmentBuilder -sitePath "${path}" -siteName "${siteBinding}" `
      -startup "$($item.startupMode)"`
      -appPool32Bits $item.is32bits `
      -dotnetCLR $item.CLR `
      -ManagedPipelineMode $item.ManagedPipeline `
      -PurgeSites $true 
  }
}
