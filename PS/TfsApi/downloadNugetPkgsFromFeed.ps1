#GET https://pkgs.dev.azure.com/{organization}/{project}/_apis/packaging/feeds/{feedId}/nuget/packages/{packageName}/versions/{packageVersion}/content?api-version=5.1-preview.1
#GET https://{instance}/{collection}/_apis/packaging/feeds/{feedId}/nuget/packages/{packageName}/versions/{packageVersion}/content?api-version=5.0-preview.1

####### Params #######
<#------------------#>
param(
    [string] $serverUrl = '[instance]/tfs/DefaultCollection/_apis/packaging/feeds',
    [string[]] $sources = @('MarketPackages','DeletedPackages'),    
    [string] $nugetPath = "C:\Users\shlomiz\source\ConvertingToDependencyManaged\apps\nuget.exe",
    [string] $method = 'GET',
    [string] $userName = "[domain]\shlomiz",
    [string] $localPath = 'C:\Users\shlomiz\Downloads\pkgs\'
)

### creds ###
[securestring] $pwd = Read-Host -AsSecureString
[pscredential] $creds = New-Object pscredential($userName, $pwd)

####### get pkgs #######
<#--------------------#>
foreach($source in $sources){
    [string[]] $nugetPkgs = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'
    $nugetPkgs += & $nugetPath list -source $source

    foreach($pkg in $nugetPkgs){
        [string] $uri = $serverUrl + '/' + $source + '/nuget/packages/' + $pkg.Split(' ')[0] + '/versions/' + $pkg.Split(' ')[1] + '/content?api-version=5.1-preview.1'
        [string] $pkgPath = $localPath + $pkg.Split(' ')[0] + '.' + $pkg.Split(' ')[1] + '.nupkg'
        Invoke-RestMethod -Uri $uri -Method $method -Credential $creds -OutFile $pkgPath
    }
}
