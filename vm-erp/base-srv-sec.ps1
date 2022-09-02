write-Host "Crowdstrike install"

# create temp folder
new-item -type Directory c:\temp

# Download Falcon client
$URI = "https://stgmvxdevops.blob.core.windows.net/files/Windows/WindowsCsFalcon.zip"
$filePath = "$env:SystemDrive\temp\WindowsCsFalcon.zip"
Invoke-WebRequest -Uri $uri -OutFile $filePath

# Unzip
Expand-Archive -LiteralPath "C:\temp\WindowsCsFalcon.zip" -DestinationPath "C:\temp"

# Install
cmd /c "c:\temp\WindowsSensor.MaverickGyr.exe /install /quiet /norestart CID=BB3EF18B04624B099032B84EF9F1EA96-9F"

# Remove files
Remove-Item -Recurse -Force -Confirm:$false -path c:\temp