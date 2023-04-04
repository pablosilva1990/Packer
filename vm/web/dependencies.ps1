Write-Host 'Chocolatey Steps'  
Install-PackageProvider Nuget -ForceBootstrap -Force -Confirm:$false
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# Choco Features
choco feature disable -n=showDownloadProgress; choco feature enable -n=allowGlobalConfirmation

# Install Dotnet with Choco
choco install dotnetcore-runtime --version=2.2.8 -y --force --force-dependencies --ignore-checksums
choco install dotnetcore-3.1-windowshosting -y --force --force-dependencies --ignore-checksums
choco install dotnet-5.0-runtime -y --force --force-dependencies --ignore-checksums
choco install dotnet-5.0-windowshosting -y --force --force-dependencies --ignore-checksums
choco install dotnet-6.0-runtime -y --force --force-dependencies --ignore-checksums
choco install dotnet-6.0-windowshosting -y --force --force-dependencies --ignore-checksums
choco install dotnet-7.0-windowshosting -y --force --force-dependencies --ignore-checksums