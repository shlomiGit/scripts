param(
    $jiraFields,
    $mspItem
)
function Status-Compare([string] $couple){
    [string[]] $couplesArray = "תכנון-PLANNING","בעבודה-In Progress","בבדיקה-IN TEST","הסתיים-DONE"
    return ($couplesArray -contains $couple)
}
function Date-Compare([string] $jiraDate, [string] $mspDate){
    [string[]] $jiraDateArray = $jiraDate.Split('-')
    [string[]] $mspDateArray = $mspDate.Split('/')

    if($jiraDateArray[0] -eq $mspDateArray[2] -and $jiraDateArray[1] -eq $mspDateArray[1] -and $jiraDateArray[2] -eq $mspDateArray[0]){
        return $true
    }
    else{
        return $false
    }
}
function Return-Name(){
    if((Get-Content -Path "$PSScriptRoot\deadUsers.txt") -match $mspItem.LoginNameProjectManager){
        return ""
    }else{
        return $mspItem.LoginNameProjectManager
    }
}
function Error-Output([string]$jiraValue,[string]$mspValue){
    Write-Host ("jira value is: {0} and msp value is: {1}" -f $jiraValue,$mspValue)
}
function Return-Comaprison([string]$jiraFieldName,[string]$mspValue){
    return ("{0}+{1}" -f $jiraFieldName,$mspValue)
}

### info ###
#----------#
##[string[]] $mspFields = {'Name','PotentialType','StartDate'},
##[string[]] $jiraFields = {'summary','PotentialType','StartDate'},

if($jiraFields.summary -ne $mspItem.Name){
    Error-Output $jiraFields.summary $mspItem.Name
    Return-Comaprison 'summary' $mspItem.Name
}elseif((($mspItem.description.ToString()).Length -gt 0 -or $jiraFields.description -ne $null -or ($jiraFields.issuetype.description.ToString()).Length -gt 0) -and $jiraFields.issuetype.description -ne $mspItem.description -and $jiraFields.description -ne $mspItem.description){
    Error-Output $jiraFields.issuetype.description $mspItem.description
    Return-Comaprison 'description' $mspItem.description
}elseif((($mspItem.Portfolio.ToString()).Length -gt 0 -or $jiraFields.customfield_10312.value -ne $null) -and $jiraFields.customfield_10312.value -ne $mspItem.Portfolio){
    Error-Output $jiraFields.customfield_10312.value $mspItem.Portfolio
    Return-Comaprison 'customfield_10312.value' $mspItem.Portfolio
}elseif($jiraFields.customfield_10318.value -ne $mspItem.PotentialType){
    Error-Output $jiraFields.customfield_10318.value $mspItem.PotentialType
    Return-Comaprison 'customfield_10318.value' $mspItem.PotentialType
}elseif(!(Date-Compare $jiraFields.customfield_10321 $mspItem.StartDate)){
    Error-Output $jiraFields.customfield_10321 ($mspItem.StartDate -replace '/','-')
    Return-Comaprison 'customfield_10321' ($mspItem.StartDate.Split('/')[2]+'-'+$mspItem.StartDate.Split('/')[1]+'-'+$mspItem.StartDate.Split('/')[0])
}elseif(!(Date-Compare $jiraFields.duedate $mspItem.FinishDate)){
    Error-Output $jiraFields.duedate ($mspItem.FinishDate -replace '/','-')
    Return-Comaprison 'duedate' ($mspItem.FinishDate.Split('/')[2]+'-'+$mspItem.FinishDate.Split('/')[1]+'-'+$mspItem.FinishDate.Split('/')[0])
}elseif($jiraFields.customfield_10319.value -ne $mspItem.Basket -and $jiraFields.customfield_10319 -ne $null -and $mspItem.Basket -ne $null){
    Error-Output $jiraFields.customifeld_10319.value $mspItem.Basket
    Return-Comaprison 'customifeld_10319.value' $mspItem.Basket
}elseif(!(Status-Compare ("{0}-{1}" -f $mspItem.Status,$jiraFields.status.name))){ #($jiraFields.status.name -ne $mspItem.Status){
    Error-Output $jiraFields.status.name $mspItem.Status
    Return-Comaprison 'status.name' $mspItem.Status
}elseif($jiraFields.customfield_10311 -ne [math]::Round($mspItem.ApprovedWork,3)){
    Error-Output $jiraFields.customfield_10311 $mspItem.ApprovedWork
    Return-Comaprison '~customfield_10311' $mspItem.ApprovedWork
}elseif($jiraFields.customfield_10315 -ne [math]::Round($mspItem.ActualWork,3)){
    Error-Output $jiraFields.customfield_10315 $mspItem.ActualWork
    Return-Comaprison '~customfield_10315' $mspItem.ActualWork
}elseif(!((Get-Content -Path "$PSScriptRoot\deadUsers.txt") -match $mspItem.LoginNameProjectManager) -and $jiraFields.assignee.name -ne $mspItem.LoginNameProjectManager){
    Error-Output $jiraFields.assignee.name $mspItem.LoginNameProjectManager
    Return-Comaprison 'assignee.name' (Return-Name)
}elseif($jiraFields.customfield_10314.value -ne $mspItem.departmentOfProjectManager){
    Error-Output $jiraFields.customfield_10314.value $mspItem.departmentOfProjectManager
    Return-Comaprison 'customfield_10314.value' $mspItem.departmentOfProjectManager
}elseif(($jiraFields.customfield_10314.child -ne $null -or ($mspItem.sectionOfProjectManager.ToString()).Length -gt 0) -and $jiraFields.customfield_10314.child.value -ne $mspItem.sectionOfProjectManager){
    Error-Output $jiraFields.customfield_10314.child.value $mspItem.sectionOfProjectManager
    Return-Comaprison 'customfield_10314.child.value' $mspItem.sectionOfProjectManager
}else {Return-Comaprison "TRUE" "TRUE"}
