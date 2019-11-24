####### curl structure #######
<#---------------------------#>
#curl -X POST --insecure "https://[server]:[port]/rest/jiracustomfieldeditorplugin/1/user/customfields/10300/contexts/default/options" -H "accept: application/json" -H "authorization: Basic Z19zemVldmk6U2hsMTIzNDU2" -H "Content-Type: application/json" -d "{ \"optionvalue\": \"Project5\"}"
<#
    curl 
    -X 
    POST 
    --insecure 
    "https://[server]:[port]/rest/jiracustomfieldeditorplugin/1/user/customfields/10300/contexts/default/options" 
    -H "accept: application/json" 
    -H "authorization: Basic Z19zemVldmk6U2hsMTIzNDU2" 
    -H "Content-Type: application/json" 
    -d "{ \"optionvalue\": \"Project5\"}"
#>

####### params #######
<#------------------#>
param(
    [string]$funcName,
    [string]$arg,
    [string]$env
)

####### vars #######
<#----------------#>
$curl = "C:\Temp\curl\curl-7.62.0-win64-mingw\bin\curl.exe"
$contentType = "application/json"
[string] $jiraServer = "https://[server]:[port]"
$env = 'PROD'
if($env -eq 'PROD'){
    [string] $jiraServer = "https://[server]:[port]"
}
[string] $scriptsPath = $PSScriptRoot

####### auth #######
<#----------------#>
$authHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$authHeaders.Add("Authorization","Basic YXBwX2ppcmFhZG1pbjokOCo1eG1LVA==")

<#
$userName = 'app_jiraadmin'
#[securestring] $pwd = Get-Content "C:\Temp\pwd.txt" | ConvertTo-SecureString
$basicAuth = ("{0}:{1}" -f $userName,$pwd)
$basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
$basicAuth = [System.Convert]::ToBase64String($basicAuth)
#$basicAuth
#break
$headers = @{Authorization=("Basic {0}" -f $basicAuth)}
<# #>

####### functions #######
<#---------------------#>
function addOption([string] $optionValue){
#& $curl --% -X POST --insecure "https://alm-prdappjir01:8443/rest/jiracustomfieldeditorplugin/1/user/customfields/10300/contexts/default/options" -H "accept: application/json" -H "authorization: Basic Z19zemVldmk6U2hsMTIzNDU2" -H "Content-Type: application/json" -d "{ \"optionvalue\": \"Project5\"}
    [int] $fieldId = 10213 #10300
    $Url = "$jiraServer/rest/jiracustomfieldeditorplugin/1/user/customfields/$fieldId/contexts/default/options"
    #$headers.Add("accept","application/json")
    $body = @{"optionvalue"="$optionValue"} | ConvertTo-Json -Compress
    Invoke-WebRequest -Uri $Url -Method Post -Headers $authHeaders -ContentType $contentType -Body $body
}
function getIssue([string] $issueId){
#& $curl --insecure -H "authorization: Basic Z19zemVldmk6U2hsMTIzNDU2" $url
#curl --insecure -H "authorization: Basic Z19zemVldmk6U2hsMTIzNDU2" GET https://alm-prdappjir01:8443/rest/api/2/issue/DVO-48
    $url = "$jiraServer/rest/api/2/issue/$issueId"
    Invoke-WebRequest -Uri $url -Method Get -Headers $authHeaders
}
function searchIssue([string] $jql){
#& curl --% --insecure -H "authorization: Basic Z19zemVldmk6U2hsIUAjWlhD" GET https://alm-prdappjir01:8443/rest/api/2/issue/DVO-48
    $url = "$jiraServer/rest/api/2/search?jql=$jql"
    Write-Host "searching $url"
    Invoke-WebRequest -Uri $url -Method Get -Headers $authHeaders #-UseDefaultCredentials 
}
function createIssue([string] $pathToJson){
    write-host $pathToJson
    $url = "$jiraServer/rest/api/2/issue/"
    write-host "creating to"$url
    Invoke-WebRequest -Uri $url -Method Post -InFile $pathToJson -ContentType $contentType -Headers $authHeaders
}
function updateIssue([string] $issueId){ # , [String] $fieldName, [String] $fieldValue){
    $url = "$jiraServer/rest/api/2/issue/$issueId/"
    Write-Host $url
    #$body = @{"$fieldName"="$fieldValue"} | ConvertTo-Json -Compress
    Invoke-WebRequest -Uri $url -Method Put -ContentType $contentType -Headers $authHeaders -InFile "$scriptsPath\json-update.json" #-Body $body #-ErrorVariable errorMessage
}
function updateStatus([string] $issueId){ # , [String] $fieldName, [String] $fieldValue){
    $url = "$jiraServer/rest/api/2/issue/$issueId/transitions?expand=transitions.fields"
    Write-Host "updating "$url
    #$body = @{"$fieldName"="$fieldValue"} | ConvertTo-Json -Compress
    Invoke-WebRequest -Uri $url -Method Post -ContentType $contentType -Headers $authHeaders -InFile "$scriptsPath\statusUpdate.json" #-Body $body #-ErrorVariable errorMessage
}

####### execution #######
<#---------------------#>
<# 
$funcName = "getIssue"
$arg = "CALPROJ-66"
<# 
$funcName = "searchIssue" 
$arg = "key=CALPROJ-1"
#$arg = "Status=PLANNING&assignee=Unassigned&id=CALPROJ-5&reporter=g_szeevi&summary=This issue was created via REST with names"
#$arg = "customfield_10308=10325"
#$arg = '"מזהה%20חד%20ערכי%20של%20רשומת%20פרויקט"~10356'
#$arg = "%27מזהה%20חד%20ערכי%20של%20רשומת%20פרויקט%27~10335"
#$arg = "summary=This%20issue%20was%20created%20via%20REST%20with%20names"
#>
<# 
$funcName = "createIssue" # "addOption"
$arg = "$scriptsPath\json.json"
<#
$funcName = "updateIssue"
$arg = "CALPROJ-31"
#>
<#$arg = {
    "CALPROJ-30",
    "summary",
    "בדיקות אוטומטיות 2018-מעדכן"
    }
    #>
<# 
$funcName = "updateStatus"
$arg = "CALPROJ-75"
#>
try {
    $response = & $funcName $arg #
    #$content = $response.Content  | ConvertFrom-Json
    #write-host $content.issues.fields
    #$response.Cwrite-host ontent | Out-File "C:\Temp\1.json"
    #write-host "response is: " $response
    #write-host "response Content is: " $response.Content #
    #write-host "response Headers is: " $response.Headers
    #write-host "response Headers.Values is: " $response.Headers.Values
    #write-host "response StatusCode is: " $response.StatusCode
    return $response
} catch{
    Write-Host $_.Exception.Message
}
