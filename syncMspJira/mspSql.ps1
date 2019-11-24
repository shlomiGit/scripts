####### vars #######
<#----------------#>
param(
[string] $server = "[server]\[instance]",
[string] $Database='[db]',
[string] $table = "[table]",
### prod
#[string] $CommandText = "select distinct Portfolio from $table "
# --this was part of the initial query to include pre-2019 proj's:
#[string] $CommandText = "select * from $table where convert(datetime, StartDate, 103) < convert(datetime, '01/01/2019', 103) and Status like 'בעבודה'"
[string] $CommandText = "select * from $table where convert(datetime, StartDate, 103) > convert(datetime, '01/01/2016', 103)"
### test
#[string] $CommandText = "select * from $table where id='10454'"
#[string] $CommandText = "select Name, StartDate, PotentialType from $table" #where TaskStatus like 'בעבודה' and TaskFinishDate > Convert(datetime, '1/1/2014')"
)

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
return $dataSet.Tables #> C:\temp\1.txt

<#
$cmd = "select Name, StartDate, PotentialType from $table"
$objdataset = Invoke-Sqlcmd -query $cmd -server $server -Database $Database
$objdataset
#>
