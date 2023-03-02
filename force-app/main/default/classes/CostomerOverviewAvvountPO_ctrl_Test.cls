@isTest 
private class CostomerOverviewAvvountPO_ctrl_Test {

    @isTest
    private static void CostomerOverviewAvvountTest() {

        Account a = TestObjectCreator.CreateAccount();
        a.CSM__c = UserInfo.getUserId();
        insert a;

        Account_Planning__c ap = TestObjectCreator.CreateAccountPlanning(a.id);
        insert ap;

        CostomerOverviewAvvountPO_ctrl.initComponent(ap.Id);

    }
}