/************************************************************************************** 
Name              : testMethods3
Description       : -
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mendy               07/05/2014          Kfir                   [SW-10307]
2. Hanit               12/10/2015          Eyal                   transfered test methods from CloneOpportunity.cls due to version update
****************************************************************************************/
@isTest
public with sharing class TestMethods3 
{
    static testmethod void ContactTriggersHendler_Test()
    {

        ClsObjectCreator cls = new ClsObjectCreator();

        Lead ld = cls.returnLead('TestA1@test.com');
        insert ld;     

        Account acc = cls.returnAccount('AccName234234');
        insert acc;

        test.startTest();
        Contact con = cls.returnContact(acc.ID , 'TestA1@test.com');
        try 
        {
            insert con;
        }
        catch (exception e)
        {
            //System.assert(e.getMessage().contains('more duplicate'));
        }
        test.stopTest();
    }
    
      
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
            
            Id newId = CloneOpportunity.clone(opp.id);
            System.assertNotEquals(opp.Id, newId);
            
            newId = CloneOpportunity.cloneWithProducts(opp.Id);
            System.assertNotEquals(opp.Id, newId);
        } catch (Exception e) {}
    }
 
}