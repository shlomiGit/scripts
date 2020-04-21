####### Params #######
<#------------------#>
param(
    [string] $pathToSln, #example = 'C:\Users\shlomiz\source\repos\Branches\NugetDev',
    [string] $slnName #example = 'Client.sln'
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
        $projectPath = $projectFullPath.Substring(0,$lastSlashIndex)

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
    #[xml] $projContent = New-Object -TypeName xml
    [xml] $projContent = Get-Content $projPath #$projContent.Load($projPath) #Get-Content -Path $projPath
    
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
Out-File -FilePath $PSScriptRoot\logs\RefsByProjects.txt -InputObject $projectsList -Width 2560
return $projectsList
