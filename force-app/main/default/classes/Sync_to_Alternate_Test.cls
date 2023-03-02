@isTest (seeAllData = true )
public class Sync_to_Alternate_Test {
    
    static testMethod void Test()
    {
         Account testAccount = new Account( Name = 'testAccount');
        insert testAccount;
        List<Opportunity> listOpp = new List<Opportunity>();
        Opportunity opp = new Opportunity(Name = 'TestOpp',StageName = 'Prospecting',CloseDate = Date.today().addDays(5), Pricebook2id = CPQ_Settings__c.getInstance().GlobalPriceBookId__c  );
        insert Opp;
        Opportunity opp2 = new Opportunity(Name = 'TestOpp',StageName = 'Prospecting',CloseDate = Date.today().addDays(5), 
                                           AccountId =testAccount.id , type ='Upsell', Pricebook2id = CPQ_Settings__c.getInstance().GlobalPriceBookId__c  );
        insert Opp2;
         SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id, SBQQ__Primary__c = false,
                                                  SBQQ__Account__c = testAccount.Id
                                                  );
        insert quote;
       // ApexPages.currentPage().getParameters().put('lc',objLeadCenter.id);	Sync_to_Alternate
        ApexPages.StandardController stdquote = new ApexPages.StandardController(quote);
        Sync_to_Alternate_Cntl Sync_to_Alternate = new Sync_to_Alternate_Cntl(stdquote);
        Sync_to_Alternate.getAllContacts();
        System.currentPageReference().getParameters().put('conid', opp2.id);
        Sync_to_Alternate.selectcon();
        Sync_to_Alternate.saveIt();
    }
}