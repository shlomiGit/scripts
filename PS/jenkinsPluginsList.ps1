### functions
function Add-Plugin([int] $i){
    Create-Plugin $pluginsListXML.FirstChild.shortName[$i] $pluginsListXML.FirstChild.version[$i]
}

function Create-Plugin([string] $Name, [string] $Version){
    $newPlugin = new-object PSObject
    $newPlugin | add-member -type NoteProperty -Name 'Name' -Value $Name
    $newPlugin | add-member -type NoteProperty -Name 'Version' -Value $Version
    return $newPlugin
}

### Jenkins API
[uri] $jenkinsPluginsAPI = "http://{jenkinsServer}/pluginManager/api/xml?depth=1&xpath=/*/*/shortName|/*/*/version&wrapper=plugins"

### Get plugins xml from Jenkins
[System.Xml.XmlDocument] $pluginsListXML = & Invoke-RestMethod -Uri $jenkinsPluginsAPI -UseDefaultCredentials

### Parse and put in list
$pluginsList = New-Object System.Collections.ArrayList
[int] $listCount = $pluginsListXML.FirstChild.version.Count

for ($i=0; $i -le $listCount; $i++) {
    $pluginsList += Add-Plugin $i
    }

### Print list
ForEach($listitem in $pluginsList){
    Write-Host $listitem
}
