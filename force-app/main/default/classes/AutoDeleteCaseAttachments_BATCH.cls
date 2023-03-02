global class AutoDeleteCaseAttachments_BATCH implements Database.Batchable<SObject> {
	
	Set <Id> setId;
	global date todaydate = null;
	global AutoDeleteCaseAttachments_BATCH() {}
	global AutoDeleteCaseAttachments_BATCH(date d) {todaydate = d;}
	global AutoDeleteCaseAttachments_BATCH(Set <Id> setId) { if (setId != null && !setId.isEmpty()) this.setId = setId; }
	global AutoDeleteCaseAttachments_BATCH(Set <Id> setId, date d) {todaydate = d; if (setId != null && !setId.isEmpty()) this.setId = setId; }
	
	
	global Database.QueryLocator start(Database.BatchableContext context) {
		System.debug('iCloudius - AutoDeleteCaseAttachments_BATCH - Start. todaydate is '+todaydate);
		if (todaydate ==null) todaydate  = date.today();
		system.debug('todaydate set to '+todaydate);
		
		set <string> excluderectypes = new set <string>();
		for (string s : label.AutoDeleteCases_ExcludeRecordTypes.split(';')) excluderectypes.add (s);
		system.debug('TESTING excluderectypes is '+excluderectypes);
		
		String query = 'SELECT Id, ClosedDate, CX_Manually_Delete_Attachments__c, AccountId, Account.CX_Days_to_Delete_Attachments_from_Case__c FROM Case';
		String whereQ = 'WHERE Status = \'Closed\' AND (CX_Manually_Delete_Attachments__c = TRUE OR Delete_Attachment_Date__c =: todaydate) ';
		if (excluderectypes.size()>0) whereQ+=' AND recordtype.developername NOT IN:excluderectypes';
		//whereQ += 'AND Account.CX_Days_to_Delete_Attachments_from_Case__c != null AND ClosedDate != NULL))';
		if (!Test.isRunningTest()) query += ' ' + whereQ;
		if (!Test.isRunningTest() && setId != null) query += ' AND Id IN :setId';

		return Database.getQueryLocator(query);
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<Case> scope) {
		System.debug('iCloudius - AutoDeleteCaseAttachments_BATCH - execute and scope is: ' + scope.size());
		system.debug('Execute run. todaydate is '+todaydate);
		if (Test.isRunningTest()) System.debug('iCloudius - AutoDeleteCaseAttachments_BATCH - execute and scope is: ' + JSON.serializePretty(scope));
		Date d = Date.today();
		Set <Id> attToDeleteParentId = new Set <Id>();
		for (Case c: scope){attToDeleteParentId.add (c.id);
		    
		    //date reqdate = null;
		    //datetime reqdt = null;
		    
		    //if (c.AccountId != null && c.Account.CX_Days_to_Delete_Attachments_from_Case__c != null  && c.Account.CX_Days_to_Delete_Attachments_from_Case__c != 'Never' && c.ClosedDate != NULL) reqdt = c.ClosedDate.addDays(Integer.valueOf(c.Account.CX_Days_to_Delete_Attachments_from_Case__c));
		    //if (reqdt!=null) reqdate = date.newinstance (reqdt.year(),reqdt.month(),reqdt.day());
		    
		    //system.debug('TESTING reqdt is '+reqdt);
		    //system.debug('TESTING reqdate is '+reqdate);
		    //system.debug('TESTING d is '+d);
		    
			//if (c.CX_Manually_Delete_Attachments__c) attToDeleteParentId.add(c.Id);
			//if (reqdate!=null && reqdate==d) attToDeleteParentId.add(c.Id);
			
		}
		
		system.debug('TESTING attToDeleteParentId is '+attToDeleteParentId);
		
		map <id,Case> Case4Update = new map <id,Case>();

		if (!attToDeleteParentId.isEmpty()){
		    
		    map <id,ContentDocument> CD4Delete = new map <id,ContentDocument>();
		    list <ContentDocumentLink> CDLList = [select id,contentdocumentid,linkedEntityid from ContentDocumentLink where linkedentityid =:attToDeleteParentId];
		    if (CDLList.size()>0) for (ContentDocumentLink cdl : CDLList) {ContentDocument cd = new ContentDocument (id = cdl.contentdocumentid); CD4Delete.put (cd.id,cd); Case c = new Case (id = cdl.linkedentityid, CX_Attachments_Deleted_Automatically__c= true); Case4Update.put (c.id,c);}
		    
			List <Attachment> la = [SELECT Id,parentid FROM Attachment WHERE ParentId IN :attToDeleteParentId];
			if (la != null && !la.isEmpty()) {
				System.debug('iCloudius - Deleting ' + la.size() + ' Attachments');
				delete la;
			}
			
			system.debug('TESTING CD4Delete is '+CD4Delete.size());
			if (CD4Delete.size()>0) {delete CD4Delete.values(); CD4Delete.clear();}
			
			system.debug('TESTING Case4Update is '+Case4Update.size());
			if (Case4Update.size()>0) {update Case4Update.values(); Case4Update.clear();}
		}
	
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		
	}
}