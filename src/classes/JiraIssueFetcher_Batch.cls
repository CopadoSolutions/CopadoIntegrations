/*------------------------------------------------------------
Author:        Johan Neidenmark (jneidenmark@salesforce.com)
Company:       Salesforce
Description:   A batch job for integrating JIRA into Copa.do
Test Class:    JiraIntegration_Batch_Test
History
2017-03-08      Johan Neidenmark     Initial Version
------------------------------------------------------------*/
public class JiraIssueFetcher_Batch implements Queueable, Database.AllowsCallouts {
    private Integer startIndex = 0; // Start number of the batch to get from JIRA
    private Integer batchSize = 100; // Number of issues to fetch in each batch
    private Integer total = 50;
    private copado__Project__c project = null; // Copado Change Management project we are working with
    private Change_Management_Integration_Credential__c  cmCredential = null; // Copado credentials for external integration
    private Map<String, Id> usersWithAccess = null; // Local storage of users that has access to Copado User Stories, this to limit the number of DML statements
    private Map<String, Id> epicLinks = null;
    private boolean isEpicFetcher = true;
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   The batch execute method that will be run by the platform when its this instance turn to run
	Inputs:        project - The Copado project to work on with this batch
	                cmCredentials - the integration credentials for this project
	                startIndex - start for the paging of issues
	                batchSize - number of issues to fetch in one batch
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    public JiraIssueFetcher_Batch(copado__Project__c project, Change_Management_Integration_Credential__c cmCredential, Boolean isEpicFetcher, Integer startIndex, Integer batchSize){
        this.project = project;
        this.cmCredential = cmCredential;
        this.isEpicFetcher = isEpicFetcher;
        this.startIndex = startIndex;
        this.batchSize = batchSize;
        this.usersWithAccess = new Map<String, Id>();
        this.epicLinks = new Map<String, Id>();
    }
    
