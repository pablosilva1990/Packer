$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
invoke-webrequest -uri $url -OutFile $file -useBasicParsing
powershell.exe -ExecutionPolicy ByPass -File $file -DisableBasicAuth
winrm quickconfig -q