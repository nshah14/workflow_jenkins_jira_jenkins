#!/usr/bin/env groovy
def validate
node {
    checkout scm
    def rootDir = pwd()
    println("Current Directory: " + rootDir)
    props = readProperties file:'dev.txt'
     validate = load "${rootDir}/validate.groovy"  
    NOCHANGE_STATUS=props['NOCHANGE_STATUS']
    IN_PROGRESS_ID=props['IN_PROGRESS_ID']
    TO_DO_ID=props['TO_DO_ID']
    DEPLOY_TO_TEST_ID =props['DEPLOY_TO_TEST_ID']
    DEVELOPMENT_COMPLETE_ID=props['DEVELOPMENT_COMPLETE']
    PROJECT=props['PROJECT']
    SITE=props['SITE']
    IN_PROGRESS_KEY=props['IN_PROGRESS_KEY']
    TO_DO_KEY=props['TO_DO_KEY']
    ISSUE_TYPE_TASK=props['ISSUE_TYPE_TASK']
     credential='credentialsJira'
    PARENT_ISSUE_TYPE=props['PARENT_ISSUE_TYPE']
    PARENT_ISSUE_RELATE=props['PARENT_ISSUE_RELATE']
    PARENT_ISSUE_STATUS=props['PARENT_ISSUE_STATUS']    
    JIRA_BASE_URL=props['JIRA_BASE_URL']
    JIRA_REST_EXT=props['JIRA_REST_EXT']
    ISSUE_TYPE_EPIC= props['ISSUE_TYPE_EPIC']
    PARENT_ISSUE_STATUS_DEV_COMP=props['PARENT_ISSUE_STATUS_DEV_COMP']
    PARENT_ISSUE_STATUS_IN_PRO=props['PARENT_ISSUE_STATUS_IN_PRO']
}
pipeline {
   agent any
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
                def write_json = validate.generateJson("poa-bal", "21.2")
                // writeJSON file: 'output.json', json: write_json, pretty: 4
                // json "release": write_json
                // def file = new File("$WORKSPACE/release.json")
                // file.write(groovy.json.JsonOutput.prettyPrint(json.toString()))

                def data = readJSON text: '{}'
                data.release = "${write_json}" as String
                writeJSON(file: 'release.json', json: data)
                

                // zip zipFile: 'output_version's
                echo "issue array size  is "+links.size()
                for (i = 0; i <links.size(); i++) {  
                    echo "link issue "+links[i].key
                    def key = links[i].key
                    setTransitions(DEPLOY_TO_TEST_ID, key)
                    // http://62.60.42.37:8080/rest/api/2/issue/PS-5?fields=customfield_10306
                    // http://62.60.42.37:8080/rest/api/2/issue/PS-5?fields=customfield_10305
                    // Check field version

                    def link_issue_artifact_version = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "${JIRA_BASE_URL}${JIRA_REST_EXT}issue/${key}?fields=customfield_10306"
                    def link_issue_artifact_name = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "${JIRA_BASE_URL}${JIRA_REST_EXT}issue/${key}?fields=customfield_10305"
                    def link_issue_artifact_version_json = readJSON text: link_issue_artifact_version.content
                    def link_issue_artifact_name_json = readJSON text: link_issue_artifact_name.content
                    println(' artifact name :: '+link_issue_artifact_name_json.fields.customfield_10305)
                    println(' artifact version :: '+link_issue_artifact_version_json.fields.customfield_10306)

                    def link_issue_response = httpRequest authentication: 'credentialsJira', contentType : "APPLICATION_JSON", url: "${JIRA_BASE_URL}${JIRA_REST_EXT}issue/${key}?fields=issuelinks"
                    def link_res_json = readJSON text: link_issue_response.content
                    for(count = 0; count < link_res_json.fields.issuelinks.size(); count++)
                    {
                        println("---------------${count}--------------------")
                        def link = link_res_json.fields.issuelinks[count]
                        
                        def issue_link_name =link.type.name
                        println(' outwardIssue link  type  :'+issue_link_name)
                        def issue_status = link.outwardIssue.fields.status.name
                        println(' status of outwardIssue :'+issue_status)
                        def issue_type = link.outwardIssue.fields.issuetype.name
                        println(' type of outwardIssue :'+issue_type)
                        def issue_key = link.outwardIssue.key
                        println(' link outwardIssue issue key :'+issue_key)
                        println('PARENT_ISSUE_TYPE '+PARENT_ISSUE_TYPE)
                        println('PARENT_ISSUE_RELATE '+PARENT_ISSUE_RELATE)
                        println('PARENT_ISSUE_STATUS '+PARENT_ISSUE_STATUS)
                        if(ISSUE_TYPE_TASK == issue_type )
                        {
                            println ( "met all conditions ")
                            validate.setTransitions(DEPLOY_TO_TEST_ID, issue_key, SITE)
                            break;
                        }
                    }
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
                            emailext to:"navedshah@sbcons.net",
                            subject:"SUCCESS: ${currentBuild.fullDisplayName} and deployed build  ${JIRA_ISSUE_ATT}",
                            body: "Yay, we passedand deployed ${JIRA_ISSUE_ATT} You got mail from pipeline, How you doing? its beer time..."
                }
                failure {
                            emailext to:"navedshah@sbcons.net", 
                            subject:"FAILURE: ${currentBuild.fullDisplayName}", 
                            body: "Boo, we failed."
                }
                unstable {
                            emailext to:"navedshah@sbcons.net", 
                            subject:"UNSTABLE: ${currentBuild.fullDisplayName}", 
                            body: "Huh, we're unstable."
                }
                changed {
                            emailext to:"navedshah@sbcons.net", 
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
