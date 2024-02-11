@IsTest
public class ContactPersonaUpdates_TEST  {
	@IsTest
	private static void firatTest(){
		Account acc = TestObjectCreator.CreateAccount();
		insert acc;

		contact con = new contact();
		con.FirstName = 'contact';
		con.LastName = 'Test 1';
		con.AccountId = acc.Id;
		con.CX_Champion__c = True;
		con.CX_Influencer__c = False;
		con.Cx_CISO__c = False;
		con.Cx_Head_of_AppSec__c = False;
		con.Cx_Head_of_Development__c = False;
		con.CX_Solution_Owner__c = False;
		con.CX_Dev_Champion__c = False;
		con.CX_Economic_Buyer__c = False;
		con.Contact_Persona_Updated__c = true;
		insert con;

		contact con2 = new contact();
		con2.FirstName = 'contact';
		con2.LastName = 'Test 2';
		con2.AccountId = acc.Id;
		con2.CX_Champion__c = False;
		con2.CX_Influencer__c = False;
		con2.Cx_CISO__c = False;
		con2.Cx_Head_of_AppSec__c = True;
		con2.Cx_Head_of_Development__c = False;
		con2.CX_Solution_Owner__c = False;
		con2.CX_Dev_Champion__c = False;
		con2.CX_Economic_Buyer__c = False;
		con2.Contact_Persona_Updated__c = true;
		insert con2;

		
		ContactPersonaUpdates_Batch theBatch = new ContactPersonaUpdates_Batch ();
        id idBatch = Database.executeBatch(theBatch);

	}

	@IsTest
	private static void test2(){
		String shId = System.schedule('Schedule_TEST', ContactPersonaUpdates_SCHEDULE.CRON_EXP, new ContactPersonaUpdates_SCHEDULE());
	}
}