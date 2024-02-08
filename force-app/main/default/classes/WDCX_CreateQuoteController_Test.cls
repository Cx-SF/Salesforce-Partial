/*
* Test class for: WDCX_CreateQuoteController Apex Class
*/
@isTest //(seeAllData = true )
public class WDCX_CreateQuoteController_Test {
    @IsTest
    public static void TestSuccessScenario()
    {
		
        RecordType oppRT = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType 
                            WHERE DeveloperName = 'Standard_Opportunity'];
        
        Account testAccount = new Account( Name = 'testAccount', Ongoing_screening_account__c = true ,BillingCountry = 'Italy');
        insert testAccount;
        
        List<Contact> contactsList = new List<Contact>();
        
        Contact contactTest1 = new Contact( LastName = 'conactTest1', MailingCountry = 'Israel', AccountId = testAccount.Id, Email='testSuperUniqueEmail34598634985recv63@mailtestSuperUniqueImpossibletorepeat.com');
        Contact contactTest2 = new Contact( LastName = 'conactTest2', MailingCountry = 'Israel', AccountId = testAccount.Id, Email='testSuperUniqueEmailojbnntung49ugfd93@mailtestSuperUniqueImpossibletorepeat.com');
        contactsList.add(contactTest1);
        contactsList.add(contactTest2);
        Insert contactsList;
        
        List<Opportunity> listOpp = new List<Opportunity>();
        Opportunity opp = new Opportunity(Name = 'TestOpp',StageName = 'Stage zero',CloseDate = Date.today().addDays(5),  
                                          RecordTypeId = oppRT.Id, Primary_Contact__c = contactTest1.Id , forecastCategoryName = 'Commit' , Pricebook2id = CPQ_Settings__c.getInstance().GlobalPriceBookId__c 
                                         , accountId = testAccount.id);
        insert Opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = true,
                                                  SBQQ__Account__c = testAccount.Id
                                                  //WDCX_Shipping_Contact__c = contactTest1.Id,
                                                  //WDCX_Billing_Contact__c = contactTest2.Id
                                                  );
        insert quote;
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        //Test.StartTest(); 
        
        Test.setCurrentPage(Page.WDCX_CreateQuote_VFP); 
        ApexPages.currentPage().getParameters().put('Id', Opp.Id);      
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(quoteList);          
        WDCX_CreateQuoteController con = new WDCX_CreateQuoteController(sc);
        con.quoteCU = new SBQQ__Quote__c();
        con.textDis = '';
        con.createAndRedirect();
        CON.Approve();
        //Test.StopTest();   
    }
    @IsTest
    public static void TestFailedScenario()
    {
        RecordType oppRT = [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType 
                            WHERE DeveloperName = 'Standard_Opportunity'];
        
        Account testAccount = new Account( Name = 'testAccount', Ongoing_screening_account__c = true ,BillingCountry = 'Italy');
        insert testAccount;
        
        Contact contactTest1 = new Contact( LastName = 'conactTest1', MailingCountry = 'Israel', AccountId = testAccount.Id, Email='testSuperUniqueEmail34598634985recv63@mailtestSuperUniqueImpossibletorepeat.com');
        Insert contactTest1;

        Opportunity opp = new Opportunity(Name = 'TestOpp',StageName = 'Stage zero',CloseDate = Date.today().addDays(5),  
                                          RecordTypeId = oppRT.Id, Primary_Contact__c = contactTest1.Id , forecastCategoryName = 'Commit' , Pricebook2id = CPQ_Settings__c.getInstance().GlobalPriceBookId__c 
                                         , accountId = testAccount.id,Probability = 0);
        insert Opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = true,
                                                  SBQQ__Account__c = testAccount.Id
                                                  );
        insert quote;
        
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();

    
        //Test.startTest();
            Test.setCurrentPage(Page.WDCX_CreateQuote_VFP); 
            ApexPages.currentPage().getParameters().put('Id', Opp.Id);      
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(quoteList);          
            WDCX_CreateQuoteController con = new WDCX_CreateQuoteController(sc);
            con.createAndRedirect();
            //WDCX_CreateQuoteController controller = new WDCX_CreateQuoteController(new ApexPages.StandardSetController(new List<SBQQ__Quote__c>()));
        // Call the createAndRedirect method
            //PageReference resultPageRef = controller.createAndRedirect();
        // Assert that the PageReference is null
            //System.assertEquals(System.PageReference, resultPageRef);
        //Test.stopTest();
    }

    
}