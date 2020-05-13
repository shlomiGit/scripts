###### get commits with comment=increase version and Author=Elimelech
#uri
$author = '???????????'
[uri] $uri = "https://dev.azure.com/???????????/??????????/_apis/git/repositories/Maxx_Firmware/commits?searchCriteria.author=$author&api-version=4.1"
 
#headers
$basicAuth = ("{0}:{1}" -f "????????????????????","?????????????????")
$basicAuth = [System.Text.Encoding]::UTF8.GetBytes($basicAuth)
$basicAuth = [System.Convert]::ToBase64String($basicAuth)
$headers = @{Authorization=("Basic {0}" -f $basicAuth)}
#Invoke-RestMethod -Uri $uri -UseDefaultCredentials -Method Get
$jsonResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
###### extract previous to last increase version commit
[int] $indexOfPrevLast = 1
$prevLastCommit = ($jsonResponse.value | Where {$_.comment -eq "increase version"})[$indexOfPrevLast]
$lastCommitId = $prevLastCommit.commitId
###### get commits between last increase version and current
#uri
[string] $repo = '??????????????????????'
[uri] $uri = "https://dev.azure.com/??????????????/???????????????/_apis/git/repositories/$repo/commits?api-version=4.1"
#Invoke-RestMethod -Uri $uri -UseDefaultCredentials -Method Get
$jsonResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
#index of last commit
$lastCommit = $jsonResponse.value | Where {$_.commitId -eq $lastCommitId}
[int] $indexOfLastIncreaseVersionCommit = $jsonResponse.value.IndexOf($lastCommit)
#fetch all commits up to last commit Id
$relevantArray = $jsonResponse.value[0..$indexOfLastIncreaseVersionCommit]
#fetch unique emails from commits
[string] $emails = $relevantArray[0..$relevantArray.Length].author.email | select -Unique
$emails
