@isTest//(SeeAllData=true)
private class OpportunityQuoteLineItemTest {
    static testMethod void test() {        

        ClsObjectCreator cls = new ClsObjectCreator();
        
        Account a = cls.returnAccount('Account123');
        insert a;

        Opportunity o = new Opportunity(AccountId=a.Id, Name='Opportunity', StageName='Prospecting', CloseDate=Date.today());
        insert o;
        
        Product2 p2 = new Product2(Name='Product',isActive=true);
        insert p2;

        //01sD00000008D3S
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=Test.getStandardPricebookId(), Product2Id=p2.Id, UnitPrice=99, isActive=true);
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(PriceBookEntryId=pbe.Id, OpportunityId=o.Id, Quantity=1, TotalPrice=99);
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        olis.add(oli);
        OpportunityLineItemHandler.onInsert(olis);
        OpportunityLineItemHandler.afterInsert(olis);
        
        try {
            insert oli;
        } catch (Exception e) {}
        
        Quote q = new Quote(Name='Quote', OpportunityId=o.Id);
        insert q;
        
        QuoteLineItem qli = new QuoteLineItem(PriceBookEntryId=pbe.Id, QuoteId=q.Id, Quantity=1);
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(qli);
        QuoteLineItemHandler.onInsert(qlis);        
        
        try {
            insert qli;
        } catch (Exception e) {}
        
    }
}