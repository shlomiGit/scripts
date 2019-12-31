def call (deploy_to_dev_var) {
	def srq_name
	def version
	def deploy_to_env

pipeline {
	parameters {
		booleanParam(defaultValue: false, description: '', name: 'deploy_to_dev')
		booleanParam(defaultValue: false, description: '', name: 'deploy_to_test')
		booleanParam defaultValue: false, description: 'force deploying a version that is already installed', name: 'force'
	}
	options{
		buildDiscarder(logRotator(numToKeepStr: "${numberOfBuildsToKeep}"))
	}
	environment {
		display = "${display}"
		// vars for stage 'build'
		mavenGoals = 'clean install -U -X'
		dependencyReleaseRepo = 'cal-maven-all'
		dependencySnapshotRepo = 'cal-maven-all'
		deployReleaseRepo = 'cal-internal-release'
		deploySnapshotRepo = 'cal-internal-snapshots'
		// vars for stage 'archive'
		pattern = '**/target/*.*ar, **/target/*.zip, **/pom.xml'
	}
	agent any
	stages {
		stage('display'){
			when {
				environment name: 'display', value: 'true'
			}
			steps{
				sh 'printenv'
			}
		}
		stage('build'){
			steps{
				artifactoryMavenBuild("${dependencyReleaseRepo}", "${dependencySnapshotRepo}", "${deployReleaseRepo}", "${deploySnapshotRepo}", "${mavenGoals}")
			}
		}
		stage('archive'){
			steps{
				archiveArtifacts "${pattern}"
			}
		}
		stage('deploy'){
			when{
				anyOf{
					environment name: 'deploy_to_dev', value: 'true'; environment name: 'deploy_to_test', value: 'true'; equals expected: "true", actual: "${deploy_to_dev_var}"
				}
			}			
		    steps{
				script {
					pom = readMavenPom file: 'pom.xml'
					srq_name = pom['artifactId']
					version = pom['version']
					group = JOB_NAME.substring(0,JOB_NAME.indexOf('-'))
					
					if(deploy_to_dev_var==true || deploy_to_dev=='true'){
						deploy_to_env = 'dev'
						build job: "${group}-deploy", parameters: [string(name: 'srq_name', value: "${srq_name}"), string(name: 'version', value: "${version}"), string(name: 'deploy_to_env', value: "${deploy_to_env}"), string(name: 'force', value: "${force}")]				
					}
					if(deploy_to_test=='true'){
						deploy_to_env = 'test'
						build job: "${group}-deploy", parameters: [string(name: 'srq_name', value: "${srq_name}"), string(name: 'version', value: "${version}"), string(name: 'deploy_to_env', value: "${deploy_to_env}"), string(name: 'force', value: "${force}")]				
					}
				}		        
		    }
		}
	}
}
}
