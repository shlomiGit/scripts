def call (String version, String moduleName=null, String moduleVersion=null) {
	script {
	// descriptor instance
		def descriptor = Artifactory.mavenDescriptor()
	// set version to update
		descriptor.version = version
	// update a sub-module
		if (moduleName){
			descriptor.setVersion moduleName, moduleVersion
		}
	// update release version in pom files
		descriptor.transform()		
	
		if(${BRANCH_NAME}!='trunk'){
	// git commit
			sh 'git commit -a -m "CI Increase Version"'
	// git push
			sh 'git config --global push.default simple'
			sh 'git push origin HEAD:$GIT_BRANCH'
		}
	// svn 
		if(env.display){
			sh 'svn copy ^/trunk ^/tags/$version -m "$version"'
		}
	}
}
