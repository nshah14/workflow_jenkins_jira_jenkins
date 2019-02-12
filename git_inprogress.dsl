#!/usr/bin/env groovy
def props
def VERSION
def FIX
def RELEASE
def validate
node {
    checkout scm
    def rootDir = pwd()
    println("Current Directory: " + rootDir)
    validate = load "${rootDir}/validate.groovy"  
    props = readProperties file:'dev.txt'
    NOCHANGE_STATUS=props['NOCHANGE_STATUS']
    IN_PROGRESS_ID=props['IN_PROGRESS_ID']
    TO_DO_ID=props['TO_DO_ID']
    PROJECT=props['PROJECT']
    SITE=props['SITE']
    IN_PROGRESS_KEY=props['IN_PROGRESS_KEY']
    TO_DO_KEY=props['TO_DO_KEY']
}
pipeline {
   agent { label 'build' }
  tools { 
        git 'Git'
        
    }
   stages{
       
     stage('Intialize'){
           steps{
               script{
                echo "issue key is ${JIRA_ISSUE_KEY}"
               }
            }
      
       }
    stage('Check Update'){
        steps{
            script{
                try
                {
                    def fields = jiraGetFields idOrKey: '${JIRA_ISSUE_KEY}', site: "${SITE}"
                    //echo fields.data.toString()
                    echo "issue key is ${JIRA_ISSUE_KEY}"
                    def linked_issues = jiraJqlSearch jql:"project = ${PROJECT} AND issue in linkedIssues(${JIRA_ISSUE_KEY})",site: "${SITE}"
                    def linked_issue_status = jiraJqlSearch jql:"project = ${PROJECT} AND issue in linkedIssues(${JIRA_ISSUE_KEY}) AND status = '${IN_PROGRESS_KEY}'",site: "${SITE}"
                    def issues_with_status = linked_issue_status.data.issues
                    echo " size of the array which has linked issue status"+issues_with_status.size()
                    
                    def links = linked_issues.data.issues
                    echo " size of the array which has linked issue"+links.size()
                   
                    if(links.size() == issues_with_status.size())
                    {
                        echo "all the issues are linked have been already in desired state"
                        NOCHANGE_STATUS = "TRUE"
                    }
                    else{

                        echo "Execute step -- Jira Update To In Progress"
                        
                    }
                }
                catch(error){
                   
                    validate.rollback(JIRA_ISSUE_KEY, IN_PROGRESS_KEY, SITE, PROJECT, TO_DO_ID)
                    throw Exception
                }


        
               
            }
        }
    }
    stage('Jira Update To In Progress'){
    
            steps{
                script{
                    try{
                        if(NOCHANGE_STATUS=="FALSE")
                        {
                        
                            def linked_issues = jiraJqlSearch jql:"project = ${PROJECT} AND issue in linkedIssues(${JIRA_ISSUE_KEY})",site: "${SITE}"
                            def links = linked_issues.data.issues
                            echo "issue array size  is "+links.size()
                            for (i = 0; i <links.size(); i++) {  
                                echo "link issue "+links[i].key
                                echo "current status of the issue "+links[i]
                                echo "****************************************************************************"
                                ///
                                //var urlissue = "http://"+config.user+":"+config.password+"@"+config.host+":"+config.port+config.url+"issue/"+queryBy;
                                //bnNoYWgxNDphZG1pbjEyMw== 
                                // def response = sh 'curl -D- -u *****:**** -X GET -H "Content-Type: application/json" http://62.60.42.37:8080/rest/api/2/issue/PS-2?fields=status'
                                //http://localhost:8080/rest/api/2/issue/
                                def res = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "http://62.60.42.37:8080/rest/api/2/issue/PS-2?fields=status"
                                println('Status: '+res.status)
                                println('Response: '+res.content)
                                println('jira status :'+res.content.fields.status.name)
                                validate.setTransitions(IN_PROGRESS_ID, links[i].key, SITE)
                                
                            }
                        }
                    }
                    catch(error){
                     
                        validate.rollback(JIRA_ISSUE_KEY, IN_PROGRESS_KEY, SITE, PROJECT, TO_DO_ID)
                        throw Exception
                    }
                }
             }
         }
   }
}