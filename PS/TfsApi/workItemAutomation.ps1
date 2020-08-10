<#
0. vars
1. functions
2. get request content
3. confirm events
4. prepareCreds
5. set server items
6. set Parent Id
7. set Parent wi
8. create update objects list
9. confirm parent state update
    9.1 create StateUpdate Obj
    9.2 add obj to list
10. set Original Estimate delta
    10.1 create origEstUpdate Obj
    10.2 add obj to list
11. create historyUpdate Obj
    11.1 add obj to list
7. invoke web request
#>

#Clear-Variable * -Scope Global

<### 0
<### vars ###>
<#------------#>
#region vars
param(
    [string] $content,
    [string] $auth
)

### log vars
[string] $logsFolder = "$PSScriptRoot\..\logs"

### update validators
[bool] $shouldUpdateState
[bool] $shouldUpdateOrigEst

### cred vars
[pscredential] $creds

### parent vars
[string] $parentWi

### server vars
[string] $serverInstance
[string] $collection
[string] $projectName

### web request vars
$contentType = 'application/json-patch+json'
[string] $wiId
[string] $wiUpdateUri

#endregion

<### 1
<### functions ###>
<#---------------#>
#region functions

function logThis([string] $message){
    $date = [datetime]::Now
    if(!(Test-Path -Path $logsFolder)){mkdir $logsFolder}
    Out-File -FilePath $logsFolder\log.txt -Append -InputObject $date": "$message
}

function shouldUpdate(){
    if($validatorsArray -contains $true){
        return $true
    }
    else{
        return $false
    }
}

function setServerItems(){
    logThis("getting server items...")   
    $global:serverInstance = $requestJson.resourceContainers.server.baseUrl.TrimEnd('/')
    $global:collection = ($requestJson.resourceContainers.collection.baseUrl).Split('/')[4]
    $global:projectName = $requestJson.resource.revision.fields.'SystemTeamProject'
    logThis("received server items: $global:serverInstance, $global:collection, $global:projectName")
}

function prepareCreds(){
    logThis("working on creds...")
    
    <### 4.2.1
    <### get creds ###>
    <#---------------#>
    [string] $encPwd = $auth.Split(' ')[1] # (Get-Content -Path $PSScriptRoot\..\workFiles\$id\auth.txt).Split(' ')[1]

    <### 4.2.2
    <### interpret creds ###>
    <#---------------------#>
    [byte[]] $encPwdBytes = [System.Convert]::FromBase64String($encPwd)
    [string] $credsStr = [System.Text.Encoding]::UTF8.GetString($encPwdBytes)

    <### 4.2.3
    <### set creds ###>
    <#---------------#>
    [string] $userName = $credsStr.Split(':')[0]
    [string] $plainPwd = $credsStr.Split(':')[1]
    #[securestring] $pwd = ConvertTo-SecureString -Key (1..16) (Get-Content "$PSScriptRoot\encPwd.txt")
    [securestring] $pwd = ConvertTo-SecureString -String $plainPwd -AsPlainText -Force #-Key (1..16)
    $global:creds = New-Object pscredential($userName, $pwd)
    #return New-Object -TypeName pscredential -ArgumentList $userName, $pwd
    #$creds.UserName = $userName
    #$creds.Password = $pwd
    #logThis("completed creds preparation")
}

function uriBuilder(){
    $global:wiUpdateUri = "$global:serverInstance/$global:collection/$global:projectName/_apis/wit/workitems/$global:wiId"+'?api-version=4.1'
    return $global:wiUpdateUri
}

function setParentId(){
    logThis("getting parent Id...")
    [PSCustomObject] $parent = $requestJson.resource.revision.relations | Where-Object({$_.rel -contains 'System.LinkTypes.Hierarchy-Reverse'})
    if($parent -eq $null){
        logThis("no parent. exiting...")
        exit
    }
    [int] $lastSlashIndex = $parent.url.LastIndexOf('/')
    [string] $parentId = $parent.url.Substring($lastSlashIndex+1,$parent.url.Length-$lastSlashIndex-1)
    logThis("parentId is: $parentId")
    $global:wiId = $parentId
}

function setParentWi(){   
    logThis("getting parent from " + (uriBuilder))
    try{
        $global:parentWi = Invoke-RestMethod -Uri (uriBuilder) -Credential $global:creds -Method Get
        logThis("received parent wi")
    }catch{
        Out-File -FilePath "$logsFolder\jsonError.json" -InputObject $_.Exception.Response
        Out-File -FilePath "$logsFolder\jsonError.json" -Append -InputObject $_.ErrorDetails.Message
        logThis("invoke failed")
        exit
    }
}

