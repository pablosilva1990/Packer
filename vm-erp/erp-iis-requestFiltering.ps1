# AppCMD
$AppCmd = "$env:WinDir\system32\inetsrv\AppCmd.exe"

# SYSUSERS
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysusers',scanUrl='True',scanQueryString='True',scanAllRaw='False']" /commit:apphost
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysusers'].denyStrings.[string='sysusers']" /commit:apphost

# SQLMAP
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sqlmap',scanUrl='True',scanQueryString='True',scanAllRaw='False']" 
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sqlmap'].scanHeaders.[requestHeader='User-agent']" 
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sqlmap'].denyStrings.[string='sqlmap']"

# internet-crawlers
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers',scanUrl='False',scanQueryString='False',scanAllRaw='False']" 
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].scanHeaders.[requestHeader='User-Agent']" 
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='python']"
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='got']"
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='internet-crawlers'].denyStrings.[string='rest-client']"

# sysdatabases
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysdatabases',scanUrl='True',scanQueryString='True',scanAllRaw='False']" /commit:apphost
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysdatabases'].denyStrings.[string='sysdatabases']" /commit:apphost

# information_schema
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='information_schema',scanUrl='True',scanQueryString='True',scanAllRaw='False']" /commit:apphost
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='information_schema'].denyStrings.[string='information_schema']" /commit:apphost

# sysobjects
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysobjects',scanUrl='True',scanQueryString='True',scanAllRaw='False']" /commit:apphost
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='sysobjects'].denyStrings.[string='sysobjects']" /commit:apphost

# table_schema
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='table_schema',scanUrl='True',scanQueryString='True',scanAllRaw='False']" /commit:apphost
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='table_schema'].denyStrings.[string='table_schema']" /commit:apphost

# db_name
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='db_name',scanUrl='True',scanQueryString='True',scanAllRaw='False']" /commit:apphost
& $AppCmd  set config -section:system.webServer/security/requestFiltering /+"filteringRules.[name='db_name'].denyStrings.[string='DB_NAME%28']" /commit:apphost

# RequestLimit
& $AppCmd set config -section:system.webServer/security/requestFiltering /requestLimits.maxAllowedContentLength:'524288000' /commit:apphost 
