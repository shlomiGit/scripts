### params ###
Param(
    [string] $serverUrl = 'http://[instance]/tfs/DefaultCollection/_apis/packaging/feeds',
    [string] $localPkgsPath = 'C:\Users\shlomiz\Downloads\pkgs',
    [string[]] $sources = @('ExternalPackages','ffffffff'),
    [string] $nugetPath = "C:\Users\shlomiz\source\ConvertingToDependencyManaged\apps\nuget.exe",
    [string] $method = 'GET',
    [string] $userName = "miz"
)

function List-Pkgs(){
    return & $nugetPath list -source $sources[0]
}

function Push-Pkgs(){
    <#
    [Object[]] $pkgs = Get-ChildItem "$localPkgsPath\*.*"
    foreach($pkg in $pkgs){
        nuget push -Source $sources[0] -ApiKey AzureDevOps -SkipDuplicate $pkg
    }
    #>
    [Object[]] $folders = Get-ChildItem "$localPkgsPath\*.*"
    foreach($folderName in $folders.Name){
        Set-Location -Path $localPkgsPath\$folderName
        & nuget push -Source $sources[0] -ApiKey AzureDevOps -SkipDuplicate '*.nupkg'
    }
}

function Compare-Pkgs(){
    [string[]] $nugetRefs = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'
    $nugetRefs += List-Pkgs

    [string[]] $pkgs = Get-ChildItem "$localPkgsPath\*.*"
    $nugetRefs
    $pkgs
    #Write-Host "Feed count is: " $nugetRefs.Count " and local count is: " $pkgs.Count
    #Write-Host "Feed is: " $nugetRefs
    #Write-Host "local is: " $pkgs
}

function Download-Pkgs(){
#IMPORTANT downloads only latest version, Not all
    ### creds ###
    [securestring] $pwd = Read-Host -AsSecureString
    [pscredential] $creds = New-Object pscredential($userName, $pwd)
    
    #foreach($source in $sources){
    [string[]] $nugetPkgs = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'
    $nugetPkgs += List-Pkgs

        foreach($pkg in $nugetPkgs){
            [string] $uri = $serverUrl + '/' + $sources[0] + '/nuget/packages/' + $pkg.Split(' ')[0] + '/versions/' + $pkg.Split(' ')[1] + '/content?api-version=5.1-preview.1'
            [string] $pkgPath = $localPkgsPath + '\' + $pkg.Split(' ')[0] + '.' + $pkg.Split(' ')[1] + '.nupkg'
            Invoke-RestMethod -Uri $uri -Method $method -Credential $creds -OutFile $pkgPath
        }
    #}
}

function Rename-Pkgs(){
    [Object[]] $pkgs = Get-ChildItem "$localPkgsPath\*.*"
    foreach($pkg in $pkgs){
        Rename-Item -Path $pkg -NewName ($pkg.Name).Replace('nupkg','zip')
    }
}

function Extract-Archives(){
    [Object[]] $zips = Get-ChildItem "$localPkgsPath\*.*"
    foreach($zip in $zips){
        [string] $zipName = $zip.Name.Replace('.zip','')
        Expand-Archive -Path $zip -DestinationPath $localPkgsPath\$zipName
    }
}

function Pack-Pkgs(){
    [Object[]] $folders = Get-ChildItem "$localPkgsPath\*.*"
    foreach($folderName in $folders.Name){
        #[string] $nuspecName = $folderName.Split('.')[0] + ".nuspec"
        #& nuget pack "$localPkgsPath\$folderName\$nuspecName" -OutputDirectory $localPkgsPath\$folderName
        Set-Location -Path $localPkgsPath\$folderName
        & nuget pack
    }
}

#function Select-Function(){
    [int] $selection = Read-Host -Prompt "Select function: Push-Pkgs (1), Compare-Pkgs (2), Download-Pkgs (3), Rename-Pkgs (4), Extract-Archives (5), Pack-Pkgs (6)"
    Switch ($selection){
        1 {Push-Pkgs}
        2 {Compare-Pkgs}
        3 {Download-Pkgs}
        4 {Rename-Pkgs}
        5 {Extract-Archives}
        6 {Pack-Pkgs}
        default {Write-Host "Don't know what to do"}
    }
#}
