def call () {
	// varaibles for stage readMavenPom
	def pomVersion = ''

pipeline {
	environment {		
		// **** respond to only multibranch jobs for now:
		jobName = ("${JOB_NAME}").replace("-updateParamsDefaultValues/${BRANCH_NAME}","-release")
		pomVarName = 'version'
		jobVarName = 'version'
	}
	agent any	
	stages {
		stage('display'){
			when{
				environment name: 'display', value: 'true'
			}
			steps{
				sh 'printenv'
			}
		}
		stage('readMavenPom'){
			steps{				
				script{
					pom = readMavenPom file: 'pom.xml'
					pomVersion = pom['version']
					sh "pomVersion=${pomVersion}"
				}
			}
		}
		stage('updateJobDefaultVersion'){
			steps{
				updateParameterDefaultValue("${jobVarName}", "${pomVersion}", "${jobName}")
			}
		}
	}
}
}
