param(
    [string] $fieldName,
    $fieldValue,
    [string] $attributeName,
    [string] $parentValue
)
[double] $containerVar = $null
if([double]::TryParse($fieldValue,[ref]$containerVar)){
    Write-Host 'containerVar:'$containerVar
}else{
    [string]$containerVar = $fieldValue
}
$properties
if($parentValue){
    $properties = @{
        fields = @{
            $fieldName = @{
                value = $parentValue
                $attributeName.Split('.')[0] = @{
                    $attributeName.Split('.')[1] = $containerVar
                }
            }
        }
    }
}elseif($attributeName -and $attributeName.Contains('.')){
    $properties = @{
        fields = @{
            $fieldName = @{
               $attributeName.Split('.')[0] = @{
                $attributeName.Split('.')[1] = $containerVar
                }
            }
        }
    }
}elseif($attributeName){
    $properties = @{
        fields = @{
            $fieldName = @{
               $attributeName = $containerVar
            }
        }
    }
}else{
    $properties = @{
        fields = @{
            $fieldName = $containerVar
        }
    }
}

#### remove null value lines
[string[]] $nullKeys = ""
foreach ($key in $properties.fields.Keys) {
    if($properties.fields[$key].GetType().Name -eq "DBNull"){
        $nullKeys += $key
    }
}
foreach($nullKey in $nullKeys){
    $properties.fields.Remove($nullKey)
}

#### convert to json and return
$hashObj = New-Object psobject -Property $properties
$jsonObj = $hashObj | ConvertTo-Json -Depth 4
#return $properties
return $jsonObj #> "M:\repos\MSP\calproj4.json"
