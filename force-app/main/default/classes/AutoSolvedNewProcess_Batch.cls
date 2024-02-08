/*
	Date: 01/001/2024
	Developer Name : Refael Dabush
	Version : 1.0
	Class functionality - update case, insert Post chatter and sending emails
*/

public class AutoSolvedNewProcess_Batch implements Database.Batchable<sObject>, Database.Stateful {
	List<Auto_Solved_process_New__mdt> autoSolvedMTD = [Select First_Reminder_Recipients__c, From_Email_Address__c, First_Reminder_TemplateId__c, First_PostToChatter_Body__c, Second_Reminder_Recipients__c, Second_Reminder_TemplateId__c, Second_PostToChatter_Body__c from Auto_Solved_process_New__mdt];
	OrgWideEmailAddress[] owea = [select Id,DisplayName from OrgWideEmailAddress where Address =: autoSolvedMTD[0].From_Email_Address__c];

	public Database.QueryLocator start(Database.BatchableContext BC){
		set<String> ExcludeRTNames = new set<String>();
		for(Auto_Solved_Process_Exclude_RecordType__mdt ExcludeRT : [SELECT RecordTypeName__c FROM Auto_Solved_Process_Exclude_RecordType__mdt]){
            ExcludeRTNames.add(ExcludeRT.RecordTypeName__c);
        }

		Map<Id, RecordType> RtIds = new Map<Id, RecordType>([SELECT id FROM RecordType WHERE DeveloperName IN :ExcludeRTNames AND SobjectType='Case']);
		if(Test.isRunningTest()){
			return Database.getQueryLocator([Select id, ContactId, SuppliedEmail, ContactEmail, CSM_Email__c, Account_CSM__c, Cx_Pending_Customer_Action__c from Case]);
		}
		return Database.getQueryLocator([Select id, ContactId, SuppliedEmail, ContactEmail, CSM_Email__c, Account_CSM__c, Cx_Pending_Customer_Action__c from Case where RecordTypeId NOT IN : RtIds.keySet() AND Status = 'Pending_Customer' AND (((Cx_Pending_Customer_Action__c = 'In progress' AND Cx_Pending_Customer_Status_Change_Date__c = N_DAYS_AGO: 7) OR (Cx_Pending_Customer_Action__c='Pending First Reminder' AND Cx_Pending_Customer_Required_Attention__c=True)) OR (Cx_Pending_Customer_Action__c='First Reminder Sent' AND Cx_Pending_Customer_Last_Reminder_Date__c = N_DAYS_AGO: 7) OR (Cx_Pending_Customer_Action__c='Pending Second Reminder' AND Cx_Pending_Customer_Required_Attention__c=True))]);

	}

	public void execute(Database.BatchableContext BC, List<Case> scope){
		Map<Id, Case> case4Update = new Map<Id, Case>();
		List<feedItem> feedItem2Insert = new List<feedItem>();
		List<Pending_Customer_Logs__c> pcLogsList = new List<Pending_Customer_Logs__c>();
		Map<String, List<Case>> caseMap = new Map<String, List<Case>>();

		List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
		for(case c : scope){
			if(c.Cx_Pending_Customer_Action__c == 'In progress' || c.Cx_Pending_Customer_Action__c == 'Pending First Reminder'){
				if(caseMap.get('firstReminder') == null){
					caseMap.put('firstReminder', new List<Case>{c});
				}else{
					caseMap.get('firstReminder').add(c);
				}
			}else{
				if(caseMap.get('secondReminder') == null){ 
					caseMap.put('secondReminder', new List<Case>{c});
				}else{
					caseMap.get('secondReminder').add(c);
				}
			}
		}

		// crate emails firest and secound reminder
		if(caseMap.containsKey('firstReminder')){
			for(case c : caseMap.get('firstReminder')){
				emailList.add(buildEmailMessage(c, 1));
			}
		}

		if(caseMap.containsKey('secondReminder')){
			for(case c : caseMap.get('secondReminder')){
				emailList.add(buildEmailMessage(c, 2));
			}
		}

		// send emails and save error
		List<String> emailErrorContactIdList = new List<String>();
		if(!emailList.isEmpty() && !Test.isRunningTest()){
			Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
			for(Messaging.SendEmailResult res : results){
				if(!res.isSuccess()){
					Messaging.SendEmailError[] errList = res.getErrors();
					emailErrorContactIdList.add(errList[0].getTargetObjectId());
				}
			}
		}

		// update case and crate post chatter - firse reminder
		if(caseMap.containsKey('firstReminder')){
			for(case c : caseMap.get('firstReminder')){
				if(!emailErrorContactIdList.contains(String.valueOf(c.ContactId))){
					feedItem2Insert.add(chatterpost(c, 1));
					c.Cx_Pending_Customer_Action__c = 'First Reminder Sent';
					c.Cx_Pending_Customer_Last_Reminder_Date__c = Date.today();
				}else {
					if(c.Cx_Pending_Customer_Action__c != 'Pending First Reminder'){
						c.Cx_Pending_Customer_Action__c = 'Pending First Reminder';
					}
				}
				case4Update.put(c.Id, c);
			}
		}

		// update case and crate post chatter - firse reminder
		if(caseMap.containsKey('secondReminder')){
			for(case c : caseMap.get('secondReminder')){
				if(!emailErrorContactIdList.contains(String.valueOf(c.ContactId))){
					feedItem2Insert.add(chatterpost(c, 2));
					c.Cx_Pending_Customer_Action__c = 'Second Reminder Sent';
					c.Cx_Pending_Customer_Last_Reminder_Date__c = Date.today();
					c.Is_auto_closed__c = true;
					c.Status = 'Solved';

					Pending_Customer_Logs__c log = new Pending_Customer_Logs__c();
					Log.Case_Status__c = 'Pending Customer';
					Log.Case__c = c.Id;
					log.New_Pending_Customer_Action__c = 'Second Reminder Sent';
					log.Previous_Pending_Customer_Action__c = 'Pending Secound Reminder';
					pcLogsList.add(log);
				}else {
					if(c.Cx_Pending_Customer_Action__c != 'Pending Second Reminder'){
						c.Cx_Pending_Customer_Action__c = 'Pending Second Reminder';
					}
				}
				case4Update.put(c.Id, c);
			}
		}


		System.debug('Rafa - case4Update size: ' + case4Update.size());
		System.debug('Rafa - feedItem2Insert size: ' + feedItem2Insert.size());
		System.debug('Rafa - pcLogsList size: ' + pcLogsList.size());

		if(!case4Update.isEmpty()) update case4Update.values();
		if(!feedItem2Insert.isEmpty()) insert feedItem2Insert;
		if(!pcLogsList.isEmpty()) insert pcLogsList;
	}

	public void finish(Database.BatchableContext BC){
		System.debug('AutoSilvedNewProcess_Batch - finish');
	}

	// build Email
	private Messaging.SingleEmailMessage buildEmailMessage(case c, Integer reminder){
		Messaging.SingleEmailMessage emil = new Messaging.SingleEmailMessage();
		List<String> addresses = new List<String>();
		List<String> addFiledList;
		if(reminder == 1) addFiledList = autoSolvedMTD[0].First_Reminder_Recipients__c.split(';');
		if(reminder == 2) addFiledList = autoSolvedMTD[0].Second_Reminder_Recipients__c.split(';');
		for(String str : addFiledList){
			if(String.isNotBlank(String.valueOf(c.get(str)))){
				addresses.add(String.valueOf(c.get(str)));
			}
		}
		if(String.isNotBlank(c.ContactId)){
			emil.setTargetObjectId(c.ContactId);
		}

		emil.setWhatId(c.Id);
		if(reminder == 1) emil.setTemplateId(autoSolvedMTD[0].First_Reminder_TemplateId__c);
		if(reminder == 2) emil.setTemplateId(autoSolvedMTD[0].Second_Reminder_TemplateId__c);
		emil.setOrgWideEmailAddressId(owea[0].Id);
		emil.setToAddresses(addresses);
		return emil;
	}

	// crate post chatter
	private FeedItem chatterpost(case c, integer reminder){
		String body;
		FeedItem  post = new FeedItem();
		post.ParentId = c.Id;
		if(reminder == 1) body = autoSolvedMTD[0].First_PostToChatter_Body__c;
		if(reminder == 2) body = autoSolvedMTD[0].Second_PostToChatter_Body__c;
		post.Body = body;
		return post;	
	}
}