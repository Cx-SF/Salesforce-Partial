/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest (SeeAllData=true)
/*
creation of CPQ objects and data is very complexed and prone for errors.
That is why Unfortnantly I use the "SeeAllData=true" notation and just query for the record.
*/
private class ContractExceptedRenewalBatchTest {

    static testMethod void BatchTest() {
        
        //setup
        list<SBQQ__Subscription__c> subscriptionList = new list<SBQQ__Subscription__c>();
        subscriptionList.addAll([Select Id, Subscription_ACV__c, SBQQ__Contract__c, SBQQ__Contract__r.SBQQ__RenewalOpportunity__c,NeedToBeCalculatedInBatch__c
    									From SBQQ__Subscription__c 
    									where Subscription_ACV__c > 0 and SBQQ__Contract__r.SBQQ__RenewalOpportunity__c != null limit 100]);
    				
        for (SBQQ__Subscription__c sub : subscriptionList) {
        	
        	sub.NeedToBeCalculatedInBatch__c = true;
        }
        update subscriptionList;
        String CRON_EXP = '0 0 0 15 3 ? *';
       
         
        Test.startTest();
        	String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new ContractExceptedRenewalBatch());
        	String jobId2 = System.schedule('ScheduleApexClassTest2',  CRON_EXP, new OpportunityExpectedRenewalBatch());
        	String jobId3 = System.schedule('ScheduleApexClassTest3',  CRON_EXP, new OpportunityLatestExpectedRenewalBatch());
            //CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];   
        Test.stopTest();
        //System.assertEquals(CRON_EXP, ct.CronExpression);
        //System.assertEquals(0, ct.TimesTriggered);
    }
}