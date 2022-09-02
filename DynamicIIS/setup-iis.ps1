<#
 .Synopsis

 .Description


 .Parameter pathWebSite
  Path Windows do site 
 
  .Parameter pathLogs
  Path Windows log site
 
  .Parameter dnsFqdn
  Informe o DNS para configuracao so site

 .Parameter SiteName
  Nome do site principal do IIS

 .Parameter AppList


 .Parameter appPool_32bits


 .Example

#>
import-module WebAdministration

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
