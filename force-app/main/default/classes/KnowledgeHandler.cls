public without sharing class KnowledgeHandler {
	public static Map <Id, Knowledge__kav> OldMap = new Map <Id, Knowledge__kav>();
	public static string event = null;

	static Map <String, List <CX_Knowledge_Subscription_Info__c>> mapKnowledgeSubscriptions = new Map <String, List <CX_Knowledge_Subscription_Info__c>>();
	public static Map <Id, CX_Knowledge_Subscription_Info__c> knowledgeSubscriptions4Update = new Map <Id, CX_Knowledge_Subscription_Info__c>();

	public static void genData (List <Knowledge__kav> LKnow){
		System.debug('iCloudius - KnowledgeHandler genData - fired');
		Set <String> setId = new Set <String>();
		for (Knowledge__kav k: LKnow){
			if (k.KnowledgeArticleId != null) setId.add(String.valueOf(k.KnowledgeArticleId));
		}
		if (!setId.isEmpty()){
			List <CX_Knowledge_Subscription_Info__c> ls = [SELECT Id, Article_Id__c FROM CX_Knowledge_Subscription_Info__c WHERE Article_Id__c IN :setId];
			if (ls != null && !ls.isEmpty()) for (CX_Knowledge_Subscription_Info__c s: ls){
				if (!mapKnowledgeSubscriptions.containsKey(s.Article_Id__c)) mapKnowledgeSubscriptions.put(s.Article_Id__c, new List <CX_Knowledge_Subscription_Info__c>());
				mapKnowledgeSubscriptions.get(s.Article_Id__c).add(s);
			}
		}
	}

	public static void handleBefoe(List <Knowledge__kav> LKnow, Map <Id, Knowledge__kav> oldtriggermap, string evnt){
		if (evnt != null) event = evnt;
		if (oldtriggermap != null) OldMap = oldtriggermap;

		genData(LKnow);

	}

	public static void genDataAfter (List <Knowledge__kav> LKnow){
		System.debug('iCloudius - KnowledgeHandler genDataAfter - fired');
	}

	public static void updateSubscription(Knowledge__kav k){
		for (CX_Knowledge_Subscription_Info__c ks: mapKnowledgeSubscriptions.get(String.valueOf(k.KnowledgeArticleId))){
			if (knowledgeSubscriptions4Update.containsKey(ks.Id)) ks = knowledgeSubscriptions4Update.get(ks.Id);
			ks.Article__c = k.Id;
			knowledgeSubscriptions4Update.put(ks.Id, ks);
		}
	}

	public static Boolean updateSubscriptionREQ(Knowledge__kav k){
		Boolean b = false;
		if (event == 'Insert' && k.KnowledgeArticleId != null && mapKnowledgeSubscriptions.containsKey(String.valueOf(k.KnowledgeArticleId))) b = true;
		if (event == 'Update' && k.KnowledgeArticleId != null && OldMap.get(k.Id).KnowledgeArticleId == null) b = true;
		System.debug('iCloudius - updateSubscriptionREQ: ' + b);
		return b;
	}

	public static void updateSubscription(List <Knowledge__kav> LKnow){
		for(Knowledge__kav k: LKnow) if (updateSubscriptionREQ(k)) updateSubscription(k);
	}

	public static void handleAfter(List <Knowledge__kav> LKnow){
		genDataAfter(LKnow);

		updateSubscription(LKnow);

		System.debug('iCloudius - ***************** DML *****************');
		Utils.CodeOff = true;

		System.debug('iCloudius - knowledgeSubscriptions4Update.size: ' + knowledgeSubscriptions4Update.size());
		if (!knowledgeSubscriptions4Update.isEmpty()) { update knowledgeSubscriptions4Update.values(); knowledgeSubscriptions4Update.clear(); }

		Utils.CodeOff = false;
	}
}