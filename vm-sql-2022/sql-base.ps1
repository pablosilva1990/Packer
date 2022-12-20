Write-Host 'Chocolatey Steps'  
Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco feature disable -n=showDownloadProgress; choco feature enable -n=allowGlobalConfirmation
choco install notepadplusplus -y --force --force-dependencies --ignore-checksums
choco install 7zip -y --force --force-dependencies --ignore-checksums
choco install procdump -y --ignore-checksums ; 

write-Host 'UAC - Disabled'
New-ItemProperty -Path 'HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\policies\\system' -Name 'EnableLUA' -PropertyType DWord -Value 0 -Force

write-Host 'FW - Disabled'
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

write-Host 'IE Protected Mode - Disabled'
Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components\\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -Name  'IsInstalled' -Value 0 -Force

# Start Windows Update
Set-Service -Name wuauserv -StartupType Manual

# TCP/IP clients ports range
netsh int ipv4 set dynamicport tcp start=10000 num=54000

