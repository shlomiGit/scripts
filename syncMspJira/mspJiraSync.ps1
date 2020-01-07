[string] $scriptsPath = $PSScriptRoot
[string] $env = 'PROD'
function logThis([string] $message){
    $date = [datetime]::Now
    Out-File -FilePath "$scriptsPath\log.txt" -Append -InputObject $date": "$message
}
function failLogThis([string] $message){
    $date = [datetime]::Now
    Out-File -FilePath "$scriptsPath\failLog.txt" -Append -InputObject $date": "$message
}
function Update-Issue(){
    $jsonObj = & "$scriptsPath\converter.field.ps1" $fieldName $fieldValue
    Out-File -FilePath "$scriptsPath\json-update.json" -InputObject $jsonObj
    $updateFieldResponse = & "$scriptsPath\jiraApiFunctions.ps1" 'updateIssue' $content.issues.key $env
    logThis("Updated custom field change for Jira issue {0} with field {1}" -f $content.issues.key,$fieldName)
}
function Update-Status([string]$mspStatus, [string]$jiraKey){
    & "$scriptsPath\converter.status.ps1" $mspStatus
    $updateStatusResponse = & "$scriptsPath\jiraApiFunctions.ps1" 'updateStatus' $jiraKey $env
    if($updateStatusResponse.StatusCode -ge '200' -and $updateStatusResponse.StatusCode -le '299'){
        logThis("Updated status for Jira item: {0}" -f $jiraKey)
    }else{logThis("failed to update status for Jira item: {0}" -f $jiraKey)}
}
function Compare-Logs(){
    $failLogContent = Get-Content -Path "$scriptsPath\failLog.txt"
    foreach($line in $failLogContent){
        $failLogNewContent += $line.Substring(21)
    }    
    $secondaryFailLogContent = Get-Content -Path "$scriptsPath\secondaryFailLog.txt"
    foreach($line in $secondaryFailLogContent){
        $secondaryFailLogNewContent += $line.Substring(21)
    }
    return $failLogNewContent -eq $secondaryFailLogNewContent
}

