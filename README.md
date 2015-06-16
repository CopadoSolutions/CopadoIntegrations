# Copado Integrations
Easily integrate your external project management system with Copado.  This repository will hold the base layer of the integration code that may be extended by the community.

The latest version supports JIRA and Version One.

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
To install the application clic

# Customisation
In order to customise the the mappings for the fields being retrieved, you will need to search for the section in the code labelled, "FIELD MAPPINGS"


