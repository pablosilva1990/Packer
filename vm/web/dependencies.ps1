Write-Host 'Chocolatey Steps'  
Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# Choco Features
choco feature disable -n=showDownloadProgress; choco feature enable -n=allowGlobalConfirmation
# Install Apps with Choco
choco install dotnet-7.0-windowshosting -y --force --force-dependencies --ignore-checksums