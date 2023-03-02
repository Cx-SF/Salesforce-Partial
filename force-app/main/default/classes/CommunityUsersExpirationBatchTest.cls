@isTest
public class CommunityUsersExpirationBatchTest {
    public static testMethod void testHaveContractCase(){
        Test.startTest();
        Account acc1=new Account();
        acc1.Name='Test Account 1';
        //acc1.Override_maximum_Portal_Users__c = 10;
       // acc1.Override_Service_Availability__c = 'Standard';
        insert acc1;
        
        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Test Last';
        contact.email= 'test@mail.com';
        contact.AccountId = acc1.Id;
        
        insert contact;
        
       User thisUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive=true and UserRole.name='Admin' LIMIT 1];
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
        CommunityUsersExpirationBatch EntBatch = new CommunityUsersExpirationBatch(accIds);
        string batchId = Database.executeBatch(EntBatch,10);
        Test.stopTest();
    }
    public static testMethod void testHaveNoContractCase(){
         Test.startTest();
        Account acc1=new Account();
        acc1.Name='Test Account 1';
        //acc1.Override_maximum_Portal_Users__c = 10;
       // acc1.Override_Service_Availability__c = 'Standard';
        insert acc1;
        
        Contact contact = new Contact();
        contact.FirstName = 'Test';
        contact.LastName = 'Test Last';
        contact.email= 'test@mail.com';
        contact.AccountId = acc1.Id;
        
        insert contact;
        
       User thisUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive=true and UserRole.name='Admin' LIMIT 1];
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
        
       
        
        //List<Entitlement> entList= EntitlementsProcessActiveContractBatch.createEntitlementAndUpdateAccount(acc1);
        List<String> accIds = new List<String>();
        accIds.add(acc1.Id);    
        CommunityUsersExpirationBatch EntBatch = new CommunityUsersExpirationBatch(accIds);
        string batchId = Database.executeBatch(EntBatch,10);
        Test.stopTest();
    }
}