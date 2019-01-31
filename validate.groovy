
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
return this