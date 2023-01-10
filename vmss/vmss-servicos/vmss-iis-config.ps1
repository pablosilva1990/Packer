# AppCMD
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"
import-module WebAdministration

# Asp Upload
new-item -type Directory /upload

# Cria sites 
$siteList = @(
  [pscustomobject]@{Name = 'ESWEBAPI_PROD' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:eswebapi-prod.microvix.com.br' }
  [pscustomobject]@{Name = 'ESWEBAPI_RC' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:eswebapi-rc.microvix.com.br' }
  [pscustomobject]@{Name = 'FISCAL_PROD' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:fiscalwebapi-prod.microvix.com.br' }
  [pscustomobject]@{Name = 'FISCAL_RC'   ; SitePath = 'C:\Linx\ERP_RC'   ; Bindings = 'http/:80:fiscalwebapi-rc.microvix.com.br' }
  [pscustomobject]@{Name = 'LFA_PROD' ; SitePath = 'C:\Linx\ERP_PROD' ; Bindings = 'http/:80:lfa-prod.microvix.com.br' }
  [pscustomobject]@{Name = 'LFA_RC'   ; SitePath = 'C:\Linx\ERP_RC'   ; Bindings = 'http/:80:lfa-rc.microvix.com.br' }
) 
# Configure Site ERP SLOT 
Foreach ($item in $siteList) {
  $site = ($item).Name
  $path = ($item).SitePath
  $Bindings = ($item).Bindings
 
  new-item -type Directory -path $item.SitePath

  & $AppCmd add apppool /name:$site
  & $AppCmd add site /name:$site /physicalPath:$path /bindings:$Bindings
  # Adiciona um caracter slash / no final do nome do Site  
  & $AppCmd set app ($site + "/") /applicationPool:$site
  Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/sites/site[@name=`"$site`"]/applicationDefaults" -name "preloadEnabled" -value "True"
  
  # APP POOL CONFIG
  & $AppCmd set AppPool $Site /managedRuntimeVersion:'v4.0' /commit:apphost 
  & $AppCmd set AppPool $Site /managedPipelineMode:'Integrated' /commit:apphost
  & $AppCmd set AppPool $Site /enable32BitAppOnWin64:'false' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.idleTimeout:'01:00:00' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.pingResponseTime:'00:00:15' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.pingInterval:'00:00:30' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.shutdownTimeLimit:'00:00:30' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.startupTimeLimit:'00:00:30' /commit:apphost
  & $AppCmd set AppPool $Site /processModel.LoadUserProfile:'true' /commit:apphost
  & $AppCmd set AppPool $Site /startmode:'AlwaysRunning' /commit:apphost

  # Recycling Config
  & $AppCmd set AppPool $Site /-recycling.periodicRestart.time
  & $AppCmd set AppPool $Site /recycling.periodicRestart.time:"00:00:00" /commit:apphost
  & $AppCmd set AppPool $Site /recycling.periodicRestart.memory:'0' 
  & $AppCmd set AppPool $Site /recycling.periodicRestart.privateMemory:'0' /commit:apphost
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

