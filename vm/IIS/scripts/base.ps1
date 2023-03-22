# Adiciona Appcmd no path Windows
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";c:\Windows\system32\inetsrv", [EnvironmentVariableTarget]::Machine)


# Start Windows Update
Set-Service -Name wuauserv -StartupType Manual

# .NET 3.5 (Classic ASP req)
Install-WindowsFeature -Name NET-Framework-Features

# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools 

# Install IIS Reques ERP
Install-WindowsFeature `
    Web-Http-Redirect, Web-Custom-Logging, Web-Http-Logging, Web-Static-Content, Web-Http-Errors, `
    Web-Log-Libraries, Web-ODBC-Logging, Web-Http-Tracing, `
    Web-Stat-Compression, Web-Dyn-Compression, `
    Web-Basic-Auth, Web-CertProvider, Web-Cert-Auth, `
    Web-Client-Auth, Web-Digest-Auth, Web-IP-Security, Web-Url-Auth, Web-App-Dev, `
    Web-AppInit, Web-ASP, Web-Asp-Net, Web-Asp-Net45, Web-Net-Ext, Web-Net-Ext45, `
    Web-CGI, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Includes, Web-WebSockets, `
    Web-Request-Monitor, Web-Mgmt-Tools, Web-Scripting-Tools


# AppCMD
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

# Delete site "Default Web Site"
& $AppCmd delete site "Default Web Site"

# Remove Defaults
$AppPoolDft = @('Classic .NET AppPool', '.NET v2.0 Classic', '.NET v2.0', '.NET v4.5 Classic', '.NET v4.5', 'DefaultAppPool')
foreach ($a in $AppPoolDft) {
    & $AppCmd  delete AppPool $a
}