	/*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   The batch execute method that will be run by the platform when its this instance turn to run
	Inputs:        context - The batch context provided by the platform
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
	public void execute(QueueableContext context) {
        if(cmCredential.External_System__c == 'JIRA') {
            System.debug('Fetching issues from JIRA');
            if(isEpicFetcher) {
                GetEpicsFromJIRA();
                if(this.total > (this.startIndex + this.batchSize +1))
                    System.enqueueJob(new JiraIssueFetcher_Batch(this.project, this.cmCredential, true, this.startIndex + this.batchSize, 100));
                else
                    System.enqueueJob(new JiraIssueFetcher_Batch(this.project, this.cmCredential, false, 0, 100));
            } else {
        	    GetIssuesFromJIRA();
    	        if(this.total > (this.startIndex + this.batchSize +1))
                    System.enqueueJob(new JiraIssueFetcher_Batch(project, this.cmCredential, false, this.startIndex + this.batchSize, 100));
    
    	    }
        }
	}
	/*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   Get Epics from JIRA
	
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
	@TestVisible private void GetEpicsFromJIRA() {
	    System.debug('Endpoint: '+cmCredential.Endpoint__c);
        System.debug('Username: '+cmCredential.Username__c);
        //System.debug('Password: '+cmCredential.Password__c+', decoded: '+EncodingUtil.base64Decode(cmCredential.Password__c).toString());
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cmCredential.Endpoint__c+'search?jql=project='+project.External_Id__c+'%20and%20issueType=Epic&startAt='+this.startIndex+'&maxResults='+this.batchSize);
     	req.setMethod('GET');
     
     	Blob headerValue = Blob.valueOf(cmCredential.Username__c + ':' + EncodingUtil.base64Decode(cmCredential.Password__c).toString());
     	String authorizationHeader = 'Basic ' +
     	EncodingUtil.base64Encode(headerValue);
     	req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
   
     	// Create a new http object to send the request object
     	// A response object is generated as a result of the request  
  
     	Http http = new Http();
     	HTTPResponse res = http.send(req);
        System.debug('Response Status:'+res.getStatusCode());
        System.debug('Body len: '+res.getBody().length());
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        total = Integer.valueOf(results.get('total'));
        System.debug('Total number of issues: '+total);
        List<Object> issues = (List<Object>)results.get('issues');
        List<copado__Epic__c> epics = new List<copado__Epic__c>();
        for(Object issue : issues) {
            Map<string,Object> i = (Map<string, object>)issue;
            copado__Epic__c epic = MapJIRAEpic(i);
            if(epic != null)
                epics.add(epic);
        }
        upsert epics External_Id__c;
	}
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   Method that does the call-out to JIRA to fetch Issues
	Inputs:        
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    @TestVisible private void GetIssuesFromJIRA() {
        System.debug('Endpoint: '+cmCredential.Endpoint__c);
        System.debug('Username: '+cmCredential.Username__c);
        //System.debug('Password: '+cmCredential.Password__c+', decoded: '+EncodingUtil.base64Decode(cmCredential.Password__c).toString());
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(cmCredential.Endpoint__c+'search?jql=project='+project.External_Id__c+'%20and%20(issueType=Story%20or%20issueType=Bug%20or%20issueType=Task)&startAt='+this.startIndex+'&maxResults='+this.batchSize);
     	req.setMethod('GET');
     
     	Blob headerValue = Blob.valueOf(cmCredential.Username__c + ':' + EncodingUtil.base64Decode(cmCredential.Password__c).toString());
     	String authorizationHeader = 'Basic ' +
     	EncodingUtil.base64Encode(headerValue);
     	req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
   
     	// Create a new http object to send the request object
     	// A response object is generated as a result of the request  
  
     	Http http = new Http();
     	HTTPResponse res = http.send(req);
        System.debug('Response Status:'+res.getStatusCode());
        System.debug('Body len: '+res.getBody().length());
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        total = Integer.valueOf(results.get('total'));
        System.debug('Total number of issues: '+total);
        List<Object> issues = (List<Object>)results.get('issues');
        List<copado__User_Story__c> userStories = new List<copado__User_Story__c>();
        for(Object issue : issues) {
            Map<string,Object> i = (Map<string, object>)issue;
            copado__User_Story__c story = MapJIRAFields(i);
            if(story != null)
                userStories.add(story);
        }
        upsert userStories External_Id__c;
        
    }
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   The batch execute method that will be run by the platform when its this instance turn to run
	Inputs:        issue - This method maps jira fields to copado User Stories
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    private copado__Epic__c MapJIRAEpic(Map<string, object> issue) {
        copado__Epic__c epic = new copado__Epic__c();
        string key;
        string email;   
        key = (string)issue.get('key');
        epic.JIRA_Key__c = key;
        epic.External_Id__c = (String)issue.get('id');
        //epic.copado__Project__c = this.project.Id;
        if(issue.get('fields') != null) {
            Map<string,object> fields = (Map<string, object>)issue.get('fields');
            // copado__User_Story_Title__c 
            if(fields.get('summary') != null) {
                epic.copado__Epic_Title__c = key + ' - ' + ((string)fields.get('summary'));
            }
            // copado__Status__c
            if(fields.get('status') != null) {
                Map<string, object> status = (Map<string, object>)fields.get('status');
                if(status.get('name') != null)
                    epic.copado__Status__c = (string)status.get('name');
            }
            // copado__Functional_Specifications__c
            if(fields.get('description') != null) {
                epic.copado__Epic_Details__c = (string)fields.get('description');
            }
            
            // Get the assignee of the JIRA ticket and assign the userstory to the corresponding user in salesforce
            if(fields.get('assignee') != null) {
                Map<string, object> assignee = (Map<string, object>)fields.get('assignee');
                if(assignee.get('emailAddress') != null) {
                    email = (string)assignee.get('emailAddress');
                    if(usersWithAccess.containsKey(email)) {
                        Id userId = usersWithAccess.get(email);
                        if(userId != null)
                            epic.OwnerId = userId;
                    } else {
                        List<User> users = [Select id,name from User where email = :email or email = :GetSandboxEmail(email) limit 1];
                        for(User u : users) {
                            Id userId = u.Id;
                            Integer count= database.countQuery('SELECT count() '+
									'FROM PermissionSetAssignment '+
									'WHERE PermissionSetId '+
									'IN (SELECT ParentId '+
									'FROM ObjectPermissions '+
									'WHERE SObjectType = \'copado__Epic__c\' AND '+
									'PermissionsRead = true '+
									') '+
									'AND Assignee.Id = \''+
                                                               userId +'\'');

                        	if(count > 0)
                            {
                                usersWithAccess.put(email, userId);
                                epic.OwnerId = userId;
                                break;
                            } else
                                usersWithAccess.put(email, null);
                        }
                    }
                    
                }
            }
        }
        //system.debug(key+','+sIssueType+','+email);
        return epic;
    }
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   The batch execute method that will be run by the platform when its this instance turn to run
	Inputs:        issue - This method maps jira fields to copado User Stories
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    private copado__User_Story__c MapJIRAFields(Map<string, object> issue) {
        copado__User_Story__c story = new copado__User_Story__c();
        string key;
        string email;   
        string sIssueType;
        key = (string)issue.get('key');
        story.JIRA_Key__c = key;
        story.External_Id__c = (String)issue.get('id');
        story.copado__Project__c = this.project.Id;
        if(issue.get('fields') != null) {
            Map<string,object> fields = (Map<string, object>)issue.get('fields');
            // copado__User_Story_Title__c 
            if(fields.get('summary') != null) {
                story.copado__User_Story_Title__c = key + ' - ' + ((string)fields.get('summary'));
            }
            // copado__Status__c
            if(fields.get('status') != null) {
                Map<string, object> status = (Map<string, object>)fields.get('status');
                if(status.get('name') != null)
                    story.copado__Status__c = (string)status.get('name');
            }
            // copado__Functional_Specifications__c
            if(fields.get('description') != null) {
                story.copado__Functional_Specifications__c = (string)fields.get('description');
            }
            // Get the issue type - were not using this atm
            if(fields.get('issuetype') != null) {
                Map<string, object> issuetype = (Map<string, object>)fields.get('issuetype');
                if(issuetype.get('name') != null) {
                    sIssueType = (string)issuetype.get('name');
                    story.copado__userStory_Role__c = sIssueType;
                }
            }
            // Get the assignee of the JIRA ticket and assign the userstory to the corresponding user in salesforce
            if(fields.get('assignee') != null) {
                Map<string, object> assignee = (Map<string, object>)fields.get('assignee');
                if(assignee.get('emailAddress') != null) {
                    email = (string)assignee.get('emailAddress');
                    if(usersWithAccess.containsKey(email)) {
                        Id userId = usersWithAccess.get(email);
                        if(userId != null)
                            story.OwnerId = userId;
                    } else {
                        List<User> users = [Select id,name from User where email = :email or email = :GetSandboxEmail(email) limit 1];
                        for(User u : users) {
                            Id userId = u.Id;
                            Integer count= database.countQuery('SELECT count() '+
									'FROM PermissionSetAssignment '+
									'WHERE PermissionSetId '+
									'IN (SELECT ParentId '+
									'FROM ObjectPermissions '+
									'WHERE SObjectType = \'copado__User_Story__c\' AND '+
									'PermissionsRead = true '+
									') '+
									'AND Assignee.Id = \''+
                                                               userId +'\'');

                        	if(count > 0)
                            {
                                usersWithAccess.put(email, userId);
                                story.OwnerId = userId;
                                break;
                            } else
                                usersWithAccess.put(email, null);
                        }
                    }
                    
                }
            }
            // Get the epic and create the link to it
            if(fields.get('customfield_10004') != null) {
                // ((string)fields.get('summary'));
                string eKey = (String)fields.get('customfield_10004');
                if(epicLinks.containsKey(eKey)) {
                    Id epicId = epicLinks.get(eKey);
                    if(epicId != null)
                        story.copado__Epic__c = epicId;
                } else {
                    List<copado__Epic__c> results = [SELECT Id from copado__Epic__c where JIRA_Key__c = :eKey];
                    if(results.size() > 0) {
                        Id epicId = results[0].Id;
                        epicLinks.put(eKey, epicId);
                        story.copado__Epic__c = epicId;
                    }
                }
            }
        }
        //if(project.Org_Credential__c != null)
        //    story.copado__Org_Credential__c = project.Org_Credential__c;
        system.debug(key+','+sIssueType+','+email);
        return story;
    }
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   Method that does the call-out to JIRA to fetch Issues
	Inputs:        project - the copado project we will be working with
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    @TestVisible private static JiraIssueFetcher_Batch HandleProject(copado__Project__c project){
        System.debug('Handling project:'+project.Name);
        if(project.Change_Management_Integration__c == null)
        {
            System.debug('No change management integration in project: '+project.Name);
            return null;
        }
        Change_Management_Integration_Credential__c cred = [SELECT Id, Name, Authentication_Method__c, Endpoint__c, External_System__c, Username__c, Password__c 
                                                            from Change_Management_Integration_Credential__c 
                                                            where Id = :project.Change_Management_Integration__c];
        
        return new JiraIssueFetcher_Batch(project, cred, true, 0, 100);
    }
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   Static method that fires off the jira integration
	Inputs:        
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    public static void FetchIssues() {
        List<copado__Project__c> projects = [select Id,Name,Change_Management_Integration__c,External_Id__c from copado__Project__c];
        for(copado__Project__c p : projects){
            JiraIssueFetcher_Batch b = HandleProject(p);
            if(b != null)
                System.enqueueJob(b);
        }
    }
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   Utility method to make an email adress look like they do in a sandbox if we are in a sandbox
	Inputs:        email - normal email address
    Output:         sandbox-ified email adrress if we are in a sandbox
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    private static String GetSandboxEmail(String email) {
        return email.replace('@', '=') + '@example.com';
    }
}