@istest
private class RecordOwnerManagement_HANDLER_TEST 
{
    @istest (seealldata = false)
    static void TestTrigger()
    {
        Account a = TestObjectCreator.CreateAccount();
        insert a;
        
        Records_Owner_Management__c rom = TestObjectCreator.Createrom();
        rom.account__c = a.id;
        insert rom;
    }

}