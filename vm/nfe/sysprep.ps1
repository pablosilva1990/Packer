Write-Output '>>> Waiting for GA Service (RdAgent) to start ...'
while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }

#Write-Output '>>> Waiting for GA Service (WindowsAzureTelemetryService) to start ...'
#while ((Get-Service WindowsAzureTelemetryService) -and ((Get-Service WindowsAzureTelemetryService).Status -ne 'Running')) { Start-Sleep -s 5 }

Write-Output '>>> Waiting for GA Service (WindowsAzureGuestAgent) to start ...'
while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }

Write-Output '>>> Adding Registry Key mitigate the #Stuck at azure-arm: IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE ...'
New-Item -Path HKLM:\Software\Microsoft\DesiredStateConfiguration
New-ItemProperty -Path HKLM:\Software\Microsoft\DesiredStateConfiguration -Name 'AgentId' -PropertyType STRING -Force


Write-Output '>>> Sysprepping VM ...'
if( Test-Path $Env:SystemRoot\system32\Sysprep\unattend.xml ) {
    Remove-Item $Env:SystemRoot\system32\Sysprep\unattend.xml -Force
}

& $Env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet /quit
while($true) {
    $imageState = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State).ImageState
    Write-Output $imageState
    if ($imageState -eq 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { break }
    Start-Sleep -s 5
  }
Write-Output '>>> Sysprep complete ...'