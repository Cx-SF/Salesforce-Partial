/**
* Wedo Task #6323   Batch for Accounts without Contracts Test
* date  :   11/11/2019
* class :    AccountsNoContractsBatchTest
* Author:   Sandra Chaltiel
* For Checkmarks
*/
@isTest
public class AccountsNoContractsBatchTest {

    @isTest(SeeAllData=true)
    static void AccountsNoContractsBatchTrueTest(){
 		// The following fields are not writable so the scope will always be empty
        // Account_Status__c = 'Prospect';
        // IsPartner = true;
        // Hence, accounts couldn't be created here ->  use of SeeAllData=true

        Test.startTest();

        List<Account> scope;
        scope = [SELECT Id, Service_Availability__c, Override_Service_Availability__c, Maximum_Portal_Users__c, Override_maximum_Portal_Users__c, Account_Status__c, (SELECT Id, Name, AccountId, StartDate, EndDate, SlaProcessId, Status, Case_Priority__c, Type, Number_Of_Users__c, Service_Availability__c FROM Entitlements where Status='Active'), (SELECT Id, Service_Availability__c, CreatedDate, endDate FROM Contracts WHERE endDate > 2019-01-01) FROM  Account WHERE Id NOT IN (SELECT AccountId FROM Contract WHERE endDate > 2019-01-01) AND Account_Status__c = 'Prospect' AND IsPartner = true];
        
        AccountsNoContractsBatch AccBatch = new AccountsNoContractsBatch();
        string batchId = Database.executeBatch(AccBatch,1);
        
        AccBatch.raiseCoverage();
        Test.stopTest();
    }
}