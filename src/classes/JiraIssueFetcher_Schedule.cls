/*------------------------------------------------------------
Author:        Johan Neidenmark (jneidenmark@salesforce.com)
Company:       Salesforce
Description:   This class is just to be able to schedule the JIRA integration
Test Class:    JiraIntegration_Schedule_Test
History
2017-03-08      Johan Neidenmark     Initial Version
------------------------------------------------------------*/
global class JiraIssueFetcher_Schedule implements Schedulable {
    /*------------------------------------------------------------
	Author:        Johan Neidenmark (jneidenmark@salesforce.com)
	Company:       Salesforce
	Description:   Schedule execute method that fires the batch job(s)
	Inputs:        
    
	History
	2017-03-08      Johan Neidenmark     Initial Version
	------------------------------------------------------------*/
    global void execute(SchedulableContext SC) {
      	JiraIssueFetcher_Batch.FetchIssues();
   	}
}