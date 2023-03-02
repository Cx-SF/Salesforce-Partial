@isTest 
private class KnowledgeHandler_TEST {

	@isTest
	private static void testName() {
		Knowledge__kav art = TestObjectCreator.CreateKnowledge();
		insert art;

		CX_Knowledge_Subscription_Info__c ksi = TestObjectCreator.CreateKnowledgeSubscriptionInfo(art);
		insert ksi;

		art = TestObjectCreator.CreateKnowledge();
		art.Title = 'Test Article 2';
		art.UrlName = 'urlName2';
		insert art;
	}
}