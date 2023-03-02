@isTest 
private class AssignedGroupTrackingTest {
    @TestSetup
    static void setup() {
        Case testCase = new Case(
                Subject = 'New Case',Assigned_group__c='APAC_EMEA_Tier2_queue'
        );
        insert testCase;
        //System.assertNotEquals(null, testCase.Id, 'Failed to insert testCase');
    }
    
     @IsTest
    static void TestAssignedGroup() {
        Case[] preCases = [SELECT Id, Subject FROM Case];
        preCases[0].Assigned_group__c = 'Tier_2';
             system.debug(' preCases[0] '+ preCases[0]);
        Case testCase = new Case(
                Subject = 'Newest Case',Assigned_group__c='APAC_EMEA_Tier2_queue'
        );

        Test.startTest();

        insert testCase;
         system.debug(' testCase '+ testCase);
        update preCases;
system.debug('update preCases[0] '+ preCases[0]);
        Test.stopTest();

        List<Case_assigned_group_total_time__c> new_assigned_group_total_time=[select id from Case_assigned_group_total_time__c];
        //System.assertEquals(3, new_assigned_group_total_time.size());
    }
    
     
    
}