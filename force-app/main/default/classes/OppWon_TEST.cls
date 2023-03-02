@isTest 
private class OppWon_TEST {

    @isTest
    private static void testName() {
        Utils.CodeOff = true;
        Account a = TestObjectCreator.CreateAccount();
        a.CSM__c = UserInfo.getUserId();
        insert a;

        Utils.CodeOff = true;
        Opportunity o = TestObjectCreator.CreateOpportunity(a);
        o.Run_opportunity_batch_process__c = true;
        insert o;

        CSM_Table_Assignment__c ta = TestObjectCreator.CreateCSMTableAssignment();
        insert ta;

        String CRON_EXP = '0 0 0 3 9 ? 2035';
        OppWon_SCHEDULE scdl = new OppWon_SCHEDULE();
        System.schedule('test', CRON_EXP, scdl);

        Set <Id> setId = new Set <Id>(new List <Id> { o.Id });

        OppWon_BATCH theBatch = new OppWon_BATCH();
        theBatch = new OppWon_BATCH(setId, 1, true);
        Id jobId = Database.executeBatch(theBatch);

    }
}