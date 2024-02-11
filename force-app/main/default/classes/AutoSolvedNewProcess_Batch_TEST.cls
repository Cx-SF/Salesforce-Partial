@isTest
public class AutoSolvedNewProcess_Batch_TEST  {
	@TestSetup
	private static void testSetup(){
		contact con = new contact();
		con.LastName = 'test lastName';
		insert con;

		Case c = new Case();
		c.ContactId = con.Id;
		c.Status = 'Pending Customer';
		c.Cx_Pending_Customer_Action__c = 'Pending First Reminder';
		c.Cx_Pending_Customer_Status_Change_Date__c = Date.today().addDays(20);
		c.RecordTypeId = '0123z000000VG2zAAG';
		insert c;

		Case c2 = new Case();
		c2.ContactId = con.Id;
		c2.Status = 'Pending Customer';
		c2.Cx_Pending_Customer_Action__c = 'Pending First Reminder';
		c2.Cx_Pending_Customer_Status_Change_Date__c = Date.today().addDays(20);
		c2.RecordTypeId = '0123z000000VG2zAAG';
		insert c2;

		Case c3 = new Case();
		c3.ContactId = con.Id;
		c3.Status = 'Pending Customer';
		c3.Cx_Pending_Customer_Action__c = 'Pending Second Reminder';
		c3.Cx_Pending_Customer_Last_Reminder_Date__c = Date.today().addDays(30);
		c3.RecordTypeId = '0123z000000VG2zAAG';
		insert c3;

		Case c4 = new Case();
		c4.ContactId = con.Id;
		c4.Status = 'Pending Customer';
		c4.Cx_Pending_Customer_Action__c = 'Pending Second Reminder';
		c4.Cx_Pending_Customer_Last_Reminder_Date__c = Date.today().addDays(30);
		c4.RecordTypeId = '0123z000000VG2zAAG';
		insert c4;
	}

	@IsTest
	private static void testNumber1() {
		AutoSolvedNewProcess_Batch theBatch = new AutoSolvedNewProcess_Batch ();
        String idBatch = Database.executeBatch(theBatch, 200);
	}
}