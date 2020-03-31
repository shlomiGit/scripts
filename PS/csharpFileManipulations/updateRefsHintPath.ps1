####### Params #######
<#------------------#>
param(
    ####### logs
    $logPath = "$PSScriptRoot\logs\log.txt",

    ####### sln details
    [string] $pathToSln, #example = 'C:\Users\shlomiz\source\repos\Branches\NugetDev',
    [string[]] $slnNames, #example = @('PCCQCS.sln','IntegrationTests.sln','ApplicationInsightsDispatcher.sln','SMFMonitor.sln','CommonInfrastructure.sln','Server.sln','OCController.sln','DPControllerCommon.sln','DPController.sln','QTController.sln','Client.sln','PressDataCollector.sln','DFEMock.sln','MigrationWizard.sln')
    [string] $tfPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe'
)

####### 0. functions #######
<#------------------------#>
function logThis([string] $message){
    $date = [datetime]::Now
    Out-File -FilePath $logPath -Append -InputObject $date": "$message
}

foreach($slnName in $slnNames){

####### 1. get projects list #######
<#--------------------------------#>
[PSObject[]] $projectsList = & $PSScriptRoot\1-getSlnProjects.ps1 $pathToSln $slnName

####### 2. loop projects #######
<#----------------------------#>
foreach($project in $projectsList){
#if($project.Name -eq 'Spitfire.Client.Utils.ECS.Plugin.csproj'){

    ####### 2a. get project refs #######
    <#--------------------------------#>
    [System.Collections.ArrayList] $refsList = $project.Refs | Select-Object -Unique
       
    ####### 2c. tf checkout csproj #######
    <#----------------------------------#>
    $csprojPath = $pathToSln +'\' + $project.Path + '\' + $project.Name
    & $tfPath checkout $csprojPath

    
    ####### 2d. read xml #######
    <#------------------------#>    
    [xml] $csprojFile = Get-Content $csprojPath

    
    ####### 2g. loop refs #######
    <#-------------------------#>
    foreach($ref in $refsList){
    #if($ref -eq 'LandaServiceBus.Core'){
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
    #}
}
#}
}
