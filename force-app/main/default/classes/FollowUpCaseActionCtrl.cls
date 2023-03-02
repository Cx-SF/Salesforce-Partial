public with sharing class FollowUpCaseActionCtrl {
    
    @AuraEnabled
    public static String getStatus(Id caseId) {
        return ([Select Status From Case Where Id = :caseId])[0].Status;
    }
    
    @AuraEnabled
    public static Case cloneCase(Id caseId) {
        String origin = (UserInfo.getUserType() != 'Standard') ? 'Community' : 'Internal_Checkmarx';
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
                                Version__c,
                                //<REM> 26/09/19
                                Actual_Result__c,
                                Client_Name__c,
                                End_Date__c,
                                Expected_Result__c,
                                Internal_Request_Type__c,
                                List_of_IP_Addresses__c,
                                Number_of_machines__c,
                                Propose_meeting_date__c,
                                Category_Query__c,
                                Start_Date__c,
                                Vulnerability__c
                                //</REM>
                           From Case 
                          Where Id = :caseId][0];

        Group g = [select Id From Group Where Name = 'Tier 2' and type = 'Queue'][0];
        
        Case newCase = new Case();
        newCase.Status = 'New';
        //newCase.OwnerId = g.Id;
        newCase.FollowUpCaseId__c = caseId;
        newCase.Origin = origin;
        newCase.RecordTypeId = caseData.RecordTypeId;
        newCase.AccountId = caseData.AccountId;
        newCase.ContactId = caseData.ContactId;
        newCase.Product_area__c = caseData.Product_area__c;
        newCase.Access_Management_Protocol__c = caseData.Access_Management_Protocol__c;
        newCase.Languages__c = caseData.Languages__c;
        newCase.Source_Repository__c = caseData.Source_Repository__c;
        newCase.IDE_Plugin__c = caseData.IDE_Plugin__c;
        newCase.Plugin_Version__c = caseData.Plugin_Version__c;
        newCase.Build_Server_Plugin__c = caseData.Build_Server_Plugin__c;
        newCase.System_Integrating__c = caseData.System_Integrating__c;
        newCase.Case_Type__c = caseData.Case_Type__c;
        //newCase.Outcome__c = caseData.Outcome__c; //<REM> 26/09/19
        //newCase.Component__c = caseData.Component__c; //<REM> 26/09/19
        //newCase.Solved_by__c = caseData.Solved_by__c; //<REM> 26/09/19
        //newCase.Sub_component__c = caseData.Sub_component__c; //<REM> 26/09/19
        //newCase.Number_of_webex__c = caseData.Number_of_webex__c; //<REM> 26/09/19
        //newCase.Ticket_Quality__c = caseData.Ticket_Quality__c; //<REM> 26/09/19
        //newCase.IsEscalated = caseData.IsEscalated; //<REM> 26/09/19
        //newCase.Assigned_group__c = caseData.Assigned_group__c; //<REM> 26/09/19
        //newCase.Bug_number__c = caseData.Bug_number__c; //<REM> 26/09/19
        newCase.Hotfix__c = caseData.Hotfix__c;
        newCase.Deployment__c = caseData.Deployment__c;
        //newCase.Fix_target_version__c = caseData.Fix_target_version__c; //<REM> 26/09/19
        newCase.Priority = caseData.Priority;
        newCase.cc__c = caseData.cc__c;
        newCase.External_ticket__c = caseData.External_ticket__c;
        //newCase.Trello_Link__c = caseData.Trello_Link__c; //<REM> 26/09/19
        newCase.POC__c = caseData.POC__c;
        newCase.Subject = 'Follow-up Case #' + caseData.CaseNumber + ' - ' + caseData.Subject;
        newCase.Released_in_Version__c = caseData.Released_in_Version__c;
        newCase.Description = caseData.Description;
        newCase.AssetId = caseData.AssetId;
        newCase.BusinessHoursId = caseData.BusinessHoursId;
        newCase.SourceId = caseData.SourceId;
        newCase.Related_Case__c = caseData.Related_Case__c;
        newCase.CommunityId = caseData.CommunityId;
        newCase.SuppliedCompany = caseData.SuppliedCompany;
        newCase.Version__c = caseData.Version__c;
        //<REM> 26/09/19
        newCase.Actual_Result__c = caseData.Actual_Result__c;
        newCase.Client_Name__c = caseData.Client_Name__c;
        newCase.End_Date__c = caseData.End_Date__c;
        newCase.Expected_Result__c = caseData.Expected_Result__c;
        newCase.Internal_Request_Type__c = caseData.Internal_Request_Type__c;
        newCase.List_of_IP_Addresses__c = caseData.List_of_IP_Addresses__c;
        newCase.Number_of_machines__c = caseData.Number_of_machines__c;
        newCase.Propose_meeting_date__c = caseData.Propose_meeting_date__c;
        newCase.Category_Query__c = caseData.Category_Query__c;
        newCase.Start_Date__c = caseData.Start_Date__c;
        newCase.Vulnerability__c = caseData.Vulnerability__c;
        //</REM>
        return newCase;
    }
    
}