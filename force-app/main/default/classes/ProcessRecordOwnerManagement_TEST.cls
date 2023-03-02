@istest
private class ProcessRecordOwnerManagement_TEST
{
    @istest (Seealldata = false)
    static void TestBatch()
    {
        Account a = TestObjectCreator.CreateAccount();
        insert a;
        
        Records_Owner_Management__c rom = TestObjectCreator.Createrom();
        rom.account__c = a.id;
        insert rom;
        
        ProcessRecordOwnerManagement_BATCH cls = new ProcessRecordOwnerManagement_BATCH();
        database.executeBatch( cls);
        
        String jobId = System.schedule('ProcessRecordOwnerManagement_SCHEDULETEST', ProcessRecordOwnerManagement_SCHEDULE.CRON_EXP, new ProcessRecordOwnerManagement_SCHEDULE ());

    }

}