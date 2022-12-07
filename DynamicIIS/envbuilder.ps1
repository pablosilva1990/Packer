<#
 .Synopsis

 .Description

  .PARAMETER envName 
  Esse parametro pode ser aceitacao, prod, rc, hom, etc 
  Pode usar para simbolizar um nome de portal também. Ex: 9090

 .ServerBuilder Microvix
 .\envbuilder.ps1  -EnvServerBuilder $true

 .Example Microvix DEV
  
 # EXP Clientes
    .\envbuilder.ps1 -envName 9040 -domain microvix.com.br -hostname expclientes `
      -pathWebSite "c:\linx" -webLogin "linxsaas\svc.mvxdev" -WebPass "SAd213@1919_02" -isDev $true `
      -CsvImportList "C:\Temp\site-list.csv"
    .\envbuilder.ps1 -envName 9049 -domain microvix.com.br -hostname expclientes `
      -pathWebSite "c:\linx" -webLogin "linxsaas\svc.mvxdev" -WebPass "SAd213@1919_02" -isDev $true `
       -CsvImportList "C:\Temp\site-list.csv"
 
 .Example Microvix Web Server 
 
  # ACEITACAO
 .\envbuilder.ps1 -envName "aceitacao" -domain microvix.com.br -pathWebSite "c:\linx"  -CsvImportList "C:\Temp\site-list.csv" -webLogin "linxsaas\svc.mvxacpt" -WebPass

  # HOMOLOGACAO
  .\envbuilder.ps1 -envName "homologacao" -domain "microvix.com.br" -pathWebSite "c:\linx"  -CsvImportList "C:\Temp\site-list.csv" -webLogin "linxsaas\svc.mvxhom" -WebPass
 
 .EXAMPLE remove-WebEnvironmentBuilder
  .\envbuilder.ps1 -EnvBuilderCleanUp $true

#>
param (
  [string] $pathWebSite = "c:\linx" ,
  [string] $logsPath = "c:\site\logs" ,
  [string] $HostName ,
  [string] $envName ,
  [string] $Domain ,
  [string] $CsvImportList = "C:\temp\site-list.csv",
  [bool] $bulkImport = $true,
   
  
  [string]$WebLogin ,
  [string]$WebPass ,

  [bool] $isDev = $false,
  
  [bool]$EnvServerBuilder = $false,
  [bool]$EnvBuilderCleanUp = $false

)

import-module .\envbuilder.psm1

if ($EnvServerBuilder) {
  start-EnvironmentBuilderBase
  break
}

if ($EnvBuilderCleanUp) {
  remove-EnvironmentBuilderApps 
  break
}

IF ($bulkImport) {
  $SitesMicrovix = import-csv $CsvImportList
}


if ($isDev) {

  ## Crite site ERP DEV 
  start-EnvironmentBuilderApps `
    -sitePath "${pathWebSite}\erp-linx-${hostname}.${Domain}" `
    -siteName "erp-linx-${hostname}.${Domain}" `
    -startup "OnDemand" `
    -ManagedPipelineMode "Classic" `
    -dotnetCLR "" `
    -appPool32Bits $true `
    -CustomIdentity $True `
    -CustomIdentityLogin $WebLogin `
    -CustomIdentityPassowrd $WebPass
  
  ## Crite site LOGIN ERP DEV 
  start-EnvironmentBuilderApps `
    -sitePath "${pathWebSite}\login-${hostname}.${Domain}" `
    -siteName "login-${hostname}.${Domain}" `
    -startup "OnDemand" `
    -ManagedPipelineMode "Classic" `
    -dotnetCLR "" `
    -appPool32Bits $true `
    -CustomIdentity $True `
    -CustomIdentityLogin $WebLogin `
    -CustomIdentityPassowrd $WebPass

  # merge lists - When is Dev. The script will create a base site and all the webapps
  $allApps = & { 
    $SitesMicrovix
  }
  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    $siteBinding = "${envName}-${projectName}-${hostname}.${Domain}"
    $path = "${pathWebSite}\${envName}\${projectName}"

    start-EnvironmentBuilderApps `
      -sitePath "${path}" `
      -siteName "${siteBinding}" `
      -startup "$($item.startupMode)" `
      -appPool32Bits $item.is32bits `
      -dotnetCLR $item.CLR `
      -ManagedPipelineMode $item.ManagedPipeline `
      -CustomIdentity $item.adminRights `
      -CustomIdentityLogin $WebLogin `
      -CustomIdentityPassowrd $WebPass
  }
} 
else {
  # merge lists - When is not Dev. The script will create all sites needed
  $allApps = & { 
    $SitesMicrovix
  }

  start-EnvironmentBuilderApps `
    -sitePath "${pathWebSite}\erp-${envName}.${Domain}" `
    -siteName "erp-${envName}.${Domain}" `
    -startup "OnDemand" `
    -ManagedPipelineMode "Classic" `
    -dotnetCLR "" `
    -appPool32Bits $true `
    -CustomIdentity $True `
    -CustomIdentityLogin $WebLogin `
    -CustomIdentityPassowrd $WebPass

  ## Crite site LOGIN ERP  
  start-EnvironmentBuilderApps `
    -sitePath "${pathWebSite}\login-${envName}.${Domain}" `
    -siteName "login-${envName}.${Domain}" `
    -startup "OnDemand" `
    -ManagedPipelineMode "Classic" `
    -dotnetCLR "" `
    -appPool32Bits $true `
    -CustomIdentity $True `
    -CustomIdentityLogin $WebLogin `
    -CustomIdentityPassowrd $WebPass

  foreach ($item in $allApps) {
    [string] $projectName = ($item).Name
    $siteBinding = "${projectName}-${envName}.${Domain}"
    $path = "${pathWebSite}\${siteBinding}"
  
    start-EnvironmentBuilderApps `
      -sitePath "${path}" `
      -siteName "${siteBinding}" `
      -startup "$($item.startupMode)"`
      -appPool32Bits $item.is32bits `
      -dotnetCLR $item.CLR `
      -ManagedPipelineMode $item.ManagedPipeline `
      -CustomIdentity $item.adminRights `
      -CustomIdentityLogin $WebLogin `
      -CustomIdentityPassowrd $WebPass
  }
}

