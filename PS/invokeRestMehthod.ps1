params(
[Parameter(Mandatory=$true)]
[string] $url
[string] $userName
[string] $pwd
[string] $method
)

###headers
# AzureDevops enables PAT, which allows $userName="" and $pwd=pat
$basicAuth = ("{0}:{1}" -f $userName,$pwd)
$basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
$basicAuth = [System.Convert]::ToBase64String($basicAuth)
$headers = @{Authorization=("Basic {0}" -f $basicAuth)}

###invoke
#$jsonResponse = Invoke-RestMethod -Uri $uri -UseDefaultCredentials -Method $method
$jsonResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method $method
