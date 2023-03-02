@isTest
private class TestChangeOpportunityStatus  {
/*
    static testmethod void testChangeOpportunityStatus() {

        ClsObjectCreator cls = new ClsObjectCreator();

        Account acc1 = cls.createAccount('quoteTestAcc1');

        Opportunity opp = new Opportunity();
        opp.Name = 'Mor Opp Test';
        opp.StageName ='Demo';
        opp.CloseDate=system.today();
        opp.MUS_Renewal__c = system.today();
        opp.AccountId = acc1.ID;
        insert opp;

        
        
        Quote quote = new Quote();
        quote.Name = 'Mor Quote Test';
        quote.Status = 'Approved';
        quote.OpportunityId = opp.Id;
        //quote.IsSyncing = true;
        insert quote;
        
        
        ////
        opp.SyncedQuoteId = quote.Id;
        update opp;
        ///
        
        
        quote.Status = 'Rejected';
        update quote;
        
        opp = [SELECT Name, StageName FROM Opportunity WHERE Name =: 'Mor Opp Test'];
        System.assert(opp.StageName == 'Rejected');
        
        quote.Status = 'Approved';
        update quote;
        
        opp = [SELECT Name, StageName FROM Opportunity WHERE Name =: 'Mor Opp Test'];
        System.assert(opp.StageName == 'Closed Won');
        
        
        quote.Status = 'In Review';
        update quote;
        
        opp = [SELECT Name, StageName FROM Opportunity WHERE Name =: 'Mor Opp Test'];
        System.assert(opp.StageName == 'Pending Approval');
        
    
    }
*/
}