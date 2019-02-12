#!/usr/bin/env groovy
import groovy.json.JsonSlurperClassic
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
    credential='credentialsJira'
    PARENT_ISSUE_TYPE=['PARENT_ISSUE_TYPE']
    PARENT_ISSUE_RELATE=['PARENT_ISSUE_RELATE']
    PARENT_ISSUE_STATUS=['PARENT_ISSUE_STATUS']    
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
                                // def res = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "http://62.60.42.37:8080/rest/api/2/issue/PS-2?fields=status"
                                // println('Status: '+res.status)
                                // println('Response: '+res.content)
                                // println('jira status :'+res)
                                // def myObject = readJSON text: res.content
                                // echo "data"+myObject.fields.status.name
                                if(validate.checkStatus(TO_DO_KEY, "http://62.60.42.37:8080/rest/api/2/issue/PS-2?fields=status", credential))
                                {
                                    validate.setTransitions(IN_PROGRESS_ID, links[i].key, SITE)
                                    //check linked issues
                                    
                                    def link_issue_response = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "http://62.60.42.37:8080/rest/api/2/issue/PS-5?fields=issuelinks"
                                    def link_res_json = readJSON text: link_issue_response.content
                                    for(count = 0; count < link_res_json.fields.issuelinks.size(); count++)
                                    {
                                        println("---------------${count}--------------------")
                                        def link = link_res_json.fields.issuelinks[count]
                                        println(' outwardIssue link  type  :'+link.type.name)
                                        def issue_link_name =link.type.name
                                        println(' status of outwardIssue :'+link.outwardIssue.fields.status.name)
                                        def issue_status = link.outwardIssue.fields.status.name
                                        println(' type of outwardIssue :'+link.outwardIssue.fields.issuetype.name)
                                        def issue_type = link.outwardIssue.fields.issuetype.name
                                        println(' link outwardIssue issue key :'+link.outwardIssue.key)
                                        def issue_key = link.outwardIssue.key
                                        if(PARENT_ISSUE_TYPE == issue_type && PARENT_ISSUE_RELATE == issue_link_name && PARENT_ISSUE_STATUS == issue_status)
                                        {
                                            println ( "met all conditions ")
                                            validate.setTransitions(IN_PROGRESS_ID, issue_key, SITE)
                                            break;
                                        }
                                    }
                                    
                                }
                                else
                                {
                                    echo "parent is already moved in "
                                }
                                
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