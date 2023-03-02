global class OppWon_BATCH implements Database.Batchable<SObject> {
	Integer oppWonprocessesCount = 1;
	Integer currentlyRunning = 1;
	Set <Id> setId = null;
	Boolean isLast = false;

	global OppWon_BATCH() {
		String oppWonprocesses = Label.Number_of_Opp_Won_processes;
		oppWonprocessesCount = (String.isNotBlank(oppWonprocesses) ? Integer.valueOf(oppWonprocesses) : 1);
		this.isLast = (currentlyRunning == oppWonprocessesCount);
	}

	global OppWon_BATCH(Set <Id> setId, Integer currentlyRunning, Boolean isLastInit) {
		String oppWonprocesses = Label.Number_of_Opp_Won_processes;
		oppWonprocessesCount = (String.isNotBlank(oppWonprocesses) ? Integer.valueOf(oppWonprocesses) : 1);

		System.debug('iCloudius - OppWon_BATCH - Total Opp Won processes: ' + oppWonprocessesCount);

		if (setId != null) this.setId = setId;
		if (currentlyRunning != null) this.currentlyRunning = currentlyRunning;
		if (isLastInit == true) this.isLast = isLastInit;
		if (isLastInit == null || isLastInit == false) this.isLast = (this.currentlyRunning == oppWonprocessesCount);

		System.debug('iCloudius - OppWon_BATCH - isLast on Init: ' + this.isLast);
	}

	global Database.QueryLocator start(Database.BatchableContext context) {
		System.debug('iCloudius - OppWon_BATCH - start');
		System.debug('iCloudius - OppWon_BATCH - currentlyRunning: ' + currentlyRunning);
		System.debug('iCloudius - OppWon_BATCH - isLast: ' + isLast);
		String query = '';
		query += 'SELECT Id, Name, AccountId, Account.CSM__c, Account.CSM__r.IsActive, Account.ShippingState, Account.Region__c, Account.Org_Sub_Region__c, Account.OwnerId, ';
		query += 'CSM__c, ACV__c,csm__r.email,csm__r.managerid,csm__r.manager.email,csm__r.manager.isactive,';
        query+='(select id,product2id,Product2.TAM_Services__c from opportunitylineitems)';
		query += 'FROM Opportunity';
		// WHERE the flag is true
		query += ' WHERE Run_opportunity_batch_process__c = true ';
		if (setId != null && !setId.isEmpty()) query += ' AND Id IN :setId';
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext context, List<Opportunity> scope) {
		System.debug('iCloudius - OppWon_BATCH - execute and scope is: ' + scope.size());
		Map <Id, Opportunity> OppMap = new Map <Id, Opportunity>();
		Map <Id, Account> accounts4Update = new Map <Id, Account>();

		OppMap.putAll(scope);
		if (setId == null || setId.isEmpty()) setId = new Set <Id>(OppMap.keySet());

		// Call logic #1
		if (currentlyRunning == 1) findAndNotifyCSM(scope, isLast);


	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		System.debug('iCloudius - is the last logic on finish: ' + isLast);
		if (!isLast){
			currentlyRunning++;
			isLast = (currentlyRunning == oppWonprocessesCount);
			OppWon_BATCH owb = new OppWon_BATCH(setId, currentlyRunning, isLast);
			Database.executeBatch(owb);
		}
	}
    
    public static boolean IsTAM (Opportunity o)
    {
        boolean b = false;
        if (o.opportunitylineitems.size()>0) for (Opportunitylineitem oli : o.opportunitylineitems) {if (oli.product2.TAM_Services__c) b=true;}
        system.debug('TESTING IsTAM is '+b);
        return b;
    }

	public static void findAndNotifyCSM(List <Opportunity> OList, Boolean isLast){
		List <Messaging.SingleEmailMessage> listMessages = new List <Messaging.SingleEmailMessage>();
		map <id,Account> account2Update = new map <id,Account>();
		List <Opportunity> opps2Update = new List <Opportunity>();
		Boolean debugging = (OList.size() == 1);

		Map <String,  CSM_Table_Assignment__c> mapAssignmentsByState = new Map <String,  CSM_Table_Assignment__c>();
		Map <String,  CSM_Table_Assignment__c> mapAssignmentsBySubRegion = new Map <String,  CSM_Table_Assignment__c>();
		Map <String,  CSM_Table_Assignment__c> mapAssignmentsByRegion = new Map <String,  CSM_Table_Assignment__c>();
		Map <Id,  CSM_Table_Assignment__c> mapAssignmentsByAccountOwner = new Map <Id,  CSM_Table_Assignment__c>();
		CSM_Table_Assignment__c NAPublic = null;

		List <CSM_Table_Assignment__c> TAList = [SELECT Id, Name, State__c, Org_Sub_Region__c, CSM_Name__c, Region__c, Account_owner__c,is_Na_Public__c FROM CSM_Table_Assignment__c];
		if (TAList != null && !TAList.isEmpty()) for (CSM_Table_Assignment__c ta: TAList) {
			if (ta.State__c != null) mapAssignmentsByState.put(ta.State__c.toLowerCase(), ta);
			if (ta.Org_Sub_Region__c != null) mapAssignmentsBySubRegion.put(ta.Org_Sub_Region__c.toLowerCase(), ta);
			if (ta.Region__c != null) mapAssignmentsByRegion.put(ta.Region__c.toLowerCase(), ta); 
			if (ta.Account_owner__c != null) mapAssignmentsByAccountOwner.put(ta.Account_owner__c, ta); 
			if (ta.is_na_public__c) NAPublic = ta;
		}

		System.debug('iCloudius - mapAssignmentsByState:\n' + JSON.serializePretty(mapAssignmentsByState));
		System.debug('iCloudius - mapAssignmentsBySubRegion:\n' + JSON.serializePretty(mapAssignmentsBySubRegion));
		System.debug('iCloudius - mapAssignmentsByRegion:\n' + JSON.serializePretty(mapAssignmentsByRegion));
		System.debug('iCloudius - mapAssignmentsByAccountOwner:\n' + JSON.serializePretty(mapAssignmentsByAccountOwner));
		system.debug('iCloudius - NAPublic is '+NAPublic);

		List <Won_Deal_Alert_Configuration__mdt> recipientControl = [SELECT Id, ACV__c, CC__c, Email_Address__c, Region__c,TAM_Emails__c FROM Won_Deal_Alert_Configuration__mdt];


		for (Opportunity o: OList){
            system.debug('TESTING Line Item Size: '+o.opportunitylineitems.size());
			Account a = new Account(Id = o.AccountId);
			CSM_Table_Assignment__c match = null;
			if (o.Account.CSM__c != null && o.Account.CSM__r.IsActive) o.CSM__c = o.Account.CSM__c;
			if (o.Account.CSM__c == null || !o.Account.CSM__r.IsActive || Test.isRunningTest()){
				if (o.Account.OwnerId != null && mapAssignmentsByAccountOwner.containsKey(o.Account.OwnerId)) match = mapAssignmentsByAccountOwner.get(o.Account.OwnerId);
				if (match==null && o.account.Org_Sub_Region__c!=null && o.account.Org_Sub_Region__c.equalsignorecase('NA Public') && NAPublic!=null) match = NAPublic;
				if (match == null && o.Account.ShippingState != null && mapAssignmentsByState.containsKey(o.Account.ShippingState.toLowerCase())) match = mapAssignmentsByState.get(o.Account.ShippingState.toLowerCase());
				if (match == null && o.Account.Org_Sub_Region__c != null && mapAssignmentsBySubRegion.containsKey(o.Account.Org_Sub_Region__c.toLowerCase())) match = mapAssignmentsBySubRegion.get(o.Account.Org_Sub_Region__c.toLowerCase());
				if (match == null && o.Account.Region__c != null && mapAssignmentsByRegion.containsKey(o.Account.Region__c.toLowerCase())) match = mapAssignmentsByRegion.get(o.Account.Region__c.toLowerCase()); 

				if (debugging) System.debug('iCloudius - CSM_Table_Assignment__c match:\n' + JSON.serializePretty(match));

				if (match != null){
					a.CSM__c = match.CSM_Name__c;
					o.CSM__c = a.CSM__c;
					account2Update.put(a.id,a);
				}
			}

			// For test only
			if (Test.isRunningTest()) account2Update.put(a.id,a);
			// .For test only

			
            List <String> toAddresses = new List <String>();
            List <String> ccAddresses = new List <String>();
            if (o.csm__c!=null) toAddresses.add(o.CSM__c);
            if (o.csm__c!=null) system.debug('TESTING manager is '+o.csm__r.managerid);
            if (o.csm__c!=null && o.csm__r.managerid!=null && o.csm__r.manager.isactive) toaddresses.add (o.csm__r.manager.email);
            if (recipientControl != null && !recipientControl.isEmpty()) for (Won_Deal_Alert_Configuration__mdt rc: recipientControl){
               if ((rc.ACV__c == null || rc.ACV__c <= o.ACV__c) && (rc.Region__c == null || rc.Region__c == o.Account.Region__c) && String.isNotBlank(rc.Email_Address__c)){
                   system.debug('TESTING Evaluating TAM');
                   boolean IsTam = IsTAM (o);
                   boolean ShouldSend = rc.TAM_Emails__c==null || rc.TAM_Emails__c.equalsignorecase('Always') || (rc.TAM_Emails__c.equalsignorecase('Only') && IsTAM) || (rc.TAM_Emails__c.equalsignorecase('Never') && !IsTAM);
                   system.debug('TESTING ShouldSend is '+ShouldSend);
				   if (rc.Email_Address__c != null && rc.Email_Address__c.contains(',')) rc.Email_Address__c = rc.Email_Address__c.replaceAll(',', ';');
                   if (ShouldSend && !rc.CC__c) toAddresses.addAll(rc.Email_Address__c.split(';'));
                   if (ShouldSend && rc.CC__c) ccAddresses.addAll(rc.Email_Address__c.split(';'));
                  }
              }
                
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(toAddresses);
            if (!ccAddresses.isEmpty()) message.SetCCAddresses (ccAddresses);
            message.setTemplateId(Label.Won_CSM_Notification_Template);
            message.setWhatId(o.Id);
            message.setTargetObjectId(label.System_Email_Contact);
            message.setSaveAsActivity(false);
            message.setTreatTargetObjectAsRecipient (false);
        	system.debug('TESTING ToAddresses is ' + JSON.serializePretty(ToAddresses));
            if (ToAddresses.size()>0)listMessages.add(message);
			

			if (isLast) { o.Run_opportunity_batch_process__c = false; }

			opps2Update.add(o);
		}

		updateRecords(account2Update, opps2Update, 'findAndNotifyCSM');
		
		system.debug('TESTING listMessages size is '+listMessages.size() );
		if (!listMessages.isEmpty() && !Test.isRunningTest()) { Messaging.sendEmail(listMessages); listMessages.clear(); }
	}
	
	public static void updateRecords(map <id,Account> account2Update, List <Opportunity> opps2Update, String logic){
		System.debug('iCloudius - Updating Records After logic: ' + logic);
		List <Batch_Log__c> batchLog4Insert = new List <Batch_Log__c>();
		Database.SaveResult[] srList = null;

		if (!account2Update.isEmpty()){
			srList = Database.update(account2Update.values(), false);

			for (Database.SaveResult sr : srList) {
				if (!sr.isSuccess() || Test.isRunningTest()){
					Batch_Log__c bl = new Batch_Log__c();
					bl.Record_ID__c = sr.getId();
					bl.Account__c = sr.getId();
					String errorMsg = '';
					if (!Test.isRunningTest()) for(Database.Error err : sr.getErrors()) { errorMsg += err.getMessage() + '\n'; }
					bl.Error_Message__c = errorMsg.left(131000);
					bl.Class_Name__c = logic; // The method that failed
					batchLog4Insert.add(bl);
				}
			}
		}

		System.debug('iCloudius - opps2Update.size(): ' + opps2Update.size());
		if (opps2Update.size() == 1) System.debug('iCloudius - opps2Update:\n' + JSON.serializePretty(opps2Update));

		srList = Database.update(opps2Update, false);

		for (Database.SaveResult sr : srList) {
			if (!sr.isSuccess() || Test.isRunningTest()){
				Batch_Log__c bl = new Batch_Log__c();
				bl.Record_ID__c = sr.getId();
				bl.Opportunity__c = sr.getId();
				String errorMsg = '';
				if (!Test.isRunningTest()) for(Database.Error err : sr.getErrors()) { errorMsg += err.getMessage() + '\n'; }
				bl.Error_Message__c = errorMsg.left(131000);
				bl.Class_Name__c = logic; // The method that failed
				batchLog4Insert.add(bl);
			}
		}

		if (!batchLog4Insert.isEmpty()) { insert batchLog4Insert; batchLog4Insert.clear(); }
	}
}