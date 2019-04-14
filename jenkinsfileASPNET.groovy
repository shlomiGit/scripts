def call () {
	// varaibles for agent
	def myLabel = 'windows'
	def jobName = ("${JOB_NAME}").replace("%2F","-")
	//def myWorkspace = "workspace\\${jobName}"
	def myWorkspace = "workspace\\${JOB_NAME}"
	myWorkspace = myWorkspace.replace("%2F","-")

pipeline {
	parameters {
		booleanParam(defaultValue: false, description: '', name: 'display')
	}
	options{
		buildDiscarder(logRotator(numToKeepStr: "${numberOfBuildsToKeep}"))
	}
	environment {
		// variables for stage 'build'		
		publishDir = 'publishFolder'
		// variables for stage 'zip'
		zipFolder = 'zipTemp'
		zipName = "${jobName}_${BUILD_ID}"
		fullZip = "${myWorkspace}\\${zipFolder}\\${zipName}.zip"
		// variables for stage 'upload'
		target = "CalSale\\${jobName}\\"
	}
	agent {
		node{
		label myLabel
		customWorkspace myWorkspace
		}
	}
	stages {
		stage('displayEnvVars'){
			when{
				environment name: 'display', value: 'true'
			}
			steps{
				bat 'set'
			}
		}
		stage('releaseNotes'){
			steps{
				releaseNotes()
			}
		}
        	stage('nugetResrore'){
	            steps{
			//nuGetPath is defined as agent env var
                	bat 'nuget restore'
	            }
        	}
	        stage('build'){
			steps{
				// create dummy publish profile
				bat 'copy nul ci.pubxml'
				writeFile file: 'ci.pubxml', text: """<?xml version="1.0" encoding="utf-8"?>
<!--
This file is used by the publish/package process of your Web project. You can customize the behavior of this process
by editing this MSBuild file. In order to learn more about this please visit https://go.microsoft.com/fwlink/?LinkID=208121. 
-->
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
<PropertyGroup>
<WebPublishMethod>FileSystem</WebPublishMethod>
<PublishProvider>FileSystem</PublishProvider>
<LastUsedBuildConfiguration>Release</LastUsedBuildConfiguration>
<LastUsedPlatform>Any CPU</LastUsedPlatform>
<SiteUrlToLaunchAfterPublish />
<LaunchSiteAfterPublish>True</LaunchSiteAfterPublish>
<ExcludeApp_Data>False</ExcludeApp_Data>
<publishUrl>e:\\CalsaleAdminPublish</publishUrl>
<DeleteExistingFiles>False</DeleteExistingFiles>
</PropertyGroup>
</Project>"""
				//msBuildPath is defined as agent env var
				bat "msbuild /p:DeployOnBuild=true;publishProfile=\"${workspace}\\ci.pubxml\";WebPublishMethod=FileSystem;publishUrl=\"${workspace}\\${publishDir}\""
			}
		}
		stage('zip'){
			steps{
				zip zipFile:"${fullZip}", dir:"${publishDir}"
			}
		}
        stage('upload'){
            steps{
                artifactoryFlatUpload("${fullZip}", "${target}")
	    }
        }
        stage('cleanup'){
            steps{
                dir ("${workspace}\\${zipFolder}") {
                    deleteDir()
                }
            }
        }
    }
}
}
