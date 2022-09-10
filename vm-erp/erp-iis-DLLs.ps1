#############################
# Microvix DLLs
#############################

Write-Host "Download the DLL zip"
$URI = "https://stgmvxdevops.blob.core.windows.net/files/ERP/DLLs.zip"
$filePath = "$env:SystemDrive\linx\Dlls.zip"
Invoke-WebRequest -Uri $uri -OutFile $filePath

write-host "Unzip DLL"
Expand-Archive -LiteralPath "C:\linx\dlls.zip" -DestinationPath "C:\LINX"

# DLL - AspUpload 
write-Host "Load AspUpload3"
copy-item c:\linx\DLLs\aspupload.dll c:\WINDOWS\SysWOW64\
regsvr32 /s c:\WINDOWS\SysWOW64\aspupload.dll
#New-Item -Path "hklm:\SOFTWARE\Wow6432Node\Persits Software\AspUpload3\RegKey"
#New-ItemProperty -Path 'hklm:\SOFTWARE\Wow6432Node\Persits Software\AspUpload3\RegKey' -Name '(Default)' -PropertyType String -Value 37933-80594-93947 -Force

# DLL - Linx Microvix Arrendondar 
# Rotina Ansible para automatizar a reaplicação
write-Host "Load Linx.Microvix.Arrendondar.dll"
copy-item c:\linx\DLLs\Linx.Microvix.Arredondar.dll c:\WINDOWS\SysWOW64\
#cmd /c "C:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe c:\WINDOWS\SysWOW64\Linx.Microvix.Arredondar.dll /codebase"
#
$STPrin = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\RegAsm.exe c:\WINDOWS\SysWOW64\Linx.Microvix.Arredondar.dll /codebase'"
$Trgs = @(
    $(New-ScheduledTaskTrigger -AtStartup),
    $(New-ScheduledTaskTrigger -Daily -At 6:30am)
)
Register-ScheduledTask -Action $action -Trigger $Trgs -Principal $STPrin -TaskPath "LINX_MICROVIX" -TaskName "LoadDLL_LinxMicrovixArrendondar" -Description "Load arrendondar DLL every day" 

# DLL - Biometria 
write-Host "Load DLL Biometria and Webcam"
copy-item c:\linx\DLLS\Biometria\VenusDrv.sys c:\WINDOWS\SysWOW64\Drivers\
copy-item c:\linx\DLLS\Biometria\NBioBSP.dll c:\WINDOWS\SysWOW64\
copy-item c:\linx\DLLS\Biometria\Venus.dll c:\WINDOWS\SysWOW64\
copy-item c:\linx\DLLS\Biometria\NbioBspCom.dll c:\WINDOWS\SysWOW64\
regsvr32 /s c:\windows\sysWow64\nbiobspcom.dll 

# Cleanup 
write-Host "Cleanup Zip"
Remove-Item -Force -Confirm:$false -path c:\Linx\Dlls.zip
