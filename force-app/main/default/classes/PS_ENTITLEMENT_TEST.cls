@IsTest (SeeAllData=true)
public class PS_ENTITLEMENT_TEST  {
    public static testMethod void runTest() {
        
        
    }
    public static testMethod void testschedule() {
         Product2 prod = new Product2(Name = 'Laptop X200', 
                                     Family = 'Hardware',
                                     ProductCode='PS_ENTITLEMENT_TEST',
                                     WDCX_PSEntitlementMonths__c = 2);
        insert prod;
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        insert standardPrice;
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true);
        insert customPB;
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;
        
        account acc = new account (name = 'testacc', Developers__c = 4);
        insert acc;
        contact con = new contact (accountid = acc.id , lastname = 'Lname test',  MailingCountry = 'France');
       // insert con;
        Opportunity opp = new Opportunity (name = 'opp Test ' , Primary_Contact__c = con.id , CloseDate = date.today() + 10 ,
                                           accountid = acc.id , Type = 'New Business' , Paying_entity__c = 'End User',
                                           StageName = 'Approved' , ForecastCategoryName = 'Pipeline' );
        Opportunity opp2 = new Opportunity(Name = 'TestOpp',StageName = 'Prospecting',CloseDate = Date.today().addDays(5) ,  Paying_entity__c = 'End User' ,accountid = acc.id);
        insert opp2;
        QUOTE Q = NEW QUOTE (Name = 'q-124' ,OpportunityId = opp2.id);
        insert q;
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(SBQQ__Quote__c = q.id , SBQQ__StartDate__c = date.today());
       // insert ql;
        OpportunityLineItem OPL = NEW OpportunityLineItem (Opportunityid = opp2.id ,WDCX_Generate_PS_Entitlement__c = true , Quantity = 2 , TotalPrice = 100 , PricebookEntryId =customPrice.id );
        insert opl;
        opp2.StageName = 'Approved';
        update opp2;
        Test.StartTest();
        PS_ENTITLEMENT_JOB sh1 = new PS_ENTITLEMENT_JOB();
        String sch = '0 0 23 * * ?';
        system.schedule('Test Territory Check', sch, sh1);
        Test.stopTest();
    }
}