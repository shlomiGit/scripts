def call () {

pipeline {
	environment {
		display = "${display}"
		// vars for stage 'build'
		mavenGoals = 'clean install -U -X'
		dependencyReleaseRepo = '???????'
		dependencySnapshotRepo = '???????'
		deployReleaseRepo = '???????'
		deploySnapshotRepo = '???????'
		// vars for stage 'archive'
		pattern = 'target/*.*ar'
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
	}
}
}
