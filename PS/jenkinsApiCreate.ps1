[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               HelpMessage = 'Lowercase, alphabetic name of process to display')]
    [ValidatePattern('(^Srq[0-9]+$)')]
    [string]$NEW_SERVICE_NAME
)



#$NEW_SERVICE_NUMBER = ($NEW_SERVICE_NAME -split "q",2)[1]
$JENKINS_SERVER_URL = "http://alm-tstappjnk01:8080/jenkins"
#$GIT_EXECUTABLE = "C:\Users\g_mmamli\AppData\Local\Programs\Git\bin\git.exe"
$BASE_FOLDER = "c:\Temp"
$LogFileName = $BASE_FOLDER + "\\" + (Get-Date -Format "yyyy-MM-dd-HH-mm-ss") + "-create-for-oda-repository-a-jenkins-job.log"
$JENKINS_PROJECT_ID="view/DevOps"
$JENKINS_Template_ID="view/DevOps/job/oda-srq001/job/oda-srq001-ci/config.xml"
$ParsedJson=""
$RESTAPIPassword=""
$RESTAPIUser=""




Function Log {
   Param ([string]$logstring)
   Write-Host "$logstring"
   $Timestamp = (Get-Date -Format "yyyy-MM-dd-HH-mm-ss")
   Add-content $LogFileName -value "$Timestamp : $logstring"
   
}

############################
# Script Entry Point
function Main {

    GeneratingJenkinscrumb
    Log "Initializing connection to Jennkins, Generating crumb"
    #CreatingJenkinsfolder
    Log "New Folder Created"
    CIXML
    Log "got Template XML of a CI JOB"
    }

#################################
# Generate a crumb (Jenkins CSRF security):
# each request to the Jenkins API needs to have what is known as a crumb defined in the headers.
# To generate this crumb, we need to make a request to http://alm-prdjnk01:8080/jenkins/crumbIssuer/api/json.


function GeneratingJenkinscrumb {
    
    
    $Credentials = Get-Credential -Credential $null
    $global:RESTAPIUser = $Credentials.UserName
    $Credentials.Password | ConvertFrom-SecureString
    $global:RESTAPIPassword = $Credentials.GetNetworkCredential().password
    
    $Headers = @{ 
        Authorization = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))
    }



    $json = Invoke-WebRequest -Uri "$JENKINS_SERVER_URL/crumbIssuer/api/json" -Headers $Headers

    $global:ParsedJson = $json | ConvertFrom-Json

    Write-Host "The Jenkins crumb is $($parsedJson.crumb)" -ForegroundColor Yellow

    #return $ParsedJson.crumb
    
} #Generate-Jenkins-crumb       




#################################
# Createin a Jenkins folder under location:
# http://alm-prdjnk01:8080/jenkins/view/DevOps/
# to change the location need to change the variable: "$JENKINS_PROJECT_ID"


function CreatingJenkinsfolder {
    
    $CreateFolderHeaders = @{ 
        "Jenkins-Crumb" = $ParsedJson.crumb
        Authorization = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))
    }
   


    try {

    Invoke-WebRequest -Uri "$JENKINS_SERVER_URL/$JENKINS_PROJECT_ID/createItem?name=$NEW_SERVICE_NAME&mode=com.cloudbees.hudson.plugins.folder.Folder" -Headers $CreateFolderHeaders -Method Post 

    } #try

    # Validate success
    catch {
        $_.Exception.Response
            $ExecutionCode=$($_.Exception.Response).StatusCode.value__
            if ($ExecutionCode -like "*401*") 
                {Write-Host "Warning Unauthorized..Exception.Response received from configuration of the Folder, **** CAN BE IGNORED ****" -ForegroundColor Yellow}
            else
                {Write-Host "$_.Exception.Response" -ForegroundColor Red}
            exit 1
    } #catch

} #Create-Jenkins-folder


function CIXML {
# download the CI Template from template-maven-multibranch-pipeline
    
    $GetCIXMLTemplateHeaders = @{ 
        "Jenkins-Crumb" = $ParsedJson.crumb
        Authorization = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))
    }

    try {

        (Invoke-WebRequest -Uri "$JENKINS_SERVER_URL/$JENKINS_Template_ID/" -Headers $GETCIXMLTemplateHeaders -Method Get).content | Out-File -FilePath "C:\Temp\citemplate.txt" | ConvertTo-Xml -As "Document"
        

        } #try
    
        # Validate success
        catch {
            $ExecutionCode=$($_.Exception.Response).StatusCode.value__
            $_.Exception.Response
                Write-Host "$($_.Exception.Response)" -ForegroundColor Yellow
                Write-Host "$($ExecutionCode)" -ForegroundColor Yellow
                exit 1
        } #catch
    
 # after downloading the ci template i am going to repalce "repository-template-oda" with the requiered srqXXX
 
    (get-content "C:\Temp\citemplate.txt" -raw) -replace "srq001",$NEW_SERVICE_NAME | out-file -FilePath "C:\Temp\citemplate.xml"

# create new CI job based on the template XML file
    
    $SetCIXMLTemplateHeaders = @{ 
        "Jenkins-Crumb" = $ParsedJson.crumb
        Authorization = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))
        "Content-Type" = "application/xml"
    }

    $body = "file=$(get-content -Path "C:\Temp\citemplate.txt" -Encoding utf8 -raw)"
     
    try {

        Invoke-WebRequest -Uri "$JENKINS_SERVER_URL/$JENKINS_PROJECT_ID/job/$NEW_SERVICE_NAME/createItem?name=$NEW_SERVICE_NAME-ci" -Headers $SetCIXMLTemplateHeaders -Method Post -Body $body
        

    } #try
    
    # Validate success
    catch {
            $ExecutionCode=$($_.Exception.Response).StatusCode.value__
            $_.Exception.Response
                Write-Host "$($_.Exception.Response)" -ForegroundColor Yellow
                Write-Host "$($ExecutionCode)" -ForegroundColor Yellow
                exit 1
    } #catch

}

Main

#########################
# run build
#
#    $BuildHeaders = @{ 
#        "Jenkins-Crumb" = $ParsedJson.crumb
#        Authorization = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))
#    }
# 
#
# try {   
# Invoke-WebRequest -Uri "$JENKINS_SERVER_URL/job/my%20powershell%20script%20job/build" -Headers $BuildHeaders -Method Post
# }
#
# catch {
#    $_.Exception.Response
#        Write-Host "$_.Exception.Response" -ForegroundColor Yellow
#        exit 1
# }
##########################



#-Body $CreateFolderBody  
    #$CreateFolderBody = @{
    #"description" = ""
    #"name" = "srq777"
    #"url" = '$JENKINS_SERVER_URL/$JENKINS_PROJECT_ID/job/srq777/'
    #} 
