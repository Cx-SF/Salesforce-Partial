public class Ctrl_SubscribeUnsubscribe_Btn  {
	
	@AuraEnabled
	public static Map <String, Object> getAll(Id articleId){
		Map <String, Object> mso = new Map <String, Object>();
		String customerServiceProfile = Label.Checkmarx_Customer_Service_Community_Profile;
		String CommunityPortalId = Label.ActiveCommunity;
		String communityBaseURL = '';
		if (String.isNotBlank(CommunityPortalId)) communityBaseURL = Network.getLoginUrl(CommunityPortalId);
		if (String.isNotBlank(communityBaseURL)) communityBaseURL = communityBaseURL.replace('login', '');
		Id customerServiceProfileId = Id.valueOf(customerServiceProfile);
		Boolean subscribe = false;
		Boolean unSubscribe = false;
		Boolean specialSubscribe = false;

		if (articleId != null && (UserInfo.getProfileId() != customerServiceProfileId)){
			List <CX_Knowledge_Subscription_Info__c> lksi = [SELECT Id FROM CX_Knowledge_Subscription_Info__c WHERE 
																	Article__c = :articleId AND Contact_Name__c = :UserInfo.getUserId() AND Action_End_Date_Time__c = null AND 
																	Action_Type__c = 'Subscribe'];
			subscribe = (lksi == null || lksi.isEmpty());
			unSubscribe = (lksi != null && !lksi.isEmpty());
		}

		if (articleId != null && UserInfo.getProfileId() == customerServiceProfileId) specialSubscribe = true;

		if (articleId != null){
			List <Knowledge__kav> lk = [SELECT Id, Title, UrlName FROM Knowledge__kav WHERE Id =:articleId];
			if (lk != null && !lk.isEmpty()) mso.put('article', lk[0]);
		}
		mso.put('subscribe', subscribe);
		mso.put('unSubscribe', unSubscribe);
		mso.put('specialSubscribe', specialSubscribe);
		mso.put('communityBaseURL', communityBaseURL);

		System.debug('iCloudius - Initial Data:\n' + JSON.serializePretty(mso));
		return mso;
	}

	@AuraEnabled
	public static String subscribe(Id articleId){
		String res = 'success';
		List <Knowledge__kav> lk = [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE Id = :articleId];
		if (lk != null && !lk.isEmpty()){
			CX_Knowledge_Subscription_Info__c ksi = new CX_Knowledge_Subscription_Info__c ();
			ksi.Article__c = articleId;
			ksi.Article_Id__c = lk[0].KnowledgeArticleId;
			ksi.Contact_Name__c = UserInfo.getUserId();
			ksi.Action_Start_Date_Time__c = Datetime.now();
			try{
				insert ksi;
			} catch (Exception ex) { System.debug('iCloudius - Exception while subscribing: ' + ex.getStackTraceString()); res = ex.getMessage(); }
			System.debug('iCloudius - Subscribe response: ' + res);
		} else { res = 'Master article not found'; }
		return res;
	}

	@AuraEnabled
	public static String unSubscribe(Id articleId){
		String res = 'success';
		List <CX_Knowledge_Subscription_Info__c> lksi = [SELECT Id FROM CX_Knowledge_Subscription_Info__c WHERE 
																	Article__c = :articleId AND Contact_Name__c = :UserInfo.getUserId() AND Action_End_Date_Time__c = null/* AND 
																	Action_Type__c = 'Subscribe'*/];
		if (lksi != null && !lksi.isEmpty()){
			lksi[0].Action_End_Date_Time__c = Datetime.now();
			try{
				update lksi[0];
			} catch (Exception ex) { System.debug('iCloudius - Exception while unsubscribing: ' + ex.getStackTraceString()); res = ex.getMessage(); }
		}
		System.debug('iCloudius - Unsubscribe response: ' + res);
		return res;
	}
}