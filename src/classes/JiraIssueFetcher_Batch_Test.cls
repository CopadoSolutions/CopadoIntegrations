/*------------------------------------------------------------
Author:        Johan Neidenmark (jneidenmark@salesforce.com)
Company:       Salesforce
Description:   Test class for testing the JIRA fetcher
History
2017-03-08      Johan Neidenmark     Initial Version
------------------------------------------------------------*/
@isTest
public class JiraIssueFetcher_Batch_Test  {

    @testSetup static void Setup() {
        
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
        User u = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
             LastName = 'last',
             Email = 'user.has.access@example.com',
             Username = 'user.has.access@example.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = r.Id
        );
        insert u;    
        User u2 = new User(
             ProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only'].Id,
             LastName = 'last',
             Email = 'user.has.no.access@example.com',
             Username = 'user.has.no.access@example.com' + System.currentTimeMillis(),
             CompanyName = 'TEST',
             Title = 'title',
             Alias = 'alias2',
             TimeZoneSidKey = 'America/Los_Angeles',
             EmailEncodingKey = 'UTF-8',
             LanguageLocaleKey = 'en_US',
             LocaleSidKey = 'en_US',
             UserRoleId = r.Id
        );
        insert u2; 
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {

            // Create an integration record
            Change_Management_Integration_Credential__c cred = new Change_Management_Integration_Credential__c();
            cred.Name = 'TEST JIRA';
            cred.Authentication_Method__c = 'BASIC';
            cred.Endpoint__c = 'http://dummy.com/';
            cred.External_System__c = 'JIRA';
            cred.Username__c = 'TEST UserName';
            cred.Password__c = 'Test_Password';
            insert cred;
            
            // Create a project
            copado__Project__c proj = new copado__Project__c();
            proj.Name = 'Test Project';
            proj.Change_Management_Integration__c = cred.Id;
            proj.External_Id__c = 'ZZ';
            insert proj;
            
            copado__Project__c proj2 = new copado__Project__c();
            proj2.Name = 'Test Project 2';
            proj2.External_Id__c = 'DC2';
            insert proj2;
            
            ObjectPermissions ucPerm = [SELECT Id, ParentId FROM ObjectPermissions WHERE SObjectType = 'copado__User_Story__c' AND PermissionsRead = true LIMIT 1];
            PermissionSetAssignment ucPSA = new PermissionSetAssignment(PermissionSetId = ucPerm.ParentId, AssigneeId = u.Id);
            insert ucPSA;
            
            copado__Epic__c e = new copado__Epic__c(copado__Epic_Title__c='Test epic', JIRA_Key__c = 'ZZ-1');
            insert e;
            /*ObjectPermissions ePerm = [SELECT Id, ParentId FROM ObjectPermissions WHERE SObjectType = 'copado__Epic__c' AND PermissionsRead = true LIMIT 1];
            PermissionSetAssignment ePSA = new PermissionSetAssignment(PermissionSetId = ePerm.ParentId, AssigneeId = u.Id);
            insert ePSA;*/
        
        }
    }
    @isTest static void FetchEpics_Test() {
        Test.setMock(HttpCalloutMock.class, new JiraIssueFetcher_Batch_Test_HttpMoc());
        copado__Project__c proj = [SELECT Id,Name,Change_Management_Integration__c,External_Id__c from copado__Project__c where Name = 'Test Project'];
        Test.startTest();
        JiraIssueFetcher_Batch b = JiraIssueFetcher_Batch.handleProject(proj);
        b.GetEpicsFromJIRA();
        Test.stopTest();
        Integer countRecords = Database.countQuery('SELECT count() from copado__Epic__c where JIRA_Key__c LIKE \'ZZ-%\'');
        System.assertEquals(6, countRecords);
    }
    
    @isTest static void FetchIssues_Test() {
        Test.setMock(HttpCalloutMock.class, new JiraIssueFetcher_Batch_Test_HttpMoc());
        copado__Project__c proj = [SELECT Id,Name,Change_Management_Integration__c,External_Id__c from copado__Project__c where Name = 'Test Project'];
        Test.startTest();
        JiraIssueFetcher_Batch b = JiraIssueFetcher_Batch.handleProject(proj);
        b.GetIssuesFromJIRA();
        Test.stopTest();
        Integer countRecords = Database.countQuery('SELECT count() from copado__User_Story__c where copado__Project__c = \''+proj.id+'\'');
        System.assertEquals(5, countRecords);
    }
    @isTest static void FetchEpicsNoIntegration_Test() {
        Test.setMock(HttpCalloutMock.class, new JiraIssueFetcher_Batch_Test_HttpMoc());
        List<copado__Project__c> projects = [SELECT Id,Name,Change_Management_Integration__c,External_Id__c from copado__Project__c where Name = 'Test Project 2'];
        System.assertEquals(true, projects != null, 'Project List should not be null');
        System.assertEquals(1, projects.size(), 'We should only have 1 project');
        copado__Project__c proj = projects[0];
        System.assertEquals(true, proj != null, 'Project should not be null');
        Test.startTest();
        JiraIssueFetcher_Batch b = JiraIssueFetcher_Batch.handleProject(proj);
        //b.GetEpicsFromJIRA();
        System.assertEquals(null, b, 'handleProject should return null');
        Test.stopTest();
    }
}