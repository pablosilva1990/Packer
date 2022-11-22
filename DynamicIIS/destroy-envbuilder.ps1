<#
 .Synopsis

 .Description

 .Parameter pathWebSite
  Path Windows do site 

  .Parameter dnsHostFqdn
  Informe o DNS para configuracao so site

  .Parameter UseCustomUsername

  .PARAMETER envName 
  Esse parametro pode ser aceitacao, prod, rc, hom, etc 
  Pode usar para simbolizar um nome de portal também. Ex: 9090

 .Example Microvix DEV
 $SecurePassword = ConvertTo-SecureString "SAd213@1919_02" -AsPlainText -Force
 .\envbuilder.ps1 -envName 9040 -domain microvix.com.br -hostname expclientes -pathWebSite "c:\linx" -webLogin "linxsaas\svc.mvxdev" -webPassword $SecurePassword -isDev $true -CsvImportList "C:\Temp\site-list.csv"
 
 .Example Microvix Web Server 
 $SecurePassword = ConvertTo-SecureString "Pa$$w0rdMicrovixSitesIIS" -AsPlainText -Force
 .\envbuilder.ps1 -envName aceitacao -domain microvix.com.br -hostname devops -pathWebSite "c:\linx\devops" -webLogin "linxsaas\svc.vmaceitacao" -webPassword $SecurePassword
 
 .EXAMPLE remove-WebEnvironmentBuilder
  .\envbuilder.ps1 -EnvBuilderCleanUp $true -envName aceitacao -domain microvix.com.br -hostname devops -pathWebSite "c:\linx\devops"

#>
param (
  [string] $pathWebSite = "c:\linx" ,
  [string] $logsPath = "c:\site\logs" ,
  [string] $HostName ,
  [string] $envName ,
  [string] $Domain ,

  [string] $CsvImportList,
   
  [bool] $setWebServerDefaults = $true ,
  
  [bool] $EnvBuilderPurgeDefaults = $true ,
  [bool] $EnvBuilderPurgeSites = $false ,

  [bool] $UseCustomUsername = $false ,
  [string]$WebLogin ,
  [securestring]$WebPassword ,

  [bool] $isDev = $false,


  [bool]$EnvBuilderCleanUp = $false

)

function remove-WebEnvironmentBuilder {
  param (
    # General Settings
    [string]$siteName,
    [string]$sitePath
  )
  
  import-module WebAdministration
  $AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"
  write-output "Purging site: ${siteName}" 

  if ((Test-Path "IIS:\sites\$siteName") -eq $true) {
    # Delete site "Default Web Site"
    write-output "Purging site ${siteName}" 
    & $AppCmd delete site "${siteName}" | Out-Null 
    remove-item -Path $sitePath -Force -Confirm:$false -Recurse
  }
   
  if ((Test-Path "IIS:\AppPools\$siteName") -eq $true) {
    # Delete site "Default Web Site"
    & $AppCmd  delete AppPool "${siteName}" | Out-Null
  }
}


<# Se precessa Lista 
 De finir variable e parametro no script envbuilder.ps1

#>
$bulkImport = $true
#$importCsv = "C:\git\git-linx\Packer\DynamicIIS\site-list.csv"
IF ($bulkImport) {
  $SitesMicrovix = import-csv $CsvImportList
}


if ($EnvBuilderCleanUp) {
  [string] $projectName = ($item).Name
  $siteBinding = "${projectName}-${envName}.${Domain}"
  $path = "${pathWebSite}\${siteBinding}"
  remove-WebEnvironmentBuilder -sitePath "${path}" -siteName "${siteBinding}"
}



if ($isDev) {

  # merge lists - When is Dev. The script will create a base site and all the webapps
  $allApps = & { 
    $SitesMicrovix
  }

  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    # Dynamic Vars
    $siteBinding = "${envName}-${projectName}-${hostname}.${Domain}"
    $path = "${pathWebSite}\${siteBinding}"


    Write-Output @("
    Microvix Web: ${projectName}
      Site Path is: ${path} 
      Binding: ${siteBinding}
      32bits: $($item.is32bits)
      .NET CLR: $($item.CLR)
      ManagedPipeline: $($item.ManagedPipeline)
    ")

    
  }
} 
else {
  # merge lists - When is not Dev. The script will create all sites needed
  $allApps = & { 
    $SitesMicrovix
  }

  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    $siteBinding = "${projectName}-${envName}.${Domain}"
    $path = "${pathWebSite}\${siteBinding}"


  }
}

