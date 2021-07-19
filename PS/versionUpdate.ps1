# Enable -Verbose option
[CmdletBinding()]
Param(
  [string]$filePath #= "C:\\temp\\Servotronix\\temp\\version.cpp"
)
if ($filePath -and (Test-Path $filePath)) {
	$fileContent = Get-Content $filePath
	$regex = 'Version [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
	# can also work: $regex = '\d+\.\d+\.\d+\.\d+'
	$versionString = select-string -Path $filePath -Pattern $regex -AllMatches | % { $_.Matches } | % { $_.Value }
	if ($versionString) {
    	$versionArray = $versionString.Split('.')
    	[int] $lastBuild = $versionArray[3]
    	$lastBuild++
    	$versionArray[3] = $lastBuild
    	[String] $newVersionString = $versionArray -join '.'
    	$newVersionString
    	Write-Host "Replacing ""$versionString"" with ""$newVersionString"""
    	$fileContent -replace $versionString,$newVersionString > "${filePath}"
	}
} else {
	Write-Error "Cannot find filePath ${filePath}"
}
