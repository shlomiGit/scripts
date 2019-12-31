def call () {
	def jobName = "${JOB_NAME}"
	jobName = ("${jobName}").replace("%2F","-")
	def agent_label = 'ofm-tstappint01'
	def branchName = "${BRANCH_NAME}"
	branchName = ("${branchName}").replace("%2F","-")
	def myWorkspace = "workspace\\${JOB_NAME}"
	myWorkspace = myWorkspace.replace("%2F","-")
	def writeAssemblyInfo = libraryResource 'writeAssemblyInfo.ps1'
pipeline {
	parameters {
		booleanParam(defaultValue: false, description: 'check this to run a "DEPLOY" build', name: 'deploy')		
		choice choices: 'dev\ntest\nstage\ndevops', description: 'select server env to deploy', name: 'server_env'
		booleanParam defaultValue: false, description: 'force deploying a version that is already installed', name: 'force_deploy'
		string defaultValue: '', description: 'please enter in the form of [product]_[component]_[version], for example calsale_admin_test', name: 'deploy_block'
	}
	options{
		buildDiscarder(logRotator(numToKeepStr: "${numberOfBuildsToKeep}"))
	}
	environment {
		// variables for stage 'update Assembly Info'
		scriptArg = "branch:${GIT_BRANCH};commit:${GIT_COMMIT};build:${BUILD_ID}"
		scriptPath = "${workspace}\\writeAssemblyInfo.ps1"
		// variables for stage 'upload'
		rt_repo_name = "cal-calsale"
		repo_trail_path = "${jobName}/${BUILD_ID}"
	}
	agent {
		node{
			label agent_label
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
				bat 'whoami'
				powershell 'Write-Host $env:myWorkspace'
			}
		}
		stage('update Assembly Info'){
			steps{
				writeFile encoding: 'UTF-8', file: 'writeAssemblyInfo.ps1', text: writeAssemblyInfo
				powershell '& $env:scriptPath -assemblyTypeInfo $env:scriptArg'
			}
		}
		stage('nugetRestore'){
			steps{
		//nuGetPath is defined as agent env var
				bat 'nuget restore -Source http://artifactory:8080/artifactory/api/nuget/cal-nuget-all'
			}
		}
        stage('clean temp package folder'){			
			steps{
				bat 'del /S /Q E:\\PackageTmp'
            }
		}
		stage('build and package website'){
			steps{
				//msBuildPath is defined as agent env var
				bat "msbuild /p:DeployOnBuild=true;publishProfile=ci.pubxml;PackageTempRootDir=\"\""
			}
		}
        stage('upload'){
            steps{
				artifactoryFlatUpload("**\\obj\\Debug\\(*).zip", "${rt_repo_name}/${repo_trail_path}/")
			}
        }
		stage('sync dmz artifactory'){
			steps{
				build job: 'sync-artifactories', parameters: [string(name: 'repo_name', value: "${rt_repo_name}"), string(name: 'repo_trail_path', value: "${repo_trail_path}"), string(name: 'artifact_file_name', value: '*.zip')]
			}
		}
		stage('call deploy'){
			when{
				environment name: 'deploy', value: 'true'
			}			
		    steps{
				script {
					int slashIndex = JOB_NAME.indexOf("/")
					JOB_NAME = JOB_NAME.substring(0,slashIndex)
					int dashIndex = JOB_NAME.indexOf("-")
					int lastDashIndex = JOB_NAME.lastIndexOf("-")
					component = JOB_NAME.substring(dashIndex+1,lastDashIndex)
					println "the component is: " + component
				}
		        build job: 'calsale-deploy', parameters: [string(name: 'version', value: "${BUILD_ID}"), string(name: 'ci_BRANCH_NAME', value: "${branchName}"), string(name: 'server_env', value: "${server_env}"), string(name: 'deploy_block', value: "${deploy_block}"), string(name: 'force', value: "${force_deploy}")]
		    }
		}
	}
	post { 
		success { 
			cleanWS()
		}
	}
}
}
