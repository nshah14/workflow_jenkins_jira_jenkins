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

    def createJson(name, value ){
        def jsonSlurper = new JsonSlurper()
        def object = jsonSlurper.parseText('{ "name": '+value'} } ')
        println('Object '+object)
    }

return this