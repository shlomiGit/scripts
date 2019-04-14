def call () {
	def pomVersion

pipeline {
	environment {
		// vars for stage 'build'
		mavenGoals = 'clean package -X'
		dependencyReleaseRepo = 'cal-maven-all'
		dependencySnapshotRepo = 'cal-maven-all'
		deployReleaseRepo = 'cal-internal-release'
		deploySnapshotRepo = 'cal-internal-snapshots'
		// vars for stage 'archive'
		pattern = 'target/*.*ar'
	}
	agent any
	parameters {
		string defaultValue: "${pomVersion}", description: '', name: 'version'
		string defaultValue: '', description: 'Leave blank or in order to set a pom version in all pom files in repo, please enter a value (include "-SNAPSHOT" if desired)', name: 'versionToIncrease'
	}
	stages {
		stage('display'){
			when {
				environment name: 'display', value: 'true'
			}
			steps{
				sh 'printenv'
			}
		}
		stage('versionUpdate'){
			steps{
				artifactoryMavenReleaseMgmt("${version}")
			}
		}
		stage('buildProperties'){
			when { not { branch 'trunk' } }
			steps{
				writeFile file: 'src/main/resources/build.properties', text: """Build_ID=${BUILD_ID}
Branch=${GIT_BRANCH}
Commit_ID=${GIT_COMMIT}
pom_version=${version}"""
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
		stage('increaseVersion'){
			when {
				expression { "${versionToIncrease}" != ''}
			}
			steps{			
				artifactorySetVersionInScm("${versionToIncrease}")
			}
		}
	}
}
}
