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
@isTest
private class HourReportTest {

    
    static testMethod void myUnitTest() {
    	
    	ClsObjectCreator creator = new ClsObjectCreator();
  
        account acc = creator.createAccount('test');   
      
        contact con = creator.CreateContact(acc.Id,'test@gmail.com');
        
        Opportunity opp = creator.createOpportunity(acc.Id);
       
        
        PS_Entitlement__c ent = creator.returnEntitlment(acc.id,Opp.Id);
        ent.WDCX_End_Date__c = date.newInstance(2018, 12, 1);
        //ent.
        insert ent;
        
        Hour_Report__c logHour = new Hour_Report__c(); 
        logHour.Account__c = acc.Id;
        logHour.Is_billable__c = 'Billable';
        logHour.PS_Entitlement__c = ent.Id;
        logHour.Number_of_Hours__c = 5;
        logHour.Contact_Name__c = con.Id;
        logHour.Engineer__c = UserInfo.getUserId();
        
        test.startTest();
        insert logHour;
        
        logHour.Number_of_Hours__c = 10;
        update  logHour;
        logHour.Is_billable__c = 'Non - Billable';
        update  logHour;
        Delete logHour;
        
        test.stopTest();
        
        	
        
        
    }
}