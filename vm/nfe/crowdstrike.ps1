$uri = "https://stgmvxdevops.blob.core.windows.net/files/Windows/WindowsCsFalcon.zip"
$filePath = "c:\temp\WindowsCsFalcon.zip"

Invoke-WebRequest -Uri $uri -OutFile $filePath

Expand-Archive -LiteralPath "C:\temp\WindowsCsFalcon.zip" -DestinationPath "C:\temp"

cmd /c "c:\temp\WindowsSensor.MaverickGyr.exe /install /quiet /norestart CID=BB3EF18B04624B099032B84EF9F1EA96-9F"