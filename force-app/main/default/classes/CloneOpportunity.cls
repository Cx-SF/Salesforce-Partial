/*
    ClassName:      CloneOpportunity
    Description:    Custom clone opportunity methods
    
    Change History
    
    Version  Date       Init    Description of Change
    ------- ------      ------  --------------------------------------------
    1.0     25-02-10    RAC     Initial Version
    
************************************************************************************** 
Name              : CloneOpportunity
Description       : -
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
2. Hanit(Update)       12/10/2015          Eyal                   [SW-15641]
****************************************************************************************
*/
public with sharing class CloneOpportunity {
    

    // Clone an opportunity with just the fields you want to copy across
    private static Opportunity cloneOpp(Id oppId) {

        // TODO: Amend this method to set the fields you wish to bring across
        // if they're not in the SELECT they won't be copied
        Opportunity origOpp = [SELECT Id,Name, CloseDate, StageName, Amount, 
                                      opportunity_Type__c, AccountId, CampaignId, Type, Description, RecordTypeId,Partner_Account__c
                                FROM   Opportunity
                                WHERE  Id = :oppId][0];

        // We use the clone function to automatically copy all the fields
        // in the SOQL above, leaving out the Id field.
        Opportunity cloneOpp = origOpp.clone(false);

        // TODO: Override or set defaults for any fields here
        cloneOpp.Name = 'Renewal - ' + origOpp.Name;
        cloneOpp.Source_Opportunity__c=origOpp.Id;
        cloneOpp.Partner_Account__c=origOpp.Partner_Account__c;
        
        if (origOpp.opportunity_Type__c == 'Standard'){
        cloneOpp.RecordTypeId='012D00000003GGd';
        } 
        else if (origOpp.opportunity_Type__c == 'MUS Renewal'){
        cloneOpp.RecordTypeId='012D00000003GGc';
        }
        else if (origOpp.opportunity_Type__c == 'Gold Disc'){
        cloneOpp.RecordTypeId='012D00000003GGa';
        }
        else if (origOpp.opportunity_Type__c == 'Gold Disc Call Off'){
        cloneOpp.RecordTypeId='012D00000003GGb';
        } Else {
        cloneOpp.RecordTypeId='012D00000003GGd';
        }
        
        cloneOpp.Type='Renewal';
        cloneOpp.CloseDate =origOpp.CloseDate.addMonths(1);   // Set your default close date or copy the original
        // Change the stage to be the first step in your sales process
        cloneOpp.StageName = 'Value Proposition';
        cloneOpp.Type = 'Renewal';
        cloneOpp.Billing_Type__c= 'Standard';
        cloneOpp.Source_Opportunity__c = origOpp.Id;
     //   cloneOpp.Source_Opportunity__c = origOpp.Id;
        // Return the new record, note we haven't created it yet
        return cloneOpp;
    }
    
    private static List<OpportunityLineItem> cloneItems(Id oldId, Id newId) {
        
        
        List<OpportunityLineItem> oldItems; 
        List<OpportunityLineItem> newItems = new List<OpportunityLineItem>();

        // TODO: Amend with any custom fields you wish to copy across, 
        // if they're not in the SELECT they won't be copied!
        oldItems = [SELECT o.UnitPrice, o.ServiceDate, o.Quantity, o.PricebookEntryId,o.Product2Id,
                        o.duration__c,o.duration_type__c,o.servers__c,o.auditors__c,o.users__c,o.engines__c,o.OpportunityId, o.Id, o.Languages__c, o.Description, o.Discount_OR__c, o.Discount_Amount__c, o.Discount_Amount_OR__c, o.Discounted_Price__c, o.Product_Type_New__c, o.Sales_Instructions__c, o.Training_Hours__c
                 FROM   OpportunityLineItem o 
                 WHERE  o.OpportunityId = :oldId];
               
        // Copy all the items and clear the original Id field
        newItems = oldItems.deepClone(false);
        system.debug('newItems = ' + newItems);
        //Loop through the records updating their OpportunityId
        for (OpportunityLineItem li : newItems) {
            li.OpportunityId = newId;
        } 

        // Return the collectin of new items, note they haven't been created yet
        return newItems;
    }
    
    
    
    public static Id clone(Id oppId) {
        
        Opportunity cloneOpp;
        
        System.debug(' enth: CloneOpportinity ' + oppId);
        
        if (oppId != null) {
            cloneOpp = cloneOpp(oppId);
            insert cloneOpp;    
        }
        else {
            throw new CloneOppException('Opportunity not found, ensure button is on the Opportunity Detail page');
        }
        
        return cloneOpp.Id;
        
    }
    
    // Clone an opportunity with just the fields you want to copy across
    public static Id cloneWithProducts(Id oppId) {

        Opportunity cloneOpp;
        List<OpportunityLineItem> items;

        if (oppId != null) 
        {
            cloneOpp = cloneOpp(oppId);
            system.debug('oppr = ' + cloneOpp);
            insert cloneOpp;
            
            items = cloneItems(oppId, cloneOpp.Id);
            if (!items.isEmpty()) {
                insert items;
            }
           
        }
        else {
            throw new CloneOppException('Opportunity not found, ensure button is on the Opportunity Detail page');
        }
        
        return cloneOpp.Id;
    }
   /*
    static testMethod void testCloneOpp() {
        try {
            Opportunity opp = new Opportunity();
            opp.name = 'testCloneOpp';
            opp.closedate = System.today();
            opp.amount = 9999;
            opp.StageName = 'Closed Won';
            opp.Type = 'TestMethod';
            insert opp;
            
            Product2 prod = new Product2();
            prod.Name = 'Test';
            prod.ProductCode = 'test';
            prod.Description = 'Test';
            prod.IsActive = true;
            insert prod;
            
            List<PriceBookEntry> pbs = new List<PriceBookEntry>();
            PriceBookEntry pbe = new PriceBookEntry();
            pbe.Product2Id = prod.id;
            pbe.UnitPrice = 9.99;
            pbe.UseStandardPrice = false;
            pbe.Pricebook2Id = [SELECT id from Pricebook2 where isStandard = true][0].id;
            pbe.isActive = true;
            pbs.add(pbe);
            pbe = new PriceBookEntry();
            pbe.Product2Id = prod.id;
            pbe.UnitPrice = 9.99;
            pbe.UseStandardPrice = false;
            pbe.Pricebook2Id = [SELECT id from Pricebook2 where Name = 'Checkmarx Official Price Book 2015' And IsStandard = false and IsActive = true limit 1][0].id;
            pbe.isActive = true;
            pbs.add(pbe);
            insert pbs;
            
            OpportunityLineItem item = new OpportunityLineItem();
            item.OpportunityId = opp.id;
            item.Quantity = 1;
            item.PricebookEntryId = pbe.id;
            item.UnitPrice = 9.99;
            insert item;
            
            Id newId = clone(opp.id);
            System.assertNotEquals(opp.Id, newId);
            
            newId = cloneWithProducts(opp.Id);
            System.assertNotEquals(opp.Id, newId);
        } catch (Exception e) {}
    }
  */
}