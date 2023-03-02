@isTest
private class AssignedGroupTrackingCloseCaseDFTest {
    @TestSetup
    static void setup() {
        Case testCase = new Case(
                Subject = 'New Case',Assigned_group__c='APAC_EMEA_Tier2_queue'
        );
        insert testCase;
        //System.assertNotEquals(null, testCase.Id, 'Failed to insert testCase');
    }
    
    @IsTest
    static void TestAssignedGroupDataFix() {
        Case[] preCases = [SELECT Id, Subject FROM Case];
        preCases[0].Assigned_group__c = 'Tier_2';
             system.debug(' preCases[0] '+ preCases[0]);
        Case testCase = new Case(
                Subject = 'Newest Case',Assigned_group__c='APAC_EMEA_Tier2_queue'
        );

        Test.startTest();

        insert testCase;
         system.debug(' testCase '+ testCase);
        case_assigned_group_total_time__c total  = new case_assigned_group_total_time__c(Case__c = testCase.Id,Assigned_group__c = 'Tier_2');
        insert total;
        Case_assigned_group_log_time__c log = new Case_assigned_group_log_time__c(case_assigned_group_total_time__c = total.Id,Start_date_time_group__c = DateTime.now());
        insert log;
        case_assigned_group_total_time__c total2  = new case_assigned_group_total_time__c(Case__c = preCases[0].Id,Assigned_group__c = 'Tier_2');
        insert total2;
        Case_assigned_group_log_time__c log2 = new Case_assigned_group_log_time__c(case_assigned_group_total_time__c = total2.Id,Start_date_time_group__c = DateTime.now());
        insert log2;
        update preCases;
system.debug('update preCases[0] '+ preCases[0]);
        preCases[0].Status ='Closed';
        update preCases;
        testCase.Status = 'Closed';
        update testCase;
        list <Case_assigned_group_log_time__c> CaseAssignedGroupLogTime = [select  End_date_time_group__c ,Case_assigned_group_total_time__r.case__r.Id ,Case_assigned_group_total_time__r.case__r.ClosedDate from Case_assigned_group_log_time__c where case_assigned_group_total_time__r.case__r.Status = 'Closed' and Case_assigned_group_total_time__r.case__r.Id = :preCases[0].id];
        CaseAssignedGroupLogTime[0].End_date_time_group__c = null;
        update CaseAssignedGroupLogTime;
        List<Id> casesToProccess = new List<Id>();
		casesToProccess.add(preCases[0].id);
        casesToProccess.add(testCase.id);
		AssignedGroupTrackingCloseCaseDataFix EntBatch = new AssignedGroupTrackingCloseCaseDataFix(null,null);
		string batchId = Database.executeBatch(EntBatch,10);
        AssignedGroupTrackingCloseCaseDataFix EntBatch2 = new AssignedGroupTrackingCloseCaseDataFix(Date.today().addDays(-5),Date.today());
		string batchId2 = Database.executeBatch(EntBatch2,10);
        Test.stopTest();

        List<Case_assigned_group_total_time__c> new_assigned_group_total_time=[select id from Case_assigned_group_total_time__c];
        //System.assertEquals(3, new_assigned_group_total_time.size());
    }
    

}