# Copado Integrations
Easily integrate your external project management system with Copado.  This repository will hold the base layer of the integration code that may be extended by the community.

The latest version supports JIRA, VersionOne, Rally, Agile Accelerator, ScrumDo and TargetProcess

# How does it work?
Copado Solutions has built the authentication module as well as the framework for retrieving user stories and inserting these into the Copado sObject called, "User Story".  The mapping is also handled by the integration.  Both the data being queried from the data source as well as the mapping can be modified.  We have commented the code with instructions to help with the customisation process.

The code & all the components are contained in an unmanaged package and available within this repository as a backup.

Installation instructions can be found below.

# What gets imported into Copado?
By default the following fields get imported:
- User Story Title (User_Story_Title__c)
- Status (Status__c)
- Project (Project__c)
- Functional Specifications (Functional_Specifications__c)

# Installation instructions
To install the application use one of the below URLs.
- Production/Developer orgs: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t24000000NgXp
- Sandbox orgs: https://test.salesforce.com/packaging/installPackage.apexp?p0=04t24000000NgXp

# Customisation
In order to customise the mappings for the fields being retrieved, you will need to search for the section in the code labelled, "FIELD MAPPINGS" in the CopadoSyncUserStories Visualforce page.

# Getting started
1) The User Story Status picklist values should match those of your external system.

2) The JIRA remote site setting contains a domain that needs to be changed. 

3) Page layout modifications (see below) 


Once the package is installed, you will need to setup a Change Management Integration Credential.
This is done from the "Change Management Integrations" tab.
- A Jira endpoint might look as follows: https://COMPANY_DOMAIN_NAME.atlassian.net/rest/api/2/
- A VersionOne endpoint might look as follows: https://www9.v1host.com/COMPANY_NAME/
- A Rally endpoint might look as follows: https://rally1.rallydev.com/slm/webservice/v2.0/
- An Agile Accelerator endpoint might look as follows: https://na12.salesforce.com (no ending "/")
- A ScrumDo endpoint might look as follows: https://www.scrumdo.com/api/v2/organizations/ORGANIZATION_SLUG
	- The organization slug can be determined by visiting ScrumDo Dashboard, and looking at the navigator URL
		https://app.scrumdo.com/organization/<ORGANIZATION_SLUG>/dashboard#/overview
	- The project slug can be determined by visiting ScrumDo Board for that project, and looking at the navigator URL
		https://app.scrumdo.com/projects/<PROJECT_SLUG>/board#/view
- A TargetProccess endpoint might look as follows: https://contractor.tpondemand.com. 
- For Agile Accelerator even username and password are required, those fields are not used since current sessionId will be used instead. Please fill any text, such as N/A. Make sure that the Authentincation Method is set to "Authentication Token"
- For Agile Accelerator the Project External Id field is match against the Product tag name so that only Work records for that product tag are imported against the Copado Project. This can be customizable as well.

Once the integration credentials have been setup, you will need to create a new project or edit an existing project and complete the following two fields.

## Page Layout modifications

### Fields
- Change Management Integration - This lookup field looks up the credential you just created.
- External Id - This external Id field needs the Id of the project for which we will import the User Stories.
- Workspace Id - Only relevant for Rally when using workspaces.

### Buttons
- Add button called, "Sync External User Stories" to the project layout.

## Remote Sites Settings
Some Remote Sites settings have been included for your convenience.  The Jira Remote Sites settings currently point to a repository called, "copado-test2".  This will need to be changed.
You may delete the remote sites settings that you will not need.

Once everything is setup, you can press the "Sync External User Stories" button.
