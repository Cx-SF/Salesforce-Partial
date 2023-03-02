public class CaseCloneControllerV2 {

/******************************************************************************
$Id: $
$Header: $

Controller for CloneCaseV2 VF page
Implements page detail Clone Case button

Change History:
Name            Date            Comments
---------------------------------------------------
Alex Levchenko  07-Mat-2019     Initial version

*******************************************************************************/
    
    public Case originalCase;
    transient public Case newCase {get; set;}
    transient public String isCaseClosed {get; set;}

    public CaseCloneControllerV2(ApexPages.StandardController stdController) {
        this.originalCase = (Case)stdController.getRecord();
        init();
    }
    
    private void init() {
        Case c = [Select Status From Case Where Id = :this.originalCase.Id];
        this.isCaseClosed = (c.Status == 'Closed') ? 'Y' : 'N';
        if (!(this.isCaseClosed == 'Y')) {
            System.debug('Case is not closed - adding error message...');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'You cannot clone open cases'));
        } else {
            cloneOriginalCase();
        }
    }
    
    public PageReference returnToOriginalCase()
    {
        return new ApexPages.StandardController(this.originalCase).view();
    }
    
    private void cloneOriginalCase() {
        Case caseData = [Select CaseNumber,
                                RecordTypeId,
                                Assigned_To__c,
                                Assigned_group__c,
                                AccountId, 
                                ContactId, 
                                Product_area__c,
                                Access_Management_Protocol__c,
                                Languages__c,
                                Source_Repository__c,
                                IDE_Plugin__c,
                                Plugin_Version__c,
                                Build_Server_Plugin__c,
                                System_Integrating__c,
                                Case_Type__c,
                                Outcome__c,
                                Component__c,
                                Solved_by__c,
                                Sub_component__c,
                                Number_of_webex__c,
                                Ticket_Quality__c,
                                IsEscalated,
                                Bug_number__c,
                                Hotfix__c,
                                Deployment__c,
                                Fix_target_version__c,
                                Priority,
                                cc__c,
                                External_ticket__c,
                                Trello_Link__c,
                                POC__c,
                                Origin,
                                Subject,
                                Released_in_Version__c,
                                Description,
                                AssetId,
                                BusinessHoursId,
                                SourceId,
                                Related_Case__c,
                                CommunityId,
                                SuppliedCompany,
                         		Version__c
                           From Case 
                          Where Id = :this.originalCase.Id][0];

        Group g = [select Id From Group Where Name = 'Tier 2' and type = 'Queue'][0];
        
        this.newCase = new Case();
        
        this.newCase.Status = 'New';
        this.newCase.OwnerId = g.Id;
        this.newCase.FollowUpCaseId__c = this.originalCase.Id;

        this.newCase.RecordTypeId = caseData.RecordTypeId;
        this.newCase.AccountId = caseData.AccountId;
        this.newCase.ContactId = caseData.ContactId;
        this.newCase.Product_area__c = caseData.Product_area__c;
        this.newCase.Access_Management_Protocol__c = caseData.Access_Management_Protocol__c;
        this.newCase.Languages__c = caseData.Languages__c;
        this.newCase.Source_Repository__c = caseData.Source_Repository__c;
        this.newCase.IDE_Plugin__c = caseData.IDE_Plugin__c;
        this.newCase.Plugin_Version__c = caseData.Plugin_Version__c;
        this.newCase.Build_Server_Plugin__c = caseData.Build_Server_Plugin__c;
        this.newCase.System_Integrating__c = caseData.System_Integrating__c;
        this.newCase.Case_Type__c = caseData.Case_Type__c;
        this.newCase.Outcome__c = caseData.Outcome__c;
        this.newCase.Component__c = caseData.Component__c;
        this.newCase.Solved_by__c = caseData.Solved_by__c;
        this.newCase.Sub_component__c = caseData.Sub_component__c;
        this.newCase.Number_of_webex__c = caseData.Number_of_webex__c;
        this.newCase.Ticket_Quality__c = caseData.Ticket_Quality__c;
        this.newCase.IsEscalated = caseData.IsEscalated;
        this.newCase.Assigned_group__c = caseData.Assigned_group__c;
        this.newCase.Bug_number__c = caseData.Bug_number__c;
        this.newCase.Hotfix__c = caseData.Hotfix__c;
        this.newCase.Deployment__c = caseData.Deployment__c;
        this.newCase.Fix_target_version__c = caseData.Fix_target_version__c;
        this.newCase.Priority = caseData.Priority;
        this.newCase.cc__c = caseData.cc__c;
        this.newCase.External_ticket__c = caseData.External_ticket__c;
        this.newCase.Trello_Link__c = caseData.Trello_Link__c;
        this.newCase.POC__c = caseData.POC__c;
        this.newCase.Origin = caseData.Origin;
        this.newCase.Subject = 'Follow-up Case #' + caseData.CaseNumber + ' - ' + caseData.Subject;
        this.newCase.Released_in_Version__c = caseData.Released_in_Version__c;
        this.newCase.Description = caseData.Description;
        this.newCase.AssetId = caseData.AssetId;
        this.newCase.BusinessHoursId = caseData.BusinessHoursId;
        this.newCase.SourceId = caseData.SourceId;
        this.newCase.Related_Case__c = caseData.Related_Case__c;
        this.newCase.CommunityId = caseData.CommunityId;
        this.newCase.SuppliedCompany = caseData.SuppliedCompany;
        this.newCase.Version__c = caseData.Version__c;
        
        //insert this.newCase;
    }
    
}