function createUpdateObj([string] $fieldName, [string] $fieldValue){
    $UpdateObj = New-Object -TypeName PSObject
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name op -Value 'add'
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name Path -Value $fieldName
    Add-Member -InputObject $UpdateObj -MemberType NoteProperty -Name value -Value $fieldValue
    return $UpdateObj
}
#endregion

<### 2
<### get request content ###>
<#-------------------------#>
logThis("*** received request following workitem update. reading request... ***")
[PSCustomObject] $requestJson = $content.Replace('~~~~','"') | ConvertFrom-Json # Get-Content -Path $PSScriptRoot\..\workFiles\$id\request.json | ConvertFrom-Json

<### 3
<### confirm events ###>
<#--------------------#>
[bool[]] $validatorsArray = New-Object System.Collections.ArrayList
logThis("confirming events...")
if($requestJson.resource.fields.SystemState.oldValue -eq 'Active' -and $requestJson.resource.fields.SystemState.newValue -eq 'In Progress'){
    $shouldUpdateState = $true
    $validatorsArray += $shouldUpdateState
    logThis("update for State may be required")
}

if($requestJson.resource.fields.'Microsoft.VSTS.Scheduling.OriginalEstimate' -ne $null){
    $shouldUpdateOrigEst = $true
    $validatorsArray += $shouldUpdateOrigEst
    logThis("update for OriginalEstimate may be required")
}
if(!(shouldUpdate)){
    logThis("no event for update. exiting...")
    exit
}

<### 4
<### prepare Creds ###>
<#-------------------#>
prepareCreds

<### 5
<### set server items ###>
<#----------------------#>
setServerItems

<### 6
<### set parent Id ###>
<#-------------------#>
setParentId

<### 7
<### set parent wi ###>
<#-------------------#>
setParentWi

<### 8
<### create update objects list ###>
<#--------------------------------#>
[PSObject[]] $updateObjectsList = New-Object System.Collections.ArrayList

<### 9
<### confirm parent state update ###>
<#---------------------------------#>
if($shouldUpdateState -and $parentWi.resource.revision.fields.'System.State' -ne 'In Progress'){
    <### 9.1
    <### add obj to list ###>
    <#---------------------#>
    $updateObjectsList += createUpdateObj "/fields/System.State" "In Progress"
}
else{
    $shouldUpdateState = $false
}

<### 10
<### set Original Estimate delta ###>
<#---------------------------------#>
if($shouldUpdateOrigEst){ #-and  $parentWi.resource.revision.fields.'Microsoft.VSTS.Scheduling.OriginalEstimate' -ne $null){
    [double] $origEstDelta = $requestJson.resource.fields.'Microsoft.VSTS.Scheduling.OriginalEstimate'.newValue - $requestJson.resource.fields.'Microsoft.VSTS.Scheduling.OriginalEstimate'.oldValue
   
    <### 10.1
    <### add obj to list ###>
    <#---------------------#>
    $updateObjectsList += createUpdateObj "/fields/Microsoft.VSTS.Scheduling.OriginalEstimate" ($parentWi.fields.'Microsoft.VSTS.Scheduling.OriginalEstimate' + $origEstDelta)
}

<### 11
<### add historyUpdate to list ###>
<#-------------------------------#>
$updateObjectsList += createUpdateObj "/fields/System.History" 'auto update by WorkItemAutomation webhook'

<### 12
<### prepare body ###>
<#------------------#>
[string] $bodyJson = ConvertTo-Json $updateObjectsList

<### 13
<### invoke web request ###>
<#------------------------#>
logThis("requesting $wiUpdateUri")
try{
    $jsonResponse = Invoke-RestMethod -Uri $wiUpdateUri -Credential $global:creds -Method Patch -ContentType $contentType -Body $bodyJson #-OutFile "$logsFolder\jsonPassThru.txt" -PassThru # -InFile "...update.json"
    #Out-File -FilePath "$logsFolder\jsonResponse.json" -InputObject $jsonResponse
    logThis("updated wi: $global:wiId")
}catch{
    Out-File -FilePath "$logsFolder\jsonError.json" -InputObject $_.Exception.Response
    Out-File -FilePath "$logsFolder\jsonError.json" -Append -InputObject $_.ErrorDetails.Message
    logThis("invoke failed")
}
