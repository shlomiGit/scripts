param(
    [System.Data.DataRow] $mspItem
)

<### fixed params ###>
$projKey = 'CALPROJ'
$issuetype = 'CAL Project'

function Convert-Date([string] $mspDate){
    $mspDateArray = $mspDate.Split('/')
    $jiraDate = $mspDateArray[2]+"-"+$mspDateArray[1]+"-"+$mspDateArray[0]+"T13:00:00.000+0300"
    return $jiraDate
}
function Get-Name(){
    if((Get-Content -Path "$PSScriptRoot\deadUsers.txt") -match $mspItem.LoginNameProjectManager){
        return ""
    }else{
        return $mspItem.LoginNameProjectManager
    }
}

if($mspItem.description.GetType().Name -eq 'DBNull'){
    $properties = @{
        fields = @{
            project = @{
                key = $projKey
            }
	        customfield_10304 = ($mspItem.id).ToString()
            summary = $mspItem.Name
            issuetype = @{
                name = $issuetype
            }
            customfield_10312 = @{
                value = $mspItem.Portfolio
            }
            customfield_10318 = @{
                value = $mspItem.PotentialType 
            }
            customfield_10321 = Convert-Date($mspItem.StartDate)
            duedate = Convert-Date($mspItem.FinishDate)
            customfield_10319 = @{
                value = $mspItem.Basket
            }
            customfield_10311 = [math]::Round($mspItem.ApprovedWork,3)
            customfield_10315 = [math]::Round($mspItem.ActualWork,3)
            assignee = @{
                name = Get-Name
            }
            customfield_10314 = @{
                value = $mspItem.departmentOfProjectManager
                child = @{
                    value = $mspItem.sectionOfProjectManager
                }
            }
        }
    }
}else{
    $properties = @{
        fields = @{
            project = @{
                key = $projKey
            }
	        customfield_10304 = ($mspItem.id).ToString()
            summary = $mspItem.Name
            issuetype = @{
                name = $issuetype
            }
            description = $mspItem.description
            customfield_10312 = @{
                value = $mspItem.Portfolio
            }
            customfield_10318 = @{
                value = $mspItem.PotentialType 
            }
            customfield_10321 = Convert-Date($mspItem.StartDate)
            duedate = Convert-Date($mspItem.FinishDate)
            customfield_10319 = @{
                value = $mspItem.Basket
            }
            customfield_10311 = [math]::Round($mspItem.ApprovedWork,2)
            customfield_10315 = [math]::Round($mspItem.ActualWork,2)
            assignee = @{
                name = $mspItem.LoginNameProjectManager
            }
            customfield_10314 = @{
                value = $mspItem.departmentOfProjectManager
                child = @{
                    value = $mspItem.sectionOfProjectManager
                }
            }
        }
    }
}

#### remove null value lines
[string[]] $nullKeys = ""
foreach ($key in $properties.fields.Keys) {
    if($properties.fields[$key].GetType().Name -eq "DBNull"){
        $nullKeys += $key
    }<#elseif($properties.fields[$key].GetType().Name -eq "Hashtable"){
        foreach($hashValue in $properties.fields[$key].Values){
            if($hashValue.GetType().Name -eq "DBNull"){
                $nullKeys += $key
            }
        }
    }#>
}
if($mspItem.Basket.GetType().Name -eq 'DBNull'){
    $nullKeys += "customfield_10319"
}
foreach($nullKey in $nullKeys){
    $properties.fields.Remove($nullKey)
}

#### convert to json and return
$hashObj = New-Object psobject -Property $properties
$jsonObj = $hashObj | ConvertTo-Json -Depth 4
#return $properties
return $jsonObj #> "M:\repos\MSP\calproj4.json"
