@isTest
public with sharing class CustomLookup_Ctrl_Test {
    @testSetup
    private static void setup(){
		Utils.CodeOff = true;
		Account a = TestObjectCreator.CreateAccount();
        a.Developers__c = 1;
		insert a;

        insert new Contact(LastName = 'Test1', FirstName = 'Name1', AccountId = a.Id);
        insert new Contact(LastName = 'Test2', FirstName = 'Name2', AccountId = a.Id);
        insert new Contact(LastName = 'Test3', FirstName = 'Name3', AccountId = a.Id);
    }
    
    static testMethod void lookupTest() {
        List<Contact> contacts = [Select Id, LastName, FirstName, Name From Contact];
        List <Id> lid = new List <Id> { contacts[0].Id };

        Test.startTest();
        CustomLookup_Ctrl.searchDB('Contact', 'Name', 'Id', 3, 'Name', 'Name', null, null, 'Account.Name', 'RECTRICT', lid);
        Test.stopTest();
    }
}