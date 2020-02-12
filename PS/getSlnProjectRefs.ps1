####### Params #######
<#------------------#>
param(
    [string] $pathToSln,
    [string] $slnName
)

####### get sln content #######
<#---------------------------#>
$slnPath = $pathToSln + '\' + $slnName
$slnContent = Get-Content -Path $slnPath

####### get sln projects #######
<#----------------------------#>
[PSObject[]] $projectsList = New-Object System.Collections.ArrayList
foreach($line in $slnContent){
    if($line.Contains('Project("') -and $line.Contains('.csproj')){        
        $projectFullPath = ((($line.Split(','))[1]).Trim()).Trim('"')
        [int] $lastSlashIndex = $projectFullPath.LastIndexOf('\')
        $projectName = $projectFullPath.Substring($lastSlashIndex+1)
        $projectPath = $projectFullPath.Substring(0,$lastSlashIndex+1)

        ####### create object
        $project = New-Object -TypeName PSObject
        Add-Member -InputObject $project -MemberType NoteProperty -Name Name -Value $projectName
        Add-Member -InputObject $project -MemberType NoteProperty -Name Path -Value $projectPath
        $projectsList += $project
    }
}

####### get refs foreach project #######
<#------------------------------------#>
foreach($project in $projectsList){

    ####### get project file content #######
    <#------------------------------------#>
    $projPath = $pathToSln + '\' + $project.Path + '\' + $project.Name
    [xml] $projContent = Get-Content -Path $projPath
    
    ####### get project refs #######
    <#----------------------------#>
    [string[]] $projectRefs = $projContent.Project.GetElementsByTagName('Reference').Include

    ####### get refs names #######
    <#--------------------------#>
    [string[]] $RefNames = New-Object System.Collections.ArrayList
    foreach($line in $projectRefs){
        $RefNames += ($line.Split(','))[0]
    }
        
    ####### insert to object #######
    <#----------------------------#>
    Add-Member -InputObject $project -MemberType NoteProperty -Name Refs -Value $RefNames
}
Out-File -FilePath "C:\Temp\1.txt" -InputObject $projectsList -Width 2560
