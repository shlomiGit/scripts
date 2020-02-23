####### Params #######
<#------------------#>
param(
    ####### logs
    $logPath = "$PSScriptRoot\logs\log.txt",

    ####### sln details
    [string] $pathToSln = 'C:\Users\shlomiz\source\repos\Spitfire\Branches\NugetDev',
    [string] $slnName = 'Client.sln',
    [string] $tfPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe',

    ####### nuget details
    [string[]] $sources = @('ExternalPackages','MarketPackages'),
    $packageProvider = 'NuGet',
    $nugetPath = "C:\Users\shlomiz\source\ConvertingToDependencyManaged\apps\nuget.exe",
    $tempRefName = 'LandaFramework.Logger'
)
[string[]] $nugetRefs = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'
 $nugetRefs += foreach ($source in $sources){ & $nugetPath list -source $source}

####### 0. functions #######
<#------------------------#>
function logThis([string] $message){
    $date = [datetime]::Now
    Out-File -FilePath $logPath -Append -InputObject $date": "$message
}

####### 1. get projects list #######
<#--------------------------------#>
Remove-Item -Path $logPath
logThis("scanning $slnName for projects")
[PSObject[]] $projectsList = & $PSScriptRoot\1-getSlnProjects.ps1 $pathToSln $slnName
logThis("found " + $projectsList.Count + " projects")

####### 2. loop projects #######
<#----------------------------#>
foreach($project in $projectsList){
    logThis('      *** project: ' + $project.Name + ' ***' )
    logThis("scanning " + $project.Name + " for refs")
    ####### 2a. get project refs #######
    <#--------------------------------#>
    [System.Collections.ArrayList] $refsList = $project.Refs | Select-Object -Unique

    ####### 2b. remove system refs #######
    <#----------------------------------#>
    [string[]] $systemRefs = $refsList | Where-Object {$_.StartsWith('System') -or $_.StartsWith('Microsoft') -or $_.ToLower().Contains('mstsc') -or $_.Contains('PresentationCore') -or $_.Contains('PresentationFramework') -or $_.StartsWith('Windows')}
    foreach($systemRef in $systemRefs){
        $refsList.Remove($systemRef)
    }
    logThis("found " + $refsList.Count + " refs")
        
    ####### 2c. tf checkout csproj #######
    <#----------------------------------#>
    $csprojPath = $pathToSln +'\' + $project.Path + '\' + $project.Name
    & $tfPath checkout $csprojPath

    ####### 2d. read xml #######
    <#------------------------#>    
    [xml] $csprojFile = Get-Content $csprojPath
        
    ####### 2e. check csproj is in old format #######
    <#---------------------------------------------#>
    logThis('checking ' + $project.Name + ' is in old format...')
    [System.Xml.XmlNodeList] $packageReferenceNodes = $csprojFile.Project.GetElementsByTagName('PackageReference')
    
    ####### 2f. csproj is in old format #######
    <#---------------------------------------#>
    if($packageReferenceNodes.Count -eq 0){
        ####### 2f1. add ItemGroup #######
        <#------------------------------#>
        logThis('Converting ' + $project.Name + ' to new nuget format')
        $newItemGroup = $csprojFile.CreateElement('ItemGroup',$csprojFile.Project.NamespaceURI)
        $csprojFile.Project.AppendChild($newItemGroup)
        logThis('Converted ' + $project.Name + ' to new nuget format')
    }

    ####### 2g. loop refs #######
    <#-------------------------#>
    foreach($ref in $refsList){
        logThis("      *** ref: $ref ***")
        ####### 2g1. find ref in feed by name #######
        <#-----------------------------------------#>
        logThis("   searching for " + $ref + " in nuget feed")
        [bool] $isRefListedInSource = ($nugetRefs -like ("$ref*")).Count -gt 0
        ####### 2g2. Ref Is Listed In Source #######
        <#----------------------------------------#>
        if($isRefListedInSource){
            logThis("   found $ref in nuget feed")

            ####### 2g2a. get current xml node by ref name #######
            <#--------------------------------------------------#>
            [System.Xml.XmlLinkedNode[]] $oldNode = $csprojFile.Project.GetElementsByTagName('Reference') | Where-Object ({$_.Include -like "*$ref*"})
                        
            ####### 2g2b. recover dll version #######
            <#-------------------------------------#>
            if($null -eq $csprojPath + '\..\' + $oldNode.HintPath){
                logThis("HERE ERROR OF EMPTY DLL PATH: $csprojPath + '\..\' + $oldNode")
            }
            else{
                [string] $dllPath = $csprojPath + '\..\' + $oldNode.HintPath[0]            
                $dllVersion = (Get-Item $dllPath).VersionInfo.ProductVersion
                if($dllVersion -notlike '[0-9].[0-9].[0-9]'){
                    $dllVersion = (Get-Item $dllPath).VersionInfo.FileVersion
                    if($dllVersion -like '[0-9].[0-9].[0-9].0'){
                        $dllVersion = $dllVersion.Substring(0,$dllVersion.Length-2)
                    }
                }
            }

            ####### 2g2c. remove current xml node #######
            <#-----------------------------------------#>
            logThis("   removing $ref from csproj")
            foreach($node in $oldNode){
                $node.ParentNode.RemoveChild($node)
            }
            logThis("   removed $ref from csproj")

            ####### 2g2d. add new xml entriy to csproj #######
            <#----------------------------------------------#>
            logThis('   adding new ref node for ' + $ref)
            
            ####### create child element
            [System.Xml.XmlNodeList] $itemGroups = $csprojFile.Project.GetElementsByTagName('ItemGroup')
            [System.Xml.XmlLinkedNode] $itemGroup = $itemGroups.Item($itemGroups.Count - 1)
            $node = $csprojFile.CreateElement('PackageReference',$csprojFile.Project.NamespaceURI)
            
            ####### Set Attributes
            $node.SetAttribute('Include',$ref)
            $node.SetAttribute('Version',$dllVersion)

            ####### add child
            $itemGroup.AppendChild($node)
            logThis('   added new ref node for ' + $ref)
        }
        ####### 2g3. Ref Is Not Listed In Source #######
        <#--------------------------------------------#>
        else {
            logThis("   ERROR: can't find $ref in nuget sources")
        }
    }

    ####### 2h. save csproj file #######
    <#--------------------------------#>
    logThis("saving csproj file for " + $project.Name)
    $csprojFile.Save($csprojPath)
    logThis("saved csproj file for " + $project.Name)
}

####### 3. nuget restore #######
<#-----------------------------#>
logThis('restoring nuget packages so that pending changes will apear in VS2017')
& $nugetPath restore ($pathToSln +'\' + $slnName)
logThis("restored nuget packages for $slnName")

logThis("$slnName is now dependency-managed")

# 0. functions
# 1. get proj list for a given sln
# 2. loop projects
    # 2a. get project refs
    # 2b. remove system refs
    # 2c. tf checkout csproj
    # 2d. read xml
    # 2e. check csproj is in old format
    # 2f. csproj is in old format
        # 2e1. add ItemGroup
    # 2g. loop refs
        # 2g1. find ref in feed by name
        # 2g2. Ref Is Listed In Source
            # 2g2a. get current xml node by ref name
            # 2g2b. recover dll version
            # 2g2c. remove current xml node
            # 2g2d. add new xml entriy to csproj
        # 2g3. Ref Is Not Listed In Source    
    # 2h. save csproj file
# 3. nuget restore
# 4. logging
