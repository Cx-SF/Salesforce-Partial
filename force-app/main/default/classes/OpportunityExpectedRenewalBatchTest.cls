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
@isTest (SeeAllData=true)
private class OpportunityExpectedRenewalBatchTest {

    static testMethod void myUnitTest() {
        
		//setup
        /*ClsObjectCreator creator = new ClsObjectCreator();
        Account acc = creator.createAccount('test account');
        Opportunity opp  = creator.createOpportunity(acc.id);
        contract cont = creator.returnContract(acc.Id,opp.Id);
        insert cont;
        cont.SBQQ__RenewalQuoted__c = true;
        update cont;
        opp.SBQQ__RenewedContract__c = cont.id;
        update opp;*/
        String CRON_EXP = '0 0 0 15 3 ? *';
        
        Test.startTest();
        	String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new OpportunityExpectedRenewalBatch());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        Test.stopTest();
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        
    }
}