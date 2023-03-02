@isTest
public with sharing class AutoSolvedProcessBatchTest {
    @TestSetup
    static void makeData(){
        ClsObjectCreator ObjectCreator = new ClsObjectCreator(); 
        Account acc = ObjectCreator.createAccount('test');
        Contact con = ObjectCreator.CreateContact(acc.Id,'test@test.test');
        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'CxAST' LIMIT 1];
        Case testCase = new Case(
                RecordTypeId = rt.Id,
                Subject = 'Newest Case',
                Status = 'New',
                On_Hold__c = false ,
            	ContactId = con.Id
        );
        insert testCase;
        
    }

    @IsTest
    static void testBatch(){
        Case testCase =[SELECT Id,Origin,Status,On_Hold__c,Status_Change_Date__c FROM Case LIMIT 1];
        testCase.Origin	 = 'Community';
        testCase.Status	 = 'Pending_customer';
        testCase.On_Hold__c	 = false;
        //for PROD
        testCase.Status_Change_Date__c  = Date.today().addDays(-7);
        //for UAT
        //testCase.Status_Change_Date__c  = Date.today().addDays(-1);
        system.debug('testCase.Status_Change_Date__c'+testCase.Status_Change_Date__c);
        update testCase;
        system.debug('testCase.Status_Change_Date__c'+testCase.Status_Change_Date__c);
        //for PROD
         testCase.Status_Change_Date__c  = Date.today().addDays(-7);
        //for UAT
        //testCase.Status_Change_Date__c  = Date.today().addDays(-1);
        system.debug('testCase.Status_Change_Date__c'+testCase.Status_Change_Date__c);
        update testCase;
        Test.startTest();
            try{
                Database.executeBatch(new AutoSolvedProcessBatch(),1); 
                Case afterCase =[SELECT Id,Origin,Status FROM Case LIMIT 1];
                System.debug('**afterCase: '+afterCase);
				Set<Id> caseIds = new Set<Id>();
				caseIds.add(afterCase.Id);
				AutoSolvedProcessBatch TBatch = new AutoSolvedProcessBatch(caseIds);
				string batchId = Database.executeBatch(TBatch,200);
            }catch(Exception e){

            }
        Test.stopTest();
    }
}