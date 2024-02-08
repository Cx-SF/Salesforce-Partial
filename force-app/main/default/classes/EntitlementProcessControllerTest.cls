@isTest
public class EntitlementProcessControllerTest {
    
    @testSetup static void setup(){
        Account acc=new Account();
        acc.Name='EntitlementProcessControllerTest_Account';
        insert acc;
        Opportunity opp=new Opportunity();
        opp.AccountId=acc.Id;
        opp.Name='Test opp';
        opp.StageName='Prospecting';
        opp.CloseDate=Date.valueOf('2020-03-16');
        insert opp;
        Contract con=new Contract();
        con.AccountId=acc.Id;
        con.Status='Terminated';
        con.StartDate=system.today().addDays(-2);
        con.ContractTerm=12;
        con.SBQQ__Opportunity__c=opp.id;
        insert con;
        Product2 prod=new Product2();
        prod.Name='Test Product';
        insert prod;
        SBQQ__Subscription__c sub=new SBQQ__Subscription__c();
        sub.SBQQ__Account__c=acc.id;
        sub.SBQQ__Contract__c=con.Id;
        sub.SBQQ__Product__c=prod.id;
        sub.SBQQ__Quantity__c=2;
       
        insert sub;
        Entitlement en=new Entitlement();
        en.AccountId=acc.id;
        en.Name='test';
        en.StartDate=system.today().addDays(-2);
        insert en;   
    }
    @isTest
    static void testcontroller(){
        Test.startTest();
        EntitlementProcessController controller=new EntitlementProcessController();
        controller.StartBactJob();
        controller.updateProgress();
        List<EntitlementProcessController.BatchJob> job=new List<EntitlementProcessController.BatchJob>();
        job=controller.getJobs();
        Boolean flag=controller.getShowProgressBar();
        Integer start = System.Now().millisecond();
       
        
        Test.stopTest();
         controller.updateProgress();
         job=controller.getJobs();
        
    }
    
    @isTest
    static void EntitlementsProcessInactiveContractBatchTest(){
        Test.startTest();
        Account acc1=new Account();
        acc1.Name='EntitlementProcessControllerTest_Account 1';
        insert acc1;
        
        Entitlement en1=new Entitlement();
        en1.AccountId=acc1.id;
        en1.Name='test';
        en1.StartDate=system.today().addDays(-2);
        en1.EndDate=system.today().addDays(-1);
        insert en1;
        
        Opportunity opp=new Opportunity();
        opp.AccountId=acc1.Id;
        opp.Name='Test opp';
        opp.StageName='Prospecting';
        opp.CloseDate=Date.valueOf('2020-03-16');
        insert opp;
        
        Contract con=new Contract();
        con.AccountId=acc1.Id;
        con.Status='Draft';
        con.StartDate=system.today().addDays(-200);
        con.ContractTerm=1;
        con.SBQQ__Opportunity__c=opp.id;
        insert con;
        List<String> accIds = new List<String>();
        accIds.add(acc1.Id);
        EntitlementsProcessInactiveContractBatch EntBatch = new EntitlementsProcessInactiveContractBatch(accIds);
        string batchId = Database.executeBatch(EntBatch,10);
        Test.stopTest();
    }
    
