param(
[Parameter(Mandatory=$true)]
[string] $url,
[string] $userName,
[secureString] $pwd,
[string] $method
)

###headers
# AzureDevops enables PAT, which allows $userName="" and $pwd=pat
$basicAuth = ("{0}:{1}" -f $userName,$pwd)
$basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
$basicAuth = [System.Convert]::ToBase64String($basicAuth)
$headers = @{Authorization=("Basic {0}" -f $basicAuth)}

######### headers object #########
$headersObj = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headersObj.Add("Authorization","Basic Z19zemVldmk6U2hsMTIzNDU2")
$headersObj.Add("X-Atlassian-Token","nocheck")

### creds ###
[pscredential] $creds = New-Object pscredential($userName, $pwd)

###invoke
#$jsonResponse = Invoke-RestMethod -Uri $uri -UseDefaultCredentials -Method $method
$jsonResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method $method
