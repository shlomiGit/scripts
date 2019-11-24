param(
	[string] $password,
  [string] $username
)
$path = "$PSScriptRoot\mspJiraSync.ps1"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

[pscredential] $ServiceAccountCreds = new-object -TypeName pscredential($username,$securePassword)
Start-Process powershell -Credential $ServiceAccountCreds -ArgumentList '-executionpolicy','bypass','-file',$path
