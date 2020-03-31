####### Params #######
<#------------------#>
param(
    ####### logs
    $logPath = "$PSScriptRoot\logs\log.txt",

    ####### sln details
    [string] $pathToSln, #example = 'C:\Users\shlomiz\source\repos\Branches\NugetDev',
    [string[]] $slnNames, #example = @('PCCQCS.sln','IntegrationTests.sln','ApplicationInsightsDispatcher.sln','SMFMonitor.sln','CommonInfrastructure.sln','Server.sln','OCController.sln','DPControllerCommon.sln','DPController.sln','QTController.sln','Client.sln','PressDataCollector.sln','DFEMock.sln','MigrationWizard.sln'),
    [string] $tfPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe',

    ####### nuget details
    [string[]] $sources = @('ExternalPackages','MarketPackages','DeletedPackages'),
    $packageProvider = 'NuGet',
    $nugetPath = "C:\Users\shlomiz\source\ConvertingToDependencyManaged\apps\nuget.exe"
)
[string[]] $nugetRefs = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'
$nugetRefs += foreach ($source in $sources){ & $nugetPath list -source $source}

####### 0. functions #######
<#------------------------#>
function logThis([string] $message){
    #$date = [datetime]::Now
    #Out-File -FilePath $logPath -Append -InputObject $date": "$message
}
Remove-Item -Path $logPath

