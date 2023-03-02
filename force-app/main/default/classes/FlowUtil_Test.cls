@isTest
private class FlowUtil_Test 
{
	private static testMethod void doTest() 
    {
        Test.startTest();
        Account acc= new Account(Name='Test FlowUtil class', BillingCountry ='Armenia');
		insert acc;
		
        Contact con = new Contact(LastName='TestFlowUtil', AccountId=acc.Id, MailingCountry='Armenia');
        insert con;
        
		Opportunity opp = new Opportunity(Name='Opp from FlowUtil test', AccountId=acc.Id,
                                          Paying_entity__c = 'End User', Type='New Business',
                                          CloseDate=system.Today(), StageName='Value Proposition',
                                          License_Type__c='Subscription', Customer_Type__c='On Premise'); 
        insert opp;
        
        License__c lic = new License__c(Name='Lic TestFlowUtil', license_Edition__c='SDLC', 
                                        Account__c=acc.Id, Opportunity__c=opp.Id,
                                        Issued_To__c=con.Id, Type__c='Subscription',
                                        HID__c='#123456789', Expiration_Date__c=system.today(),
                                        Number_of_Auditors__c=1, Number_of_Reviewers__c=1, 
                                        Number_of_Scanners__c=1);
        insert lic;

        List<String> idLst = New List<String>();
        idLst.add(lic.Id+';'+opp.Id);
        
        list<string> newlicenseId = FlowUtil.getClonedLicenseId(idLst);

        Test.stopTest();
    }
}