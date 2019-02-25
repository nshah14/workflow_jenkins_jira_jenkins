import groovy.json.JsonBuilder
import groovy.json.JsonSlurper
    def setTransitions(transId, key, site)
    {
        echo 'Set transition to allocated status'
        echo "link issue "+key
        def transitions = jiraGetIssueTransitions idOrKey: key, site: site
        def transitionInput = [ transition: [ id: transId ] ]
        jiraTransitionIssue idOrKey: key, input: transitionInput, site: site

    }
    def rollback( JIRA_ISSUE_KEY, STATUS, SITE, PROJECT, BACK) {

        def obj_rollback_issues = jiraJqlSearch jql:"project = ${PROJECT} AND issue = ${JIRA_ISSUE_KEY} AND status = '${STATUS}'",site: "${SITE}"
        def listOfRollbackIssues = obj_rollback_issues.data.issues
        echo " size of the array which has rollback issue"+listOfRollbackIssues.size()
        for (i = 0; i <listOfRollbackIssues.size(); i++) { 
            setTransitions(BACK, listOfRollbackIssues[i].key, SITE)
        }
    }
    def printSomething()
    {
        echo 'Its printing'
    }

    def checkStatus(exp_status, jira_url, credential)
    {
            // def res = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "http://62.60.42.37:8080/rest/api/2/issue/PS-2?fields=status"
            def res = httpRequest authentication: credential, contentType : "APPLICATION_JSON", url: jira_url
            println('Status: '+res.status)
            println('Response: '+res.content)
            println('jira status :'+res)
            def json = readJSON text: res.content
            echo "data"+json.fields.status.name
            if(exp_status == json.fields.status.name )
            {
                return true
            }
            else
            {
                return false

            }
    }
    def generateJson(name, value){
        def json_string = """{ 

        "name": "${name}",
        "version": "${value}",
        "artifacts":
        [
            {
                "artifact_name": "abcd",
                "artifact_version": 12.2
            },
            {
                "artifact_name": "xyz",
                "artifact_version": 12.2
            },
            {
                "artifact_name": "efgh",
                "artifact_version": 12.2
            }
        ]

            } """

            println('**********************JSON***************************'+json_string)
        return json_string
    }

    def createJson(name, value ){
        def jsonSlurper = new JsonSlurper()
        def slurpe_object = jsonSlurper.parseText("""{ 

        "release": "${name}",
        "version": "${value}",
        "artifacts":
        [
            {
                "artifact_name": "abcd",
                "artifact_version": 12.2
            },
            {
                "artifact_name": "xyz",
                "artifact_version": 12.2
            },
            {
                "artifact_name": "efgh",
                "artifact_version": 12.2
            }
        ]

            } """)
        println('Object '+slurpe_object)
        def builder = new JsonBuilder(slurpe_object)
         println('*********************************builder***************************************'+builder)
        return slurpe_object
    }

return this