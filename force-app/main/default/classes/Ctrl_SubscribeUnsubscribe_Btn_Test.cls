@isTest 
private class Ctrl_SubscribeUnsubscribe_Btn_Test {

	@isTest
	private static void testName() {
		Knowledge__kav art = TestObjectCreator.CreateKnowledge();
		insert art;

		CX_Knowledge_Subscription_Info__c ksi = TestObjectCreator.CreateKnowledgeSubscriptionInfo(art);
		insert ksi;

		Ctrl_SubscribeUnsubscribe_Btn.getAll(art.Id);
		Ctrl_SubscribeUnsubscribe_Btn.subscribe(art.Id);
		Ctrl_SubscribeUnsubscribe_Btn.unSubscribe(art.Id);
	}
}