do{
$repeat = $false
#0 ##### clear previous logs ######
#---------------------------------#
if((Test-Path -Path "$scriptsPath\failLog.txt")){Remove-Item "$scriptsPath\failLog.txt"}
if((Test-Path -Path "$scriptsPath\log.txt")){Remove-Item "$scriptsPath\log.txt"}

#1 ##### pull details from MSP db ######
#--------------------------------------#
$data = & "$scriptsPath\mspSql.ps1"

###### for each line from the msp date object ######
#--------------------------------------------------#
foreach($item in $data){
    logThis ("Working on MSP item: {0}" -f $item.id)
        <#### test 
        & "$scriptsPath\app_jiraadminests.ps1" $item
        break
        ####>

    #2 ##### extract MSP id ######
    #----------------------------#
    $mspId = $item.id

    #3 ##### search in Jira ######
    #----------------------------#
    logThis ("Searching on MSP item: {0}" -f $mspId)
    [string] $funcName = "searchIssue"
    [string] $funcArg = "%27מזהה%20חד%20ערכי%20של%20רשומת%20פרויקט%27~$mspId"
    $httpResponse = & "$scriptsPath\jiraApiFunctions.ps1" $funcName $funcArg $env

    #4 ##### analyze http response ######
    #-----------------------------------#
    #  ##### if exists ######
    #-----------------------#
    if($httpResponse.StatusCode -ge 200 -and $httpResponse.StatusCode -lt 299){
        #5 ##### interpret json ######
        #----------------------------#
        [PSCustomObject] $content = $httpResponse.Content | ConvertFrom-Json
        [int] $totalItemsFound = $content.total
        if($totalItemsFound -eq 1){
            logThis("Found MSP item: {0} in Jira" -f $item.id)
    
            #6 ##### compare all values ######
            #--------------------------------#
            #[bool] $isMatch = & "$scriptsPath\compareValues.ps1" $content.issues.fields $item
            [string] $comparisonResult = & "$scriptsPath\compareValues - $env.ps1" $content.issues.fields $item
        
            #6a #### if match ######
            #----------------------#
            #if($isMatch){
            if($comparisonResult -eq "TRUE+TRUE"){
                logThis("MSP item {0} is synced in Jira" -f $item.id)
                continue
            }
            #6b #### if mismatch ######
            #-------------------------#
            elseif($comparisonResult.Contains('status')){
                Update-Status $item.Status $content.issues.key
            }
            elseif($comparisonResult.Contains('.') -and !($comparisonResult.StartsWith('~'))){
                [string] $fieldName = ((($comparisonResult.Split('+'))[0]).Split('.'))[0]
                [string] $fieldValue = ($comparisonResult.Split('+'))[1]
                [string] $attributeName = ((($comparisonResult.Split('+'))[0]).Split('.'))[1]
                $jsonObj
                if($comparisonResult.Contains('.child.value')){
                    $attributeName = $attributeName + "." + ((($comparisonResult.Split('+'))[0]).Split('.'))[2]
                    $jsonObj = & "$scriptsPath\converter.field.ps1" $fieldName $fieldValue $attributeName $item.departmentOfProjectManager
                }else{
                    $jsonObj = & "$scriptsPath\converter.field.ps1" $fieldName $fieldValue $attributeName
                }
                Out-File -FilePath "$scriptsPath\json-update.json" -InputObject $jsonObj
                $updateFieldResponse = & "$scriptsPath\jiraApiFunctions.ps1" 'updateIssue' $content.issues.key $env
                logThis("Updated custom field change for Jira issue {0} with field {1}" -f $content.issues.key,$fieldName)
                failLogThis("Updated custom field change for Jira issue {0} with field {1}. Please run again and confirm the update is cleared" -f $content.issues.key,$fieldName)
            }
            else{
                if($comparisonResult.StartsWith('~')){
                    $comparisonResult = $comparisonResult.Replace('~','')
                }
                [string] $fieldName = ($comparisonResult.Split('+'))[0]
                [string] $fieldValue = ($comparisonResult.Split('+'))[1]
                $jsonObj = & "$scriptsPath\converter.field.ps1" $fieldName $fieldValue
                Out-File -FilePath "$scriptsPath\json-update.json" -InputObject $jsonObj
                $updateFieldResponse = & "$scriptsPath\jiraApiFunctions.ps1" 'updateIssue' $content.issues.key $env
                logThis("Updated custom field change for Jira issue {0} with field {1}" -f $content.issues.key,$fieldName)
                failLogThis("Updated custom field change for Jira issue {0} with field {1}. Please run again and confirm the update is cleared" -f $content.issues.key,$fieldName)
            }
        }
        elseif($totalItemsFound -gt 1){
            logThis("Found MSP item {0} more than once in Jira" -f $item.id)
            failLogThis("Found MSP item {0} more than once in Jira" -f $item.id)
        }
        #7 ##### if not exists ######
        #---------------------------#    
        #elseif($httpResponse.Contains('(400) Bad Request')){
        #elseif($httpResponse -eq $null){
        elseif($totalItemsFound -eq 0 -and [datetime]($item.StartDate.Split('/')[1]+'/'+$item.StartDate.Split('/')[0]+'/'+$item.StartDate.Split('/')[2]) -ge [datetime]'01/01/2019'){
            logThis("MSP item {0} is not in Jira" -f $item.id)

            #8 ##### create json from msp object ######
            #-----------------------------------------#
            $jsonObj = & "$scriptsPath\converter.mspToJira - $env.ps1" $item
            Out-File -FilePath "$scriptsPath\json.json" -InputObject $jsonObj
        
            #9 ##### HTTP Request to jira rest api ######
            #-------------------------------------------#
            $createHttpResponse = & "$scriptsPath\jiraApiFunctions.ps1" "createIssue" "$scriptsPath\json.json" $env

            #10 ##### confirm 201 ######
            #--------------------------#
            if($createHttpResponse.StatusCode -ge '200' -and $createHttpResponse.StatusCode -le '299'){
                logThis("MSP item with id: {0} was created in Jira" -f $mspId)
                
                #11 ##### check if status not equal תכנון ######
                #---------------------------------------------#
                if($item.Status -ne "תכנון"){
                    #12 ##### update status ######
                    #----------------------------#
                    [string] $jiraKey = ($createHttpResponse.Content | ConvertFrom-Json).key
                    Update-Status $item.Status $jiraKey
                }
            }
            else{
                logThis("error creating Jira for msp item with id: {0}" -f $mspId)
                failLogThis("error creating Jira for msp item with id: {0}. Please check all values are valid before turning to your Admin" -f $mspId)
            }
        }
        else{
            logThis("Dropping MSP item {0}" -f $item.id)
        }
    }
}
#13 ##### monitor multiple runs ######
#------------------------------------#
#14 ##### check faillog is not empty ######
#-----------------------------------------#
if((Test-Path -Path "$scriptsPath\failLog.txt") -and (Get-Content -Path "$scriptsPath\failLog.txt") -ne ""){
    #16 ##### if not exists then create and rerun ######
    #--------------------------------------------------#
    if(!(Test-Path -Path "$scriptsPath\secondaryFailLog.txt")){
        # create
        Copy-Item -Path "$scriptsPath\failLog.txt" -Destination "$scriptsPath\secondaryFailLog.txt"
        # rerun
        #& "$scriptsPath\runAs.ps1"
        $repeat = $true
    }
    #17 ##### if exists then compare current to secondry ######
    #---------------------------------------------------------#
    else{
        #18 ##### if match then notify user ######
        #----------------------------------------#
        if(Compare-Logs){
            #notify user
            failLogThis("the errors above cannot be cleared. Please notify the admin")
        }
        #19 ##### if mismatch then rerun ######
        #----------------------------------------#
        else{
            Remove-Item "$scriptsPath\secondaryFailLog.txt"
            $repeat = $true
        }
    }
}
}
while($repeat)

#0 ##### clear previous logs
#1 ##### pull from MSP DB ------------------------------ DONE
#2 ##### get the msp object ID ------------------------------ DONE
#3 ##### search for it in all the Jira MSP objects ------------------------------ DONE
#4 ##### analyze http response ------------------------------ DONE
#  ##### if exists - validate: ------------------------------ DONE
    #5 ##### interpret json response ------------------------------ DONE
    #6 ##### compare all values ------------------------------ DONE
    #6a #### if match: continue ------------------------------ DONE
    #6b #### if mismatch: rewrite ------------------------------ DONE
#7 ##### if not exists - create: ------------------------------ DONE
    #8 ##### create json from msp object ------------------------------ DONE
    #9 ##### invoke HTTP Request to jira rest api ------------------------------ DONE    
    #10 ##### decide on failure ------------------------------ DONE
    #11 ##### check if status ne תכנון ------------------------------ DONE
        #12 ##### update status ------------------------------ DONE
#13 ##### monitor multiple runs
    #14 ##### check faillog is not empty:
        #15 ##### check secondary faillog exists
            #16 ##### if not exists then create and rerun
            #17 ##### if exists then compare current to secondry
                #18 if match then notify user
                #19 if mismatch then rerun
#15 ###### create general scheduler for this task

# trans: http://alm-tstappjir01:8080/rest/api/2/issue/CALPROJ-33/transitions?expand=transitions.fields
