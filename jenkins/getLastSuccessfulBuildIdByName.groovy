def call (String jobName, Boolean verbose = false) {	
		if(env.display || verbose){
			println "jobName: "  + jobName
		}
    Item[] items = Jenkins.instance.getAllItems()
		if(env.display || verbose){
			println "items: " + items
		}
	Item item = items.find{it.fullName==jobName}
		if(env.display || verbose){
			println "item: " + item
		}
	Job[][] jobs = item.getAllJobs()
		if(env.display || verbose){
			println "jobs: " + jobs
		}
	org.jenkinsci.plugins.workflow.job.WorkflowRun lastBuild = jobs[0][0].getLastSuccessfulBuild()
		if(env.display || verbose){
			println "lastBuild: " + lastBuild
		}
	return lastBuild.id
}
