param(
[Parameter(Mandatory=$true)]
[string] $url,
[string] $userName,
[secureString] $pwd,
[string] $method
)

###headers
# AzureDevops enables PAT, which allows $userName="" and $pwd=pat
[string] $basicAuth = ("{0}:{1}" -f $userName,$pwd)
[byte[]] $basicAuthBytes = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
[string] $basicAuth64String = [System.Convert]::ToBase64String($basicAuthBytes)
$headers = @{Authorization=("Basic {0}" -f $basicAuth64String)}

######### headers object #########
$headersObj = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headersObj.Add("Authorization","Basic Z19zemVldmk6U2hsMTIzNDU2")
$headersObj.Add("X-Atlassian-Token","nocheck")

### creds ###
[pscredential] $creds = New-Object pscredential($userName, $pwd)

###invoke
try{
  #$jsonResponse = Invoke-RestMethod -Uri $uri -UseDefaultCredentials -Method $method
  $jsonResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method $method -OutFile [path] -PassThru
}catch{
  Out-File -FilePath "$PSScriptRoot\logs\jsonError.json" -InputObject $_.Exception.Response
}
