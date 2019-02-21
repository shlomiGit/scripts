param(
[string] $server,
[string] $sqlInstance,
[string] $server,
[string] $Database,
[string] $table
)

$conn=new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server=$server\$sqlInstance;Database=$Database;Integrated Security=SSPI;Connect Timeout=10"

$conn.ConnectionString=$ConnectionString
$conn.Open()

$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $conn
#$Command.CommandText = "INSERT INTO $table VALUES ('$Type', '$Version', 'I:\eng\Maxx\Firmware\Versions\Release 1.0\$Version\$Type', '1', '0')"
$Command.CommandText = "select * from $table"
#$Command.ExecuteReader()
$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
$dataset = New-Object System.Data.DataSet
$adapter.Fill($dataSet) | Out-Null

$conn.Close()
$dataSet.Tables
