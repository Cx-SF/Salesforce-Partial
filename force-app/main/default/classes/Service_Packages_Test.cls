@isTest 
private class Service_Packages_Test {
    static testMethod void TestFunction() {
    
        account accTest = new account (name = 'Test');
        insert accTest;
        Product2 ProducTest = new Product2(name = 'TestProd', WDCX_IncludeForServiceCharge__c = true);
        insert ProducTest;
        Opportunity opptest = new Opportunity(name = 'opptest' , Accountid = accTest.id , StageName = 'Prospecting', CloseDate = date.today() + 20 );
        insert opptest;
        SBQQ__Quote__c quoteTest = new SBQQ__Quote__c (SBQQ__Account__c = accTest.id , SBQQ__Primary__c = false);
        insert quoteTest;
        Asset assTest = new Asset(AccountId  = accTest.id , name = 'TestaSS', Product2id = ProducTest.id , Quantity = 5 , price = 100);
        insert assTest;
        Contract conTest = new Contract(Accountid = accTest.id , Status = 'Draft' , SBQQ__Opportunity__c = opptest.id,
                                        ContractTerm = 20,  StartDate = date.today());
        insert conTest;
        SBQQ__Subscription__c SubscriptionTest = new SBQQ__Subscription__c(SBQQ__Account__c  = accTest.id , SBQQ__Product__c = ProducTest.id , SBQQ__Quantity__c = 5 ,
                                                                           SBQQ__NetPrice__c = 100 , SBQQ__ProrateMultiplier__c = 10 , SBQQ__ListPrice__c = 100
                                                                          ,SBQQ__Contract__c = conTest.id );
        insert SubscriptionTest;
        SBQQ__QuoteLine__c qlTest = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quoteTest.id, SBQQ__Quantity__c =3,SBQQ__Product__c = ProducTest.id , SBQQ__ProrateMultiplier__c = 1, SBQQ__NetPrice__c= 10  ); 
        insert qlTest;
        Test.StartTest(); 
        PageReference pageRef = Page.Service_Packages_view;
        pageRef.getParameters().put('id', quoteTest.Id);
        Test.setCurrentPage(pageRef);
		//ApexPages.StandardController sc = new ApexPages.StandardController();
        Service_Packages_Controller Service_Packages = new Service_Packages_Controller();
        Service_Packages.SaveRollUp();
       	
		Test.StopTest();
    }

}