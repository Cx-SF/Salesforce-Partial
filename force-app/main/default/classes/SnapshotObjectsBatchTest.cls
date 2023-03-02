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

private class SnapshotObjectsBatchTest {

    static testMethod void snapshotOpportunityTest() {
        

		//setup
        ClsObjectCreator objcreator = new ClsObjectCreator();
        Account acc = objcreator.createAccount('test Account Yuval');
        Opportunity opp = objcreator.createOpportunity(acc.Id);
        
        Test.startTest();
        	Database.executeBatch(new SnapshotOpportunityBatch(),200);
        Test.stopTest();
        list<snapshot_opportunity__c> snapList = new list<snapshot_opportunity__c>();
        snapList.addAll([select Id,Opportunity__c from snapshot_opportunity__c where Opportunity__c = : opp.Id]);
        system.assertEquals(snapList.size(),1);
        
    }
     
    static testMethod void snapshotAccountTest() {
        

		//setup
       ClsObjectCreator objcreator = new ClsObjectCreator();
        Account acc = objcreator.createAccount('test Account Yuval');
        Opportunity opp = objcreator.createOpportunity(acc.Id);
        
        
        Test.startTest();
        	Database.executeBatch(new SnapshotAccountBatch(),200);
        Test.stopTest();
        list<Snapshot_Account__c> snapList = new list<Snapshot_Account__c>();
        snapList.addAll([select Id,account__c from Snapshot_Account__c where account__c = : acc.Id]);
        system.assertEquals(snapList.size(),1);
        
    }
    
    static testMethod void snapshotContractTest() {
        
        //setup
        ClsObjectCreator objcreator = new ClsObjectCreator();
        Account acc = objcreator.createAccount('test Account Yuval');
        Opportunity opp = objcreator.createOpportunity(acc.Id);
        contract cont = objcreator.returnContract(acc.id,opp.id);
        insert cont;
        
        Test.startTest();
        	Database.executeBatch(new SnapshotContractBatch(),200);
        Test.stopTest();
        list<Snapshot_Contract__c> snapList = new list<Snapshot_Contract__c>();
        snapList.addAll([select Id,contract__c from Snapshot_Contract__c where contract__c =: cont.Id]); 
        system.assertEquals(snapList.size(),1);
        
    }
}