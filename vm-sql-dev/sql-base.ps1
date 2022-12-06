
# setup.exe /Q /IACCEPTSQLSERVERLICENSETERMS /ACTION="install" /FEATURES=SQL
# /SUPPRESSPRIVACYSTATEMENTNOTICE
# /INSTANCENAME=MSSQLSERVER
# /SQLSVCACCOUNT="LINXSAAS\00.mvxsqladmin"
# /SQLSVCPASSWORD="Gbn2bn8Gq&rYQ%4*"
# /SQLSYSADMINACCOUNTS="LINXSAAS\00.mvxsqladmin"
# /AGTSVCACCOUNT="LINXSAAS\00.mvxsqladmin" /AGTSVCPASSWORD="Gbn2bn8Gq&rYQ%4*"
# /SQLSVCSTARTUPTYPE="Automatic"
# /AGTSVCSTARTUPTYPE="Automatic"
# /BROWSERSVCSTARTUPTYPE="Disabled"
# /SECURITYMODE=SQL
# /SAPWD="Gbn2bn8Gq&rYQ%4*"
# /SQLTEMPDBDIR="D:\TempDB\Data"
# /SQLTEMPDBLOGDIR="D:\TempDB\Log"
# /SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
# /SQLUSERDBDIR="F:\Data"
# /SQLUSERDBLOGDIR="G:\Log"
# /TCPENABLED=1
# /NPENABLED=1
# /PID="AAAAA-BBBBB-CCCCC-DDDDD-EEEEE"

# # Levando em consideração que existem as unidades D F e G. Existem as pastas D:\TempDB\Data, D:\TempDB\Log, F:\Data e G:\Log. A senha de SA não é esta, mas este usuário ficará desabilitado, ele só deve ser utilizado para criar os usuários de BD. O PID é o serial do SQL Server, o que está acima é um exemplo.