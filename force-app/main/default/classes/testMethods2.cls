/************************************************************************************** 
Name              : testMethods2
Description       : -
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Dana Furman               07/05/2014          Kfir                   [SW-08799]
2. Dana Furman               02/06/2014          Kfir                   [SW-09176]
****************************************************************************************/
@isTest
public class testMethods2 
{
    /*static testmethod void OpportunityTriggersHendler_OpportunityNumbering_Test()
    {
        Opportunity opp1 = new Opportunity(Name='Check', StageName = 'Demo', CloseDate = system.today(), Description = NULL);
        insert opp1;
        
        System.assertEquals(opp1.Closed_Won_Opportunities_counter__c, null);
        
        opp1.stageName = 'Approved';
        update opp1;
        
        System.assertNotEquals(opp1.Closed_Won_Opportunities_counter__c, 0);
            
        Opportunity opp2 = new Opportunity(Name='Check', StageName = 'Demo', CloseDate = system.today(), Description = NULL);
        insert opp2;
        
        System.assertEquals(opp2.Closed_Won_Opportunities_counter__c, null);
        
        opp2.stageName = 'Closed Won';
        update opp1;
        
        System.assertNotEquals(opp2.Closed_Won_Opportunities_counter__c, 0);    
            
            
    }*/

   static testmethod void ZendeskTicketTriggersHendler_RelatedZendeskTicketsToOrganizations_Test()
    {
        
        /*ClsObjectCreator cls = new ClsObjectCreator();
        
        Account acc = cls.returnAccount('test653454');
        insert acc;
        
        Contact con1 = cls.returnContact(acc.ID , 'TestC1@test.com');
        insert con1;
        
        Contact con2 = cls.returnContact(acc.ID , 'TestC2@test.com');
        insert con2;

        Zendesk__Zendesk_Ticket__c zt2 = new Zendesk__Zendesk_Ticket__c(Name = 'test1', Zendesk__Requester__c = con1.id);
        insert zt2;
        
        Zendesk__Zendesk_Ticket__c zt3 = new Zendesk__Zendesk_Ticket__c(Name = 'test2' , Zendesk__Requester__c = con2.id);
        insert zt3;
        
        ZendeskTicketTriggersHendler.justBringUpTheCovrage();*/
        
        ZendeskTicketTriggersHendler ZTTHtest = new ZendeskTicketTriggersHendler();
    } 
    
    
}