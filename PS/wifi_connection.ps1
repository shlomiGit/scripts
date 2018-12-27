########## params
[int] $connectGap = 60000
[int] $pingCounter = 0
[int] $pingLimit = 5
[bool] $firstTime = $true

########## function Test-IsWiFiConnected
function Test-IsWiFiConnected {
    # get state string
    [string] $stateStr = netsh interface show interface name="Wi-Fi" | findstr /C:"Connect state"

    # test connection action
    [bool] $isConnected = $stateStr.Contains('Connected')

    #return result
    return $isConnected
}

########## function Reset-WiFi
function Reset-WiFi {
    netsh interface set interface name="Wi-Fi" admin=DISABLED
    netsh interface set interface name="Wi-Fi" admin=ENABLED
    netsh wlan connect name=oren
    Write-Host "Reset-WiFi: " ([datetime]::Now)
}

########## infinite loop
while($true){    
    ########## test wifi
    if(!(Test-IsWiFiConnected)){
        if($firstTime){
            netsh wlan connect name=oren
            Write-Host "first try: " ([datetime]::Now)
            $firstTime = $false
        } else {
            (Reset-WiFi)
            Write-Host "second try: " ([datetime]::Now)
            $firstTime = $true
        }
    } else {
        if(!$firstTime){$firstTime = $true}
    }
    
    ########## test out
    [bool] $firstTest = $true
    $pingCounter++
    if($pingCounter -eq $pingLimit){
        $pingCounter = 0
        if(!(Test-Connection google.com -Quiet)){
            if($firstTest){
                (Reset-WiFi)
                $firstTest = $false
            }
            else{
                Restart-Computer
            }
        }
    }

    ########## sleep loop
    Start-Sleep -Milliseconds $connectGap
}

########## my timer
#[datetime] $currentTime = [datetime]::Now
#[datetime] $targetTime = $currentTime.AddMinutes(5)

#while($true){
#    if([datetime]::Now.Minute -eq $targetTime.Minute){
#        if(!(Test-IsWiFiConnected)){
#            netsh wlan connect name=oren
#        }
#        $targetTime = $targetTime.AddMinutes(5)
#    }
#}


########## timer event
#Unregister-Event thetimer
#[timers.timer] $timer = new-object timers.timer
#$action = Write-Host 'from timer' #Test-IsWiFiConnected
#$timer.Interval = 2000
#$timer.AutoReset = $false
#$timer.Enabled = $true
#$timer.start()
#Register-ObjectEvent -InputObject $timer -EventName elapsed –SourceIdentifier thetimer -Action $action