####### 1. get projects list #######
<#--------------------------------#>
foreach($slnName in $slnNames){

logThis("scanning $slnName for projects")
[PSObject[]] $projectsList = & $PSScriptRoot\1-getSlnProjects.ps1 $pathToSln $slnName
logThis("found " + $projectsList.Count + " projects")

####### 2. loop projects #######
<#----------------------------#>
foreach($project in $projectsList){
#if($project.Name -eq 'Spitfire.CommonServices.DBF.PDLS.Interfaces.csproj'){
    logThis('      *** project: ' + $project.Name + ' ***' )
    logThis("scanning " + $project.Name + " for refs")
    ####### 2a. get project refs #######
    <#--------------------------------#>
    [System.Collections.ArrayList] $refsList = $project.Refs | Select-Object -Unique

    ####### 2b. remove system refs #######
    <#----------------------------------#>
    [string[]] $systemRefs = $refsList | Where-Object {$_.StartsWith('System') -or $_.StartsWith('Microsoft') -or $_.ToLower().Contains('mstsc') -or $_.Contains('PresentationCore') -or $_.Contains('PresentationFramework') -or $_.StartsWith('Windows') -or $_.StartsWith('Spitfire') -or $_.StartsWith('Telerik') -or $_.StartsWith('SStuff') -or $_.StartsWith('Interop')}
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
    #if($ref -eq 'entityframework'){
        logThis("      *** ref: $ref ***")
        ####### 2g1. find ref in feed by name #######
        <#-----------------------------------------#>
        logThis("   searching for " + $ref + " in nuget feed")
        [bool] $isRefListedInSource = $false
        if(($nugetRefs -like ("$ref*")).Count -gt 0){ #-or $ref -eq 'CefSharp' -or $ref -eq 'CefSharp.Core'){ 
            $isRefListedInSource = $true
        }
        
        ####### 2g2. Ref Is Listed In Source #######
        <#----------------------------------------#>
        if($isRefListedInSource){
            logThis("   found $ref in nuget feed")

            ####### 2g2a. get current xml node by ref name #######
            <#--------------------------------------------------#>
            [System.Xml.XmlLinkedNode[]] $oldNode = $csprojFile.Project.GetElementsByTagName('Reference') | Where-Object ({$_.Include -like "*$ref*"})
            if($null -eq $oldNode){
                logThis("HERE ERROR OF EMPTY node for: $ref")
            }
            
            ####### 2g2b. retrieve dll version #######
            <#--------------------------------------#>
            [string[]] $hintPath = $oldNode[0].HintPath
            if($null -eq $oldNode -or $null -eq $csprojPath + '\..\' + $hintPath){
                logThis("HERE ERROR OF EMPTY DLL PATH for: $ref | $csprojPath + '\..\' + $oldNode")
            }
            else{
                [string] $dllPath = $csprojPath + '\..\' + $oldNode[0].HintPath
                $dllVersion = (Get-Item $dllPath).VersionInfo.ProductVersion
                if($dllVersion -notlike '[0-9]*.[0-9]*.[0-9]*' -and $dllVersion -notlike '[0-9]*.[0-9]*.[0-9]*.[0-9]*'){
                    $dllVersion = (Get-Item $dllPath).VersionInfo.FileVersion
                }
                #if($dllVersion -like '[0-9]*.[0-9]*.[0-9]*.0'){
                <#if($dllVersion -like '[0-9]*.[0-9]*.[0-9]*.[0-9]*'){
                    [int] $lastDotIndex = $dllVersion.LastIndexOf('.')
                    #$dllVersion = $dllVersion.Substring(0,$dllVersion.Length-2)
                    $dllVersion = $dllVersion.Substring(0,$lastDotIndex)
                }#>
                if($null -eq $dllVersion){                    
                    if($ref -like 'Newtonsoft.Json'){
                        $dllVersion = '11.0.2.21924'
                    }
                    else{
                        logThis("HERE ERROR OF EMPTY DLL version for: $ref | (Get-Item $dllPath).VersionInfo.ProductVersion")
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
            $versionNode = $csprojFile.CreateElement('Version',$csprojFile.Project.NamespaceURI)
            $excludeAssetsNode = $csprojFile.CreateElement('ExcludeAssets',$csprojFile.Project.NamespaceURI)
            
            ####### Set Attributes
            <#if($ref -eq 'CefSharp' -or $ref -eq 'CefSharp.Core'){
                $node.SetAttribute('Include','CefSharp.Common')
                #$node.SetAttribute('Version','73.1.130')
                $versionNode.InnerText = '73.1.130'
            }else{#>
                $node.SetAttribute('Include',$ref)
                #$node.SetAttribute('Version',$dllVersion)
                $versionNode.InnerText = $dllVersion
                $excludeAssetsNode.InnerText = 'runtime'
            #}
            $node.AppendChild($versionNode)
            $node.AppendChild($excludeAssetsNode)

            ####### add child
            #if(($ref -ne 'CefSharp' -and $ref -ne 'CefSharp.Core') -or $csprojFile.Project.ItemGroup.PackageReference.Where({$_.Include -eq 'CefSharp.Common'})[0] -eq $null){
                $itemGroup.AppendChild($node)
            #}
            logThis('   added new ref node for ' + $ref)
        }
        ####### 2g3. Ref Is Not Listed In Source #######
        <#--------------------------------------------#>
        else {
            logThis("   ERROR: can't find $ref in nuget sources")
        }
    #}
    }
    
        ####### update from other script for 3rd party duplicate #######
        <#------------------------------------------------------------#>
        #refsList2 is re-generated because the 1st one is clean from system refs
    [System.Collections.ArrayList] $refsList2 = $project.Refs | Select-Object -Unique
    foreach($ref in $refsList2){
    
        ####### 2g2a. get current xml node by ref name #######
        <#--------------------------------------------------#>
        [System.Xml.XmlLinkedNode[]] $oldNode = $csprojFile.Project.GetElementsByTagName('Reference') | Where-Object ({$_.Include -like "*$ref*"})

            
        ####### 2g2b. get Hint path #######
        <#-------------------------------#>
        if($null -ne $oldNode){

            [string[]] $hintPath = $oldNode[0].HintPath
            if($hintPath){
                if($hintPath[0].Contains('\3rd Party\')){
                    $oldNode[0].HintPath = $hintPath[0].Replace('\3rd Party\','\3rd Party Duplicate\')
                            
                ####### 2h. save csproj file #######
                <#--------------------------------#>
                $csprojFile.Save($csprojPath)
                Write-Host "update in" $project.Path
                }
            }
        }else{
            Write-Host "$oldNode is empty"
        }
    }



    ####### 2h. save csproj file #######
    <#--------------------------------#>
    logThis("saving csproj file for " + $project.Name)
    $csprojFile.Save($csprojPath)
    logThis("saved csproj file for " + $project.Name)
#}
}
}
####### 3. nuget restore #######
<#----------------------------#>
logThis('restoring nuget packages so that pending changes will apear in VS2017')
& $nugetPath restore ($pathToSln +'\' + $slnName)
logThis("restored nuget packages for $slnName")

logThis("$slnName is now dependency-managed")


####### 5. copy 3rd Party Folder Duplicates #######
<#-----------------------------------------------#>
& $PSScriptRoot\5-duplicating3rdParty.ps1

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
            # 2g2b. retrieve dll version
            # 2g2c. remove current xml node
            # 2g2d. add new xml entriy to csproj
        # 2g3. Ref Is Not Listed In Source    
    # 2h. save csproj file
# 3. nuget restore
# 4. logging
# 5. copy 3rd Party Folder Duplicates
