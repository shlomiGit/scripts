####### vars #######
<#----------------#>
param(
#[string] $server = "[server]/[instance]",
[string] $server = "[server]/[instance]",
#[string] $Database='[db]',
[string] $Database='[db]',
[string] $table = "[table]"
)
[string] $mspId = Read-Host 'Please enter MSP Project Id'
[string] $CommandText = "select * from $table where id=$mspId"

####### connection #######
#------------------------#
$conn=new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server=$server;Database=$Database;Integrated Security=SSPI;Connect Timeout=10;User Id=app_jiraadmin"
$conn.ConnectionString=$ConnectionString
$conn.Open()

####### command #######
#---------------------#
$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $conn
$Command.CommandText = $CommandText 
#$Command.ExecuteReader()
$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
$dataset = New-Object System.Data.DataSet
$adapter.Fill($dataSet) | Out-Null
$conn.Close()

####### output #######
#--------------------#
[string] $outputPath = 'C:\temp\1.txt'
write-host "Please read $outputPath"
$dataSet.Tables > $outputPath
pause
