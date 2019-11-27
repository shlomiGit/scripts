#file for encripted pswd
$filePath = 'c:\temp\encPswd.txt'

#save pswd from user input to encripted file
Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File $filePath

#get pswd as secureString
[SecureString] $securePassword = ConvertTo-SecureString (Get-Content $filePath)

#PScredential object
[pscredential] $ServiceAccountCreds = new-object -TypeName pscredential($username,$securePassword)
