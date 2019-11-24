<#### params ####>
<#--------------#>
param(
    [string] $mspStatus
)
#[string[]] $mspStatusArray = {"בתכנון","בעבודה","בבדיקה","הסתיים"}
#[string[]] $jiraTransArray = {"בתכנון","בעבודה","בבדיקה","הסתיים"}
[string] $jsonPath = "C:\Temp\utilities\msp-to-jira-sync\statusUpdate.json"

<#### funcs ####>
<#-------------#>
function Get-TransitionIdFromMspStatus([string] $mspStatus=$mspStatus){
    switch($mspStatus){
        #"תכנון" {return "PLANNING"}
        "בעבודה" {return 11}
        #"בבדיקה" {return "IN TEST"}
        "הסתיים" {return 21}
        "בוטל" {return 71}
    }
}
function SaveTo-Json([string] $transitionId){
    $properties = @{
        transition = @{
            id = $transitionId
        }
    }
    $hashObj = New-Object psobject -Property $properties
    $hashObj | ConvertTo-Json | Out-File -FilePath $jsonPath #-InputObject $hashObj
}

<#### script ####>
<#--------------#>
SaveTo-Json (Get-TransitionIdFromMspStatus)
