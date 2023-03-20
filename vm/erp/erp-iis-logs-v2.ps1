# AppCMD
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

# Site level Config (Logs, Site parameters)

& $AppCmd set config -section:system.webServer/httpErrors /errorMode:Custom /commit:apphost 
& $AppCmd set config -section:system.webServer/httpLogging /selectiveLogging:"LogAll" /commit:apphost
& $AppCmd set config -section:system.applicationHost/log /centralW3CLogFile.period:"Hourly" /commit:apphost
& $AppCmd set config -section:system.applicationHost/sites /siteDefaults.logFile.enabled:"True" /commit:apphost 
& $AppCmd set config -section:system.applicationHost/sites /siteDefaults.logFile.period:"Hourly" /commit:apphost
& $AppCmd set config -section:system.applicationHost/sites /siteDefaults.logFile.logTargetW3C:'File' /commit:apphost 
& $AppCmd set config -section:system.applicationHost/log /centralW3CLogFile.localTimeRollover:"True" /commit:apphost
& $AppCmd set config -section:system.applicationHost/sites /siteDefaults.logFile.LocalTimeRollover:'True' /commit:apphost 
& $AppCmd set config -section:system.applicationHost/sites /+"siteDefaults.logFile.customFields.[logFieldName='X-Forwarded-For',sourceName='X-Forwarded-For',sourceType='RequestHeader']" /commit:apphost
& $AppCmd set config -section:system.applicationHost/sites /siteDefaults.logFile.logExtFileFlags:"Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Cookie,Referer,ProtocolVersion,Host,HttpSubStatus"  /commit:apphost
# & $AppCmd set config  -section:system.applicationHost/sites /siteDefaults.logFile.directory:"d:\logs"  /commit:apphost # Configuração post deployment