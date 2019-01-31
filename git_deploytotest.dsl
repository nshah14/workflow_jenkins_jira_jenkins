node {
    checkout scm
    props = readProperties file:'dev.txt'
    NOCHANGE_STATUS=props['NOCHANGE_STATUS']
    IN_PROGRESS_ID=props['IN_PROGRESS_ID']
    TO_DO_ID=props['TO_DO_ID']
    DEPLOY_TO_TEST_ID =props['DEPLOY_TO_TEST_ID']
    DEVELOPMENT_COMPLETE_ID=props['DEVELOPMENT_COMPLETE']
    PROJECT=props['PROJECT']
    SITE=props['SITE']
    IN_PROGRESS_KEY=props['IN_PROGRESS_KEY']
    TO_DO_KEY=props['TO_DO_KEY']
}
pipeline {
   agent { label 'build' }
   environment {
       EXCEPTION="NONE"
    }
   stages{
       stage('Intialize'){
           steps{
               
               script{
                echo "Deployed to ${JIRA_ISSUE_ATT}"
                echo "issue key is ${JIRA_ISSUE_KEY}"
                
                def fixversion = JIRA_ISSUE_ATT
                echo " version is "+fixversion

                echo "print environemnts "+JIRA_TEST_ENVS
               }
            }
      
       }
    stage('Deploy To Environemnts') {
            steps{
                script{
                    try{

                        running_set = [
                                        "Test-1": {
                                            Test_1()
                                        },
                                        "Test-2": {
                                            Test_2()
                                        },
                                        "Test-3":{
                                            Test_3()
                                        }
                                    ]

                        def actual_set = [:]
                        def tests = JIRA_TEST_ENVS.split(',')
                        "${JIRA_TEST_ENVS}".tokenize(",").each {
                                echo "For "+it
                                echo "from running_set" + running_set[it.replaceAll("\\s","")]
                                actual_set.put(it, running_set[it.replaceAll("\\s","")])
                                    
                                }
                            echo "Actual set "+actual_set
                        parallel(actual_set)
                        //(To test failure condition)throw Exception
                    }
                    catch(Exception e){
                        echo "build is been interrupted and exception is caught"
                        EXCEPTION = "SOME"
                    }
                    
                }
                
            }
        }

    stage('Jira Update'){
        steps{
            script{
                if(EXCEPTION == "SOME")
                {
                    echo "rethrow exception here"
                    /*
                    def transitions = jiraGetIssueTransitions idOrKey: JIRA_ISSUE_KEY, site: "${SITE}"
                    echo "data ::::: " +transitions.data.toString()
                    def transitionInput = [ transition: [ id: '91'] ]
                    jiraTransitionIssue idOrKey: JIRA_ISSUE_KEY, input: transitionInput, site: "${SITE}"
                    transitionInput = [ transition: [ id: '21'] ]
                    jiraTransitionIssue idOrKey: JIRA_ISSUE_KEY, input: transitionInput, site: "${SITE}"
                    transitionInput = [ transition: [ id: '61'] ]
                    jiraTransitionIssue idOrKey: JIRA_ISSUE_KEY, input: transitionInput, site: "${SITE}"
                    */
                    setTransitions(TO_DO_ID, JIRA_ISSUE_KEY)
                    setTransitions(IN_PROGRESS_ID, JIRA_ISSUE_KEY)
                    setTransitions(DEVELOPMENT_COMPLETE_ID, JIRA_ISSUE_KEY)
                    throw Exception
                }
                // check status of user story 
                echo "issue key is ${JIRA_ISSUE_KEY}"
                def linked_issues = jiraJqlSearch jql:"project =  ${PROJECT} AND issue in linkedIssues(${JIRA_ISSUE_KEY})",site: "${SITE}"
                echo "issues "+linked_issues
                def links = linked_issues.data.issues
                echo "links "+linked_issues.data.issues
                
                echo "issue array size  is "+links.size()
                for (i = 0; i <links.size(); i++) {  
                    echo "link issue "+links[i].key
                    def key = links[i].key
                    setTransitions(DEPLOY_TO_TEST_ID, key)
                    /*
                    def transitions = jiraGetIssueTransitions idOrKey: key, site: "${SITE}"
                    echo "data ::::: " +transitions.data.toString()
                    def transitionInput = [ transition: [ id: '31'] ]
                    jiraTransitionIssue idOrKey: key, input: transitionInput, site: 'JIRA'
                    */
                }
               
            }
        }
    }
       stage("Mail"){
            steps{
                script{
                    echo "Deployed to ${JIRA_ISSUE_ATT}"
                    echo "issue key is ${JIRA_ISSUE_KEY}"
                    echo "print environemnts "+JIRA_TEST_ENVS
               }
            }
            
            post {
                success {
                            emailext to:"naved.shah@uk.fujitsu.com,steve.aston@fujitsu.co.uk",
                            subject:"SUCCESS: ${currentBuild.fullDisplayName} and deployed build  ${JIRA_ISSUE_ATT}",
                            body: "Yay, we passedand deployed ${JIRA_ISSUE_ATT} You got mail from pipeline, How you doing? its beer time..."
                }
                failure {
                            emailext to:"naved.shah@uk.fujitsu.com,steve.aston@fujitsu.co.uk", 
                            subject:"FAILURE: ${currentBuild.fullDisplayName}", 
                            body: "Boo, we failed."
                }
                unstable {
                            emailext to:"naved.shah@uk.fujitsu.com,steve.aston@fujitsu.co.uk", 
                            subject:"UNSTABLE: ${currentBuild.fullDisplayName}", 
                            body: "Huh, we're unstable."
                }
                changed {
                            emailext to:"naved.shah@uk.fujitsu.com,steve.aston@fujitsu.co.uk", 
                            subject:"CHANGED: ${currentBuild.fullDisplayName}", 
                            body: "Wow, our status changed! we green now ... "
                }
            }
            
       }

    }
}

def Test_1() {
    echo 'Deploy in Test environement 1'
}

def Test_2() {
    echo 'Deploy in Test environement 2'
}

def Test_3() {
    echo 'Deploy in Test environement 3'
}
def setTransitions(transId, key)
{
    echo 'Set transition to allocated status'
   
    echo "link issue "+key
    def transitions = jiraGetIssueTransitions idOrKey: key, site: "${SITE}"
    def transitionInput = [ transition: [ id: transId ] ]
    jiraTransitionIssue idOrKey: key, input: transitionInput, site: "${SITE}"

}
