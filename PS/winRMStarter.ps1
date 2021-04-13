### vars
[string] $targetName
[string] $targetIp
[string] $userName
[SecureString] $securePassword = Read-Host -AsSecureString
#or [SecureString] $securePassword = ConvertTo-SecureString -Force -AsPlainText -String 'pswdStringHere'

### enable winRM on target machine
#Enable-PSRemoting

### test connection from source machine
#Test-WsMan $targetName
#Test-WsMan $targetIp

### authenticate
[pscredential] $creds = new-object -TypeName pscredential($userName,$securePassword)

### single cmd
Invoke-Command -ComputerName $targetName -ScriptBlock { Get-ChildItem C:\ } -credential $creds

### Start a Remote Session
Enter-PSSession -ComputerName $targetName -Credential $creds
