@IsTest
private class CaseTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Case testCase = new Case(
                Subject = 'New Case'
        );
        insert testCase;
        System.assertNotEquals(null, testCase.Id, 'Failed to insert testCase');
    }
    
    @IsTest
    static void testCaseTriggerHandlerInsert() {
    	Case testCase = new Case(
            Subject = 'New Case',
            Origin = 'Contact_Us',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId()
        );
        insert testCase;
        Case c = [SELECT Id, AccountId FROM Case WHERE Id = :testCase.Id][0];
        System.assertNotEquals(null, c.AccountId);
    }
    
    /*
    @IsTest
    static void testCaseTriggerHandler() {
        Case[] preCases = [SELECT Id, Subject FROM Case];
        preCases[0].Subject = 'Updated Case';
        Case testCase = new Case(
                Subject = 'Newest Case'
        );

        Test.startTest();

        insert testCase;
        update preCases;

        Test.stopTest();

        Case[] postCases = [SELECT Id, Subject FROM Case];
        System.assertEquals(2, postCases.size());
        System.assertEquals('Updated Case', postCases[0].Subject);
    }

    @IsTest
    static void testCaseTriggerHandlerUpdate() {
        Case[] preCases = [SELECT Id, Subject,Assigned_group__c FROM Case];
        preCases[0].Subject = 'Old Case';
        preCases[0].Assigned_group__c = 'Tier_2';
        Test.startTest();

        update preCases;

        Test.stopTest();


        Case[] postCases = [SELECT Id, Subject FROM Case];
        System.assertEquals('Old Case', postCases[0].Subject);
    }

    @IsTest
    static void testCaseTriggerHandlerDisabled() {
        Case[] preCases = [SELECT Id, Subject FROM Case];
        preCases[0].Subject = 'Test Case';

        Test.startTest();

        CaseTriggerHandler.TriggerDisabled = true;
        update preCases;

        Test.stopTest();

        Case[] postCases = [SELECT Id, Subject FROM Case];
        System.assertEquals('Test Case', postCases[0].Subject);
    }

    @IsTest
    static void testCaseTriggerHandlerDelete() {
        Case[] preCases = [SELECT Id, Subject FROM Case];

        Test.startTest();

        delete preCases;
        undelete preCases;

        Test.stopTest();

        Case[] postCases = [SELECT Id, Subject FROM Case];
        System.assertEquals('New Case', postCases[0].Subject);
    }
	*/
}