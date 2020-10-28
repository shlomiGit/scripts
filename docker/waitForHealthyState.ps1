[string] $containerName = 'zzz'
[int] $timeout = 60
[int] $counter = 0
For ($i=0; $i -le $timeout; $i++) {
    if((& docker inspect --format='{{.State.Health.Status}}' $containerName) -eq 'healthy'){
        write-host "container state is 'healthy'"
        break
    }else{
        write-host "container state is not yet 'healthy'"
        $counter += 1
        sleep 1
    }
}
if($counter -gt 58){write-host "container state is NOT 'healthy'"}