    @isTest
    static void EntitlementsProcessActiveContractBatchTest(){
        Test.startTest();
        Account acc1=new Account();
        acc1.Name='EntitlementProcessControllerTest_Account 1';
        acc1.Maximum_Portal_Users__c = 20;
        acc1.Override_maximum_Portal_Users__c = 10;
        acc1.Override_Service_Availability__c = 'Standard'; 
        insert acc1;
        
        Entitlement en1=new Entitlement();
        en1.AccountId=acc1.id;
        en1.Name='test';
        en1.StartDate=system.today().addDays(-2);
        en1.EndDate=system.today().addDays(+20);
        en1.Service_Availability__c = 'Standard';
        insert en1;
        
        Opportunity opp=new Opportunity();
        opp.AccountId=acc1.Id;
        opp.Name='Test opp';
        opp.StageName='Prospecting';
        opp.CloseDate=Date.valueOf('2020-03-16');
        insert opp;
        
        Contract con=new Contract();
        con.AccountId=acc1.Id;
        con.Status='Draft';
        con.StartDate=system.today().addDays(-20);
        con.ContractTerm=1;
        con.SBQQ__Opportunity__c=opp.id;
        con.Service_Availability__c = 'Enterprise';
        insert con;
        List<String> accIds = new List<String>();
        accIds.add(acc1.Id);
        EntitlementsProcessActiveContractBatch EntBatch = new EntitlementsProcessActiveContractBatch(accIds);
        string batchId = Database.executeBatch(EntBatch,10);
        Test.stopTest();
    }
    
    
    @isTest
    static void EntitlementsProcessNoContractBatchTest(){
        Test.startTest();
        
        Account acc1=new Account();
        acc1.Name='EntitlementProcessControllerTest_Account 1';
        acc1.Override_maximum_Portal_Users__c = 10;
        acc1.Override_Service_Availability__c = 'Standard';
        insert acc1;
        
        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Test Last';
        contact.email= 'test@mail.com';
        contact.AccountId = acc1.Id;
        
        insert contact;
        
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       system.runAs(thisUser){
       UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
       
        system.debug('portalRole is ' + portalRole);     
       
       Id p = [select id from profile where name='Service Community User Login'].id;
       User user2 = new User(
           contactid=contact.id,
           ProfileId = p,
           Username = 'TestUserCheckOut@mail.com',
           Alias = 'Test',
           Email='Test.last@mail.com',
           EmailEncodingKey='UTF-8',
           Firstname='Test',
           Lastname='Last',
           LanguageLocaleKey='en_US',
           LocaleSidKey='en_US',
           TimeZoneSidKey='America/Chicago',
           IsActive =true
           
         );
           insert user2;  
       }
        
        //EntitlementUtilsTest.CreateCommunityUser(contact);
        List<String> accIds = new List<String>();
        accIds.add(acc1.Id);
        EntitlementsProcessActiveContractBatch EntBatch = new EntitlementsProcessActiveContractBatch(accIds);
        string batchId = Database.executeBatch(EntBatch,10);
        Test.stopTest();
    }
    
    @isTest
    static void EntitlementsProcessContractAndUsersBatchTest(){
        Test.startTest();
        Account acc1=new Account();
        acc1.Name='EntitlementProcessControllerTest_Account 1';
        //acc1.Override_maximum_Portal_Users__c = 10;
       // acc1.Override_Service_Availability__c = 'Standard';
        insert acc1;
        
        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Test Last';
        contact.email= 'test@mail.com';
        contact.AccountId = acc1.Id;
        
        insert contact;
        
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       system.runAs(thisUser){
       UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
       
        system.debug('portalRole is ' + portalRole);     
       
       Id p = [select id from profile where name='Service Community User Login'].id;
       User user2 = new User(
           contactid=contact.id,
           ProfileId = p,
           Username = 'TestUserCheckOut@mail.com',
           Alias = 'Test',
           Email='Test.last@mail.com',
           EmailEncodingKey='UTF-8',
           Firstname='Test',
           Lastname='Last',
           LanguageLocaleKey='en_US',
           LocaleSidKey='en_US',
           TimeZoneSidKey='America/Chicago',
           IsActive=true
         );
           insert user2;  
       }
        
        Opportunity opp=new Opportunity();
        opp.AccountId=acc1.Id;
        opp.Name='Test opp';
        opp.StageName='Prospecting';
        opp.CloseDate=Date.valueOf('2020-03-16');
        insert opp;
        
        Contract con=new Contract();
        con.AccountId=acc1.Id;
        con.Status='Draft';
        con.StartDate=system.today().addDays(-200);
        con.ContractTerm=1;
        con.SBQQ__Opportunity__c=opp.id;
        con.Service_Availability__c = 'Enterprise';
        insert con;
        
        //List<Entitlement> entList= EntitlementsProcessActiveContractBatch.createEntitlementAndUpdateAccount(acc1);
        List<String> accIds = new List<String>();
        accIds.add(acc1.Id);    
        EntitlementsProcessActiveContractBatch EntBatch = new EntitlementsProcessActiveContractBatch(accIds);
        string batchId = Database.executeBatch(EntBatch,10);
        Test.stopTest();
    }
    
 }