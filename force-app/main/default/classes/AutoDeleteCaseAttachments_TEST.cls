@isTest 
private class AutoDeleteCaseAttachments_TEST {

	@isTest
	private static void test() {
		Account a = TestObjectCreator.CreateAccount();
		a.CX_Days_to_Delete_Attachments_from_Case__c = '7';
		insert a;

		Case c = TestObjectCreator.CreateCase(a);
		c.CX_Manually_Delete_Attachments__c = true;
		c.ClosedDate = Date.today().addDays(-1);
		insert c;

		String jobId = System.schedule('Schedule_TEST', AutoDeleteCaseAttachments_SCHEDULE.CRON_EXP, new AutoDeleteCaseAttachments_SCHEDULE());
		
		AutoDeleteCaseAttachments_BATCH theBatch = new AutoDeleteCaseAttachments_BATCH ();
        id idBatch = Database.executeBatch(theBatch);
	}
}