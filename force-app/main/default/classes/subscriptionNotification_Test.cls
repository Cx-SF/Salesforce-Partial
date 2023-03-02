@isTest 
private class subscriptionNotification_Test {

	@isTest
	private static void testName() {
		Knowledge__kav art = TestObjectCreator.CreateKnowledge();
		insert art;

		CX_Knowledge_Subscription_Info__c ksi = TestObjectCreator.CreateKnowledgeSubscriptionInfo(art);
		insert ksi;

		String jobId = System.schedule('Schedule_TEST', subscriptionNotification_Schedule.CRON_EXP, new subscriptionNotification_Schedule());
		
		subscriptionNotification_Batch theBatch = new subscriptionNotification_Batch ();
        id idBatch = Database.executeBatch(theBatch);
		theBatch = new subscriptionNotification_Batch (null, null, '', null, '');
	}
}