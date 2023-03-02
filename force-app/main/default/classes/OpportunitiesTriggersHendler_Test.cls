@isTest(SeeAllData = true)
public class OpportunitiesTriggersHendler_Test {
  
    static testmethod void SetDeliveryAlert_Test()
    {
        Opportunity opp1 = new Opportunity(Name='TestOpp-1', StageName = 'Demo', CloseDate = system.today(), Description = NULL, 
                                           Billing_Type__c ='Pre-Payment', Opportunity_Status__c ='Pending Payment', Payment_collected_amount__c = 3000);
        insert opp1;
    }   

}