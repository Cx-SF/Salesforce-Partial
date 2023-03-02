global class subscriptionNotification_Batch implements Database.Batchable<SObject>, Database.Stateful {
	
	private Set <Id> setId = null;
	private Datetime fromDate = null;
	private Datetime toDate = null;
	private String fromDateOperator = '';
	private String toDateOperator = '';

	Map <Id, Set<Id>> mapArticleIdtoSetUserIds = new Map <Id, Set<Id>>();
	Map <Id, Id> mapArtical2ArticleVer = new Map <Id, Id>();
	Map <Id, String> mapUserId2Error = new Map <Id, String>();
	
	global subscriptionNotification_Batch(){}

	global subscriptionNotification_Batch(Set <Id> setId, Datetime fromDate, String fromDateOperator, Datetime toDate, String toDateOperator) {
		if (setId != null) this.setId = setId;
		if (fromDate != null) this.fromDate = fromDate;
		if (String.isNotBlank(fromDateOperator)) this.fromDateOperator = fromDateOperator;
		if (toDate != null) this.toDate = toDate;
		if (String.isNotBlank(toDateOperator)) this.toDateOperator = toDateOperator;
	}
	
	global Database.QueryLocator start(Database.BatchableContext context) {
		System.debug('iCloudius - subscriptionNotification_Batch - Start');
		String query = 'SELECT Id, Name, Article__c, Article__r.KnowledgeArticleId, Contact_Name__c, Action_End_Date_Time__c FROM CX_Knowledge_Subscription_Info__c WHERE Article__r.Notify_Users__c = true AND Contact_Name__r.IsActive = true AND Action_End_Date_Time__c = null';
		if (setId != null && !setId.isEmpty()) query += ' AND Article__c IN :setId';
		if ((setId == null || setId.isEmpty()) && fromDate != null && String.isNotBlank(fromDateOperator)) query += ' AND LastPublishedDate__c ' + fromDateOperator + ' :fromDate';
		if ((setId == null || setId.isEmpty()) && toDate != null && String.isNotBlank(fromDateOperator)) query += ' AND LastPublishedDate__c ' + toDateOperator + ' :toDate';
		if ((fromDate == null || String.isBlank(fromDateOperator)) && (toDate == null || String.isBlank(toDateOperator)) && setId == null && !Test.isRunningTest()) query += ' AND LastPublishedDate__c = TODAY';

		System.debug('iCloudius - subscriptionNotification_Batch query: ' + query);
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext context, List<CX_Knowledge_Subscription_Info__c> scope) {
		System.debug('iCloudius - subscriptionNotification_Batch - execute and scope is: ' + scope.size());
		Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> ();
		Messaging.SendEmailResult[] results = null;
		OrgWideEmailAddress[] owea = null;
		Map <Id, User> userMap = new Map <Id, User>();
		List <String> tmpCustomerServiceCommunityProfileIds = null;
		Set <Id> CustomerServiceCommunityProfileIds = new Set <Id>();
		if (Label.Customer_Service_Community_Profiles_List != null) tmpCustomerServiceCommunityProfileIds = Label.Customer_Service_Community_Profiles_List.split(';');
		if (tmpCustomerServiceCommunityProfileIds != null && !tmpCustomerServiceCommunityProfileIds.isEmpty()) for (String s: tmpCustomerServiceCommunityProfileIds) CustomerServiceCommunityProfileIds.add(s.trim());
		Set <Id> userIds = new Set <Id>();
		for (CX_Knowledge_Subscription_Info__c ksi: scope) {
			if (!mapArticleIdtoSetUserIds.containsKey(ksi.Article__r.KnowledgeArticleId)) mapArticleIdtoSetUserIds.put(ksi.Article__r.KnowledgeArticleId, new Set <Id>());
			mapArticleIdtoSetUserIds.get(ksi.Article__r.KnowledgeArticleId).add(ksi.Contact_Name__c);
			userIds.add(ksi.Contact_Name__c);
			mapArtical2ArticleVer.put(ksi.Article__r.KnowledgeArticleId, ksi.Article__c);
		}

		if (!userIds.isEmpty()){
			List <User> lu = [SELECT Id, Name, Email, ProfileId FROM User WHERE Id IN :userIds];
			if (lu != null && !lu.isEmpty()) userMap.putAll(lu);
		}

		if (!mapArticleIdtoSetUserIds.isEmpty()){
			List <Subscription_Notification_Alert__mdt> lmd = [SELECT Id, Body__c, Subject__c, X1st_param__c, X2nd_param__c, Set_default_sender__c, Organization_Wide_Email_Address__c, 
																	  URL_to_logo__c, Body_for_APP__c 
															   FROM Subscription_Notification_Alert__mdt WHERE DeveloperName = 'Batch_template'];
			if (lmd != null && !lmd.isEmpty()){
				Subscription_Notification_Alert__mdt md = lmd[0];
				if (md.Set_default_sender__c == true && String.isNotBlank(md.Organization_Wide_Email_Address__c)){
					owea = [select Id from OrgWideEmailAddress where Address = :md.Organization_Wide_Email_Address__c];
				}
				Map <String, String> mss = new Map <String, String>();
				List <Id> verIds = mapArtical2ArticleVer.values();
				String URLtoLogo = md.URL_to_logo__c;
				String baseMailSubject = md.Subject__c;
				String baseMailBody = md.Body__c;
				String baseMailBodyForApp = md.Body_for_APP__c;
				String currentHTMLBodyHeader = '<table width="464"><tr><td align="center" style="border-bottom: 2px solid #33cc00; padding-bottom: 8px;"><img src="' + URLtoLogo + '" /></td></tr><tr><td style="padding: 8px 6px;">';
				String currentHTMLBodyFooter = '</td></tr></table>';
				String q = 'SELECT ';
				if (String.isNotBlank(md.X1st_param__c)) { q += md.X1st_param__c.substringAfter('.').substringBefore('}'); mss.put(md.X1st_param__c, md.X1st_param__c.substringAfter('.').substringBefore('}')); }
				if (String.isNotBlank(md.X2nd_param__c)) { q += (q == 'SELECT ' ? '' : ', ') + md.X2nd_param__c.substringAfter('.').substringBefore('}'); mss.put(md.X2nd_param__c, md.X2nd_param__c.substringAfter('.').substringBefore('}')); }
				if (!q.containsIgnoreCase('id')) q += ', Id';
				q += ', IsVisibleInApp, IsVisibleInPkb, IsVisibleInPrm, IsVisibleInCsp FROM Knowledge__kav WHERE Id In :verIds';

				System.debug('iCloudius - Metadata query: ' + q);

				List <Knowledge__kav> lkav = (List <Knowledge__kav>)Database.query(q);
				Map <Id, Knowledge__kav> mapVer = new Map <Id, Knowledge__kav>();
				mapVer.putAll(lkav);

				for (Id artId: mapArticleIdtoSetUserIds.keySet()) for (Id uId: mapArticleIdtoSetUserIds.get(artId)) {
					System.debug('iCloudius - Creating notification Email');
					Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
					String currentSubject = baseMailSubject;
					String currentBody = baseMailBody;
					String currentHTMLBody = baseMailBody;
					if (userMap.containsKey(uId) && (CustomerServiceCommunityProfileIds.isEmpty() || !CustomerServiceCommunityProfileIds.contains(userMap.get(uId).ProfileId))) {
						currentBody = baseMailBodyForApp;
						currentHTMLBody = baseMailBodyForApp;
					}
					currentHTMLBody = currentHTMLBody.replaceAll('[\\n]', '<br />');
					currentHTMLBody = currentHTMLBody.replaceAll('[\\r]', '');

					for (String s: mss.keySet()){
						String replaceStr = (String)mapVer.get(mapArtical2ArticleVer.get(artId)).get(mss.get(s));
						if (currentSubject.contains(s)) currentSubject = currentSubject.replace(s, replaceStr);
						if (currentBody.contains(s)) currentBody = currentBody.replace(s, replaceStr);
						if (currentHTMLBody.contains(s)) currentHTMLBody = currentHTMLBody.replace(s, replaceStr);
					}

					currentHTMLBody = currentHTMLBodyHeader + currentHTMLBody + currentHTMLBodyFooter;

					if(Test.isRunningTest()) System.debug('iCloudius - Current Subject: ' + currentSubject);
					if(Test.isRunningTest()) System.debug('iCloudius - Current Body: ' + currentBody);

					message.setSaveAsActivity(false);
					message.setToAddresses(new List <String> { String.valueOf(uId) });
					message.setSubject(currentSubject);
					message.setPlainTextBody(currentBody);
					message.setHtmlBody(currentHTMLBody);
					message.setTargetObjectId(uId);

					if (owea != null && !owea.isEmpty() && owea[0].Id != null) message.setOrgWideEmailAddressId(owea[0].Id);

					messages.add(message);
				}
			}
		}

		System.debug('iCloudius - messages to send: ' + messages.size());
		if (!messages.isEmpty() && !Test.isRunningTest()) results = Messaging.sendEmail(messages);
		if (results != null && !results.isEmpty()){
			for (Messaging.SendEmailResult r: results) if (!r.isSuccess()) { mapUserId2Error.put(r.getErrors()[0].getTargetObjectId(), r.getErrors()[0].getMessage()); } else if (messages.size() < 10) { System.debug('iCloudius - Email sent successfully'); }
		}
	}
	
	global void finish(Database.BatchableContext context) {
		System.debug('iCloudius - subscriptionNotification_Batch - Finish');
		List <Subscription_Notifications_Logs__c> logs4Insert = new List <Subscription_Notifications_Logs__c>();
		List <Subscribed_Users_List__c> su4Insert = new List <Subscribed_Users_List__c>();
		Id jobId = context.getJobId();
		//AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :context.getJobId()];
		if (!mapArticleIdtoSetUserIds.isEmpty()){
			for (Id artId: mapArticleIdtoSetUserIds.keySet()){
				Subscription_Notifications_Logs__c snl = new Subscription_Notifications_Logs__c();
				snl.Batch_Id__c = jobId;
				snl.Batch_Execution_Date__c = Date.today();
				snl.Article_Id__c = artId;
				logs4Insert.add(snl);
			}
			
			System.debug('iCloudius - logs4Insert size: ' + logs4Insert.size());
			if (!logs4Insert.isEmpty()){
				insert logs4Insert;
				for (Subscription_Notifications_Logs__c l: logs4Insert){
					if (mapArticleIdtoSetUserIds.containsKey(l.Article_Id__c) && !mapArticleIdtoSetUserIds.get(l.Article_Id__c).isEmpty()) for (Id uId: mapArticleIdtoSetUserIds.get(l.Article_Id__c)){
						Subscribed_Users_List__c su = new Subscribed_Users_List__c();
						su.Subscription_Notifications_Logs__c = l.Id;
						su.Contact_Name__c = uId;
						su.Status__c = (!mapUserId2Error.containsKey(uId) ? 'Success' : mapUserId2Error.get(uId));
						su4Insert.add(su);
					}
				}

				System.debug('iCloudius - su4Insert size: ' + su4Insert.size());
				if (!su4Insert.isEmpty()) insert su4Insert;
			}
		}
	}
}