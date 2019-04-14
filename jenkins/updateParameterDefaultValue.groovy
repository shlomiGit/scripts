def call (String name, String value, String jobName, Boolean verbose = false) {	
		if(env.display || verbose){
			println "jobName: "  + jobName
		}
	
	// get object
    Item[] items = Jenkins.instance.getAllItems()
		if(env.display || verbose){
			println "items: " + items
		}
	Item item = items.find{it.fullName==jobName}
		if(env.display || verbose){
			println "item: " + item
		}
	Job[] jobs = item.getAllJobs()
		if(env.display || verbose){
			println "jobs: " + jobs
		}
	
	// loop job branches
	jobs.each{ job ->
			if(env.display || verbose){
				println "job: " + job
				println "job.name: " + job.name
			}		
		JobProperty property = job.getProperty(ParametersDefinitionProperty)
			if(env.display || verbose){
				println "PROPERTY: " + property
			}
		parameterDefinitions = property.parameterDefinitions
			if(env.display || verbose){
				println "parameterDefinitions: " + parameterDefinitions
			}
		
		ParameterDefinition parameterDefinition = parameterDefinitions.find{it.name==name}
			if(env.display || verbose){
					println "parameterDefinition: " + parameterDefinition
					println "parameterDefinition: " + parameterDefinition.name
			}
			
		parameterDefinition.defaultValue = value
	}	
}
