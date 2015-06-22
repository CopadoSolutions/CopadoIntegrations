@isTest
private class ChangeManagementIntegrationTriggerTest {
	static testMethod void testEncoding(){
		Change_Management_Integration_Credential__c cred = new Change_Management_Integration_Credential__c();
		cred.Name = 'My Credential';
		cred.External_System__c = 'Jira';
		cred.Authentication_Method__c = 'Basic Authentication';
		cred.Username__c = 'MyUsername';
		cred.Password__c = 'MyPassword';
		cred.Endpoint__c = 'http://endpoint.com';

		Test.startTest();
		insert cred;
		Test.stopTest();
		List<Change_Management_Integration_Credential__c> results = [select Id, Name, Password__c from Change_Management_Integration_Credential__c];
		system.assertEquals(1, results.size(), 'Results query returned no results');
		system.assertEquals('TXlQYXNzd29yZA==', results.get(0).Password__c, 'The expected password encoded string did not match.');
	}
}