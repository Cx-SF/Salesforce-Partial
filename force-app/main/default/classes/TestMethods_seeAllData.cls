/************************************************************************************** 
Name              : testMethods3
Description       : -
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mohammad               19/12/2014               Kfir                  [SW-11335]
2. Mohammad               21/12/2014               Kfir                  [SW-11335]
****************************************************************************************/
@isTest(SeeAllData=true)
private class TestMethods_seeAllData {

    
    /**
     * Created By: Mohammad Garrah
     * Code Tested: OpportunitiesTriggersHendler.Opportunity_InitialRevenueRecognitionControl
     */
    static testMethod void InitialRevenueRecognitionControlCreation_Test(){


        Pricebook2 pb = [select id from Pricebook2 where IsStandard = false and IsActive = true limit 1];
        //String CheckmarxOfficialPriceBook = '01sD00000007dZC';
        
        Opportunity opp1 = new Opportunity(Name='Check', StageName = 'CLosed Won', Opportunity_Status__c = '', Support_Status__c = '', CurrencyIsoCode = 'USD', Delivery_Date__c = system.today(), CloseDate = system.today(), Description = NULL, Pricebook2Id = pb.id, Number_of_Payments__c = 2, Payment_Schedule__c = 'Monthly', Payment_collected_date__c = system.today());
        insert opp1;
        
        list<PricebookEntry> lst_pbe = [select id,Product2.Product_Type__c from PricebookEntry where CurrencyIsoCode = 'USD' and IsActive = true and Product2.IsActive = true and Pricebook2Id =: pb.id And Product2.Product_Type__c ='Project' limit 2];

        list<OpportunityLineItem> lst_items = new list<OpportunityLineItem>();
        lst_items.add(new OpportunityLineItem(Duration_Type__c = 'Week',Duration__c = '2',Languages__c = 'Apex',UnitPrice = 500, Quantity = 5, PriceBookEntryId = lst_pbe[0].id, OpportunityId = opp1.id));
        lst_items.add(new OpportunityLineItem(Duration_Type__c = 'Week',Duration__c = '2',Languages__c = 'Apex',UnitPrice = 700, Quantity = 3, PriceBookEntryId = lst_pbe[1].id, OpportunityId = opp1.id));
        insert lst_items;
        Test.startTest();
        opp1.Support_Status__c = 'Delivered';
        update opp1;
        Test.stopTest();
        
        list<Revenue_Recognition_Control__c> lst_RRC = new list<Revenue_Recognition_Control__c>([select id from Revenue_Recognition_Control__c where Opportunity_Name__c =: opp1.id]);
        system.assertEquals(lst_RRC.size(),1);
    }
    
    
    /**
     * Created By: Mohammad Garrah
     * Code Tested: OpportunitiesTriggersHendler.Opportunity_GeneratePayments
     */
    static testMethod void opportunityGeneratePayments_Test(){
        

        ClsObjectCreator cls = new ClsObjectCreator();

        Account acc = cls.createAccount('tstAccname');

        Pricebook2 pb = [select id from Pricebook2 where IsStandard = false and IsActive = true limit 1];
        //String CheckmarxOfficialPriceBook = '01sD00000007dZC';
        
        Opportunity opp1 = new Opportunity(Name='Check', StageName = 'Qualification', Opportunity_Status__c = '', CurrencyIsoCode = 'USD', Delivery_Date__c = system.today(), CloseDate = system.today(), Pricebook2Id = pb.id, Number_of_Payments__c = 2, Payment_Schedule__c = 'Monthly', Payment_collected_date__c = system.today());
        insert opp1;
        
        list<PricebookEntry> lst_pbe = [select id from PricebookEntry where CurrencyIsoCode = 'USD' and IsActive = true and Product2.IsActive = true and Pricebook2Id =: pb.id And Product2.Product_Type__c ='Project' limit 2];
        
        list<OpportunityLineItem> lst_items = new list<OpportunityLineItem>();
        lst_items.add(new OpportunityLineItem(Duration_Type__c = 'Week',Duration__c = '2',Languages__c = 'Apex',UnitPrice = 500, Quantity = 5, PriceBookEntryId = lst_pbe[0].id, OpportunityId = opp1.id));
        lst_items.add(new OpportunityLineItem(Duration_Type__c = 'Week',Duration__c = '2',Languages__c = 'Apex',UnitPrice = 700, Quantity = 3, PriceBookEntryId = lst_pbe[1].id, OpportunityId = opp1.id));
        insert lst_items;
        Test.startTest();
        opp1.Invoice_date__c = Date.today();
        opp1.StageName = 'Closed Won';
        opp1.Opportunity_Status__c = 'Invoiced';
        opp1.AccountId = acc.ID;
        update opp1;
        Test.stopTest();
        
        list<Payment__c> lst_payments = new list<Payment__c>([select id from Payment__c where Opportunity__c =: opp1.id]);
        //system.assertEquals(lst_payments.size(),2);
    }
    
    
     /**
     * Created By: Mohammad Garrah
     * Code Tested: VF_RevenueRecognitionControl
     */
    static testMethod void VF_RevenueRecognitionControl_Test(){
        
        Pricebook2 pb = [select id from Pricebook2 where IsStandard = false and IsActive = true limit 1];
        //String CheckmarxOfficialPriceBook = '01sD00000007dZC';
        
        Opportunity opp1 = new Opportunity(Name='Check', StageName = 'CLosed Won', Opportunity_Status__c = '', Support_Status__c = '' , CurrencyIsoCode = 'USD', Delivery_Date__c = system.today(), CloseDate = system.today(), Description = NULL, Pricebook2Id = pb.id, Number_of_Payments__c = 2, Payment_Schedule__c = 'Monthly', Payment_collected_date__c = system.today());
        insert opp1;
        
        list<PricebookEntry> lst_pbe = [select id from PricebookEntry where CurrencyIsoCode = 'USD' and IsActive = true and Product2.IsActive = true and Pricebook2Id =: pb.id And Product2.Product_Type__c ='Project' limit 2];
        
        list<OpportunityLineItem> lst_items = new list<OpportunityLineItem>();
        lst_items.add(new OpportunityLineItem(Duration_Type__c = 'Week',Duration__c = '2',Languages__c = 'Apex',UnitPrice = 500, Quantity = 2, PriceBookEntryId = lst_pbe[0].id, OpportunityId = opp1.id));
        lst_items.add(new OpportunityLineItem(Duration_Type__c = 'Week',Duration__c = '2',Languages__c = 'Apex',UnitPrice = 700, Quantity = 3, PriceBookEntryId = lst_pbe[1].id, OpportunityId = opp1.id));
        insert lst_items;
        opp1.Support_Status__c = 'Delivered';
        update opp1;
        
        system.Test.setCurrentPage(Page.VF_RevenueRecognitionControl);
        ApexPages.StandardController oppSC = new ApexPages.standardController(opp1);
        Test.startTest();
        VF_RevenueRecognitionControl rrController1 = new VF_RevenueRecognitionControl(oppSC);
        rrController1.GenerateRR();
        
        list<Revenue_Recognition__c> lst_RR = [select id from Revenue_Recognition__c where Opportunity_Name__c =: opp1.id];
        if(lst_RR == null || lst_RR.size()==0)
            system.assert(false);
        lst_RR[0].Locked__c = true;
        update lst_RR;
        
        VF_RevenueRecognitionControl rrController2 = new VF_RevenueRecognitionControl(oppSC);
        rrController2.RRC.Product_Control__r[0].Total_Price_for_Revenue_Recognition__c -= 100;
        rrController2.RRC.Product_Control__r[1].Total_Price_for_Revenue_Recognition__c += 100;
        rrController2.GenerateRR();
        
        Test.stopTest();
    }
    
    
    /**
     * Created By: Mohammad Garrah
     * Code Tested: VF_OpportunityRevenueRecognition
     */
    static testMethod void VF_OpportunityRevenueRecognition_Test(){
        
        Opportunity opp1 = new Opportunity(Name='Check', StageName = 'CLosed Won', CurrencyIsoCode = 'USD', Delivery_Date__c = system.today(), CloseDate = system.today(), Number_of_Payments__c = 2, Payment_Schedule__c = 'Monthly', Payment_collected_date__c = system.today());
        insert opp1;
        
        list<Product2> lst_products = [select id from Product2 where IsActive = true limit 2];
        
        list<Revenue_Recognition__c> lst_RR = new list<Revenue_Recognition__c>();
        lst_RR.add(new Revenue_Recognition__c(Opportunity_Name__c=opp1.id, CurrencyIsoCode='USD', Product_Name__c=lst_products[0].id, Date__c=system.today(), Amount__c=100, Days_In_Quarter__c=30, OpportunityLineItemId__c='1111111111'));
        lst_RR.add(new Revenue_Recognition__c(Opportunity_Name__c=opp1.id, CurrencyIsoCode='USD', Product_Name__c=lst_products[0].id, Date__c=system.today().addMonths(3), Amount__c=100, Days_In_Quarter__c=30, OpportunityLineItemId__c='1111111111'));
        lst_RR.add(new Revenue_Recognition__c(Opportunity_Name__c=opp1.id, CurrencyIsoCode='USD', Product_Name__c=lst_products[0].id, Date__c=system.today().addMonths(6), Amount__c=100, Days_In_Quarter__c=30, OpportunityLineItemId__c='1111111111'));
        lst_RR.add(new Revenue_Recognition__c(Opportunity_Name__c=opp1.id, CurrencyIsoCode='USD', Product_Name__c=lst_products[1].id, Date__c=system.today(), Amount__c=100, Days_In_Quarter__c=30, OpportunityLineItemId__c='2222222222'));
        lst_RR.add(new Revenue_Recognition__c(Opportunity_Name__c=opp1.id, CurrencyIsoCode='USD', Product_Name__c=lst_products[1].id, Date__c=system.today().addMonths(3), Amount__c=100, Days_In_Quarter__c=30, OpportunityLineItemId__c='2222222222'));
        
        insert lst_RR;
        
        system.Test.setCurrentPage(Page.VF_OpportunityRevenueRecognition);
        ApexPages.StandardController oppSC = new ApexPages.standardController(opp1);
        Test.startTest();
        VF_OpportunityRevenueRecognition rrController1 = new VF_OpportunityRevenueRecognition(oppSC);
        Test.stopTest();
    }
    
}