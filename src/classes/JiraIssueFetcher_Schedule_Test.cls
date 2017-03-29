/*------------------------------------------------------------
Author:        Johan Neidenmark (jneidenmark@salesforce.com)
Company:       Salesforce
Description:   Test class for the scheduler
Test Class:    JiraIntegration_Schedule_Test
History
2017-03-08      Johan Neidenmark     Initial Version
------------------------------------------------------------*/
@isTest
public class JiraIssueFetcher_Schedule_Test {

    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   TestMethod to fire the scheduler
	Inputs:        
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    public testMethod static void TestSchedule() {
        JiraIssueFetcher_Schedule sch = new JiraIssueFetcher_Schedule();
        Test.startTest();
        System.schedule('JiraIssueFetcher_Schedule_Test', '0 0 23 * * ?', sch);
        Test.stopTest();
    }
}