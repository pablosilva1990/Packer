# AppCMD
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"
import-module WebAdministration

# Cria estrutura inicial 
new-item -type Directory /linx/ERP_PROD
new-item -type Directory /linx/ERP_RC

# Asp Upload
new-item -type Directory /upload

# Cria sites 
$siteList = @(
  [pscustomobject]@{Name = 'linx.microvix.com.br' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:linx.microvix.com.br' }
  [pscustomobject]@{Name = 'linx02.microvix.com.br' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:linx02.microvix.com.br' }
  [pscustomobject]@{Name = 'linx03.microvix.com.br' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:linx03.microvix.com.br' }
  [pscustomobject]@{Name = 'linx-rc.microvix.com.br'   ; SitePath = 'C:\Linx\ERP_RC'   ; Bindings = 'http/:80:linx-rc.microvix.com.br' }
) 
# Configure Site ERP SLOT 
Foreach ($item in $siteList) {
  $site = ($item).Name
  $path = ($item).SitePath
  $Bindings = ($item).Bindings
 
  & $AppCmd add apppool /name:$site
  & $AppCmd add site /name:$site /physicalPath:$path /bindings:$Bindings
  # Adiciona um caracter slash / no final do nome do Site  
  & $AppCmd set app ($site + "/") /applicationPool:$site
  Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/site[@name=`"$site`"]/applicationDefaults" -name "preloadEnabled" -value "True"
  
  # APP POOL CONFIG
  & $AppCmd set AppPool $Site /managedRuntimeVersion:'' /commit:apphost 
  & $AppCmd set AppPool $Site /managedPipelineMode:'Classic' /commit:apphost
  & $AppCmd set AppPool $Site /enable32BitAppOnWin64:'true' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.idleTimeout:'01:00:00' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.pingResponseTime:'00:00:15' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.pingInterval:'00:00:30' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.shutdownTimeLimit:'00:00:30' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.startupTimeLimit:'00:00:30' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.LoadUserProfile:'true' /commit:apphost
  & $AppCmd set AppPool $Site /startmode:'OnDemand' /commit:apphost



  # Recycling Config
  & $AppCmd set AppPool $Site /-recycling.periodicRestart.time
  & $AppCmd set AppPool $Site /recycling.periodicRestart.time:"00:00:00" /commit:apphost
  & $AppCmd set AppPool $Site /recycling.periodicRestart.memory:'3481600' 
  & $AppCmd set AppPool $Site /recycling.periodicRestart.privateMemory:'2867200' /commit:apphost
}

# ASP CONFIG 
& $AppCmd set config -section:system.webServer/asp /scriptErrorSentToBrowser:'True' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /errorsToNTLog:'True' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /EnableParentPaths:'True' /commit:apphost 
  
# TrackingID MS 2208240040004733 - MTA must be disabled 
& $AppCmd  set config -section:system.webServer/asp /comPlus.executeInMta:'False' /commit:apphost 

& $AppCmd set config -section:system.webServer/asp /Session.timeOut:'00:20:00' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /Limits.bufferingLimit:'10094304' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /Limits.maxRequestEntityAllowed:'2147483647' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /Limits.processorThreadMax:'250' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /Limits.scriptTimeout:'00:10:00' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /cache.scriptFileCacheSize:'0' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /cache.maxDiskTemplateCacheFiles:'0' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /cache.scriptEngineCacheMax:'0' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /cache.enableTypelibCache:'True' /commit:apphost 
& $AppCmd set config -section:system.webServer/asp /cache.diskTemplateCacheDirectory:'c:\inetpub\temp\ASP Compiled Templates' /commit:apphost 

# Dynamic compression disabled
& $AppCmd set config -section:system.webServer/urlCompression /doDynamicCompression:'false' /commit:apphost 
& $AppCmd set config -section:system.webServer/httpCompression /minFileSizeForComp:2700 /commit:apphost 
& $AppCmd set config -section:system.webServer/httpCompression /maxDiskSpaceUsage:16000 /commit:apphost 

