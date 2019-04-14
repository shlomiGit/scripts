def call (String dependencyReleaseRepo, String dependencySnapshotRepo, String deployReleaseRepo, String deploySnapshotRepo, String mavenGoals) {
	script {
	// artifactory server
		def server = Artifactory.server "??????????????????"
	// maven build
		def rtMaven = Artifactory.newMavenBuild()
		rtMaven.resolver server: server, releaseRepo: dependencyReleaseRepo, snapshotRepo: dependencySnapshotRepo
		rtMaven.deployer server: server, releaseRepo: deployReleaseRepo, snapshotRepo: deploySnapshotRepo
		env.MAVEN_HOME = '/prod/jenkins/apache-maven-3.0.5'
	// buildInfo
		def buildInfo = rtMaven.run pom: 'pom.xml', goals: mavenGoals
		server.publishBuildInfo buildInfo
	// Interactive promotion
		def promotionConfig = [
		// Mandatory parameters
			'targetRepo': '',
			'buildName': buildInfo.name,
			'buildNumber': buildInfo.number
		]
		Artifactory.addInteractivePromotion server: server, promotionConfig: promotionConfig
	// build promotion
	//	Artifactory.artifactoryPromoteBuild server: server, promotionConfig: promotionConfig
	}
}
