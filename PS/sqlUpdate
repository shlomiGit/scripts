params(
[string] $server,
[string] $Database,
[string] $table,
[string] $userName,
[string] $pwd
)

$conn=new-object System.Data.SqlClient.SQLConnection
$ConnectionString = "Server=$server;Database=$Database;Integrated Security=SSPI;User ID=$userName;Password=$pwd;Connect Timeout=10"
$conn.ConnectionString=$ConnectionString
$conn.Open()

$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $conn
$Command.CommandText = "INSERT INTO $table VALUES ('$Type', '$Version', 'I:\eng\Maxx\Firmware\Versions\Release 1.0\$Version\$Type', '1', '0')"
$Command.ExecuteReader()

$conn.Close()
