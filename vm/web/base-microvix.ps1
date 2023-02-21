Write-Host 'Chocolatey Steps'  
Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# Choco Features
choco feature disable -n=showDownloadProgress; choco feature enable -n=allowGlobalConfirmation
# Install Apps with Choco
choco install notepadplusplus -y --force --force-dependencies --ignore-checksums ; choco install 7zip -y --force --force-dependencies --ignore-checksums
# Install MS SQL Driver Client
choco install sql2012.nativeclient -y --ignore-checksums 
# sysinternals, procdump, logparser
choco install procdump -y --ignore-checksums ; choco install debugdiagnostic -y --ignore-checksums

write-Host 'UAC - Disabled'
New-ItemProperty -Path 'HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\policies\\system' -Name 'EnableLUA' -PropertyType DWord -Value 0 -Force

write-Host 'FW - Disabled'
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

write-Host 'IE Protected Mode - Disabled'
Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components\\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name  'IsInstalled' -Value 0 -Force

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

# TCP/IP clients ports range
netsh int ipv4 set dynamicport tcp start=10000 num=54000

# Install WebDeploy
choco install webdeploy -y --ignore-checksums 

# Install Url Rewrite
choco install urlrewrite -y --ignore-checksums

# Default directory Linx
new-item -type Directory /linx

# AppCMD
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

# Server Config
& $AppCmd unlock config /section:system.webServer/handlers
& $AppCmd unlock config /section:system.webServer/modules
& $AppCmd unlock config /section:system.webServer/asp

# Disable HTTP v2 
New-ItemProperty -Path "HKLM:System\CurrentControlSet\Services\HTTP\Parameters" -Name 'EnableHttp2Tls' -PropertyType DWord -Value 0 -Force 
New-ItemProperty -Path "HKLM:System\CurrentControlSet\Services\HTTP\Parameters" -Name 'EnableHttp2Cleartext' -PropertyType DWord -Value 0 -Force

# Tunning - Set 20 threads peer Processor 
New-ItemProperty -Path "HKLM:System\CurrentControlSet\Services\InetInfo\Parameters" -Name 'MaxPoolThreads' -PropertyType DWord -Value 20 -Force

# Delete site "Default Web Site"
& $AppCmd delete site "Default Web Site"

# Remove Defaults
$AppPoolDft = @('Classic .NET AppPool', '.NET v2.0 Classic', '.NET v2.0', '.NET v4.5 Classic', '.NET v4.5', 'DefaultAppPool')
foreach ($a in $AppPoolDft) {
    & $AppCmd  delete AppPool $a
}

