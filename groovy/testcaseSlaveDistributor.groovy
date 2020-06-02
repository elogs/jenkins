currentBuild.displayName = "${BUILD_NUMBER}_${Revision}"
currentBuild.description = "${TCList}"

repeat_num = "${Execute_Times}" as Integer

if ("${TCList}" == "none") {
    println "No more pending TCs to run..."
    return
}

labels = getAvailableNode(getLabelNodes("${Node_Label}"))

for (int exec_counter = 1; exec_counter <= repeat_num; exec_counter++) {
    preDistribution(TCList, labels)
}

def getAvailableNode(nodeList) {
	TCCount = TCList.count("TC")
  	def freeNodes = []
    for (Node node in nodeList) {
		if (node.getComputer().isOffline()) {
			println "'$node.nodeName' is OFFLINE"
          	continue
        }
        if (node.getComputer().countBusy()>0) {
			println "'$node.nodeName' is BUSY, will add it to the pool with least priority"
			freeNodes.add(0, node.nodeName)
			continue
		}
        freeNodes.push(node.nodeName)
    }
    if ( TCCount < freeNodes.size()) {
	  freeNodes = freeNodes.takeRight(TCCount)		
	}
	return freeNodes
}

def getLabelNodes(label) {
    def lgroup = Jenkins.instance.getLabel(label)
    def nodes = lgroup.getNodes()
	return nodes
}

def preps(labels) {
    def builders = [:]
    labels.eachWithIndex { label, idx ->
		println label
		builders[label] = {
			tenvPrepare(label)
		}
	}
	parallel builders
}

def preDistribution(TCList, labels) {
    def builders = [:]
    TCArrayList = TCList.split(',') as List
    size = TCArrayList.size()

	labels.eachWithIndex { label, idx ->
		builders[label] = {
			def tcmap = [:]
			tc = TCArrayList.join(",")
			TCArrayList << TCArrayList[0]
			TCArrayList.remove(0)
			println "---> TC to run is: $tc at $label"
			tcmap[label] = tc
			if (tenvPrepare(label) == 'SUCCESS') {
                tcmap.eachWithIndex{entry, i -> runJob(entry.value, entry.key)}
			}
			else
			    println "TENV preparation failed"
		}
	}
	parallel builders
}

def runJob(tcList, label) {
	def buildResults = [:]
	stage("$label: Executing TCs") {
		script {
			echo "Run at ${label} TCs ${tcList}"
			def jobBuild = build job: "${sct_executor_job}", propagate: false, parameters: 
				[[$class: 'NodeParameterValue', name: 'NODE_NAME', labels: ["$label"], nodeEligibility: [$class: 'AllNodeEligibility']], 
				[$class: 'StringParameterValue', name: 'TCList', value: "${tcList}"], 
				[$class: 'StringParameterValue', name: 'SW_Revision', value: "${Revision}"],
				[$class: 'StringParameterValue', name: 'Branch', value: "${Branch}"]]
        		def jobResult = jobBuild.getResult()
        		echo "Build of ${sct_executor_job} returned result: ${jobResult}"
        		buildResults["${sct_executor_job}"] = jobResult
        			if (jobResult != 'SUCCESS') {
        				error("${tcList} failed due to CI problems: ${jobResult}")
        			}
		}
	}
}

def tenvPrepare(label) {
	def buildResults = [:]
	def jobResult = ""
	stage("$label:Preps") {
    	script {
    		echo "Running preparation steps"
    		def jobBuild = build job: "${tenvprepare_job}", parameters: 
    				[[$class: 'NodeParameterValue', name: 'NODE_NAME', labels: ["$label"], nodeEligibility: [$class: 'AllNodeEligibility']], 
    				[$class: 'StringParameterValue', name: 'TCList', value: "${tcList}"], 
    				[$class: 'StringParameterValue', name: 'SW_Revision', value: "${Revision}"],
    				[$class: 'StringParameterValue', name: 'Branch', value: "${Branch}"]]
            		jobResult = jobBuild.getResult()
            		echo "Build of ${tenvprepare_job} returned result: ${jobResult}"
            		buildResults["${tenvprepare_job}"] = jobResult
            			if (jobResult != 'SUCCESS') {
            				error("${tcList} failed due to CI problems: ${jobResult}")
            			}    				
    	}
	}
	return jobResult
}
