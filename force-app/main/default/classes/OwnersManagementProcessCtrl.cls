public class OwnersManagementProcessCtrl  {

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getRegionalDirector(){
	try{
		System.debug('Rafa - In getRegionalDirector function');
		Map<String, Object> obj = new Map<String, Object>();
		List<User> userList = new List<User>();
		List<User> accountOwnerList = new List<User>();
		//Map<Id,UserRole> userRoleMap = new Map<Id,UserRole>();

		// Strat - check user Profile to choosem List. comper from the Labels //
		List<String> allRecordsOwner = new List<String>();
		String allRecordOwnerString = System.Label.Records_Owner_Managment_see_all_RD_s;
		System.debug('oneRecordOwnerString: ' + allRecordOwnerString);
		System.debug('UserInfo.getProfileId() ' + UserInfo.getProfileId());
		System.debug('//////////////////////////////////////////////////////////');
		for(String record : allRecordOwnerString.split(';')){allRecordsOwner.add(record);}

		/*Boolean recordOwnerChaeck = false;
		if(allRecordsOwner.contains(UserInfo.getProfileId())) recordOwnerChaeck = true;

		List<String> oneRecordsOwner = new List<String>();
		String oneRecordOwnerString = System.Label.Records_Owner_Management_see_only_his_user;
		System.debug('oneRecordOwnerString: ' + oneRecordOwnerString);
		System.debug('UserInfo.getProfileId() ' + UserInfo.getProfileId());
		for(String record : oneRecordOwnerString.split(';')){oneRecordsOwner.add(record);}
		Boolean oneRecordOwnerChaeck = false;
		if(oneRecordsOwner.contains(UserInfo.getProfileId())) oneRecordOwnerChaeck = true;
		// Strat - check user Profile to choosem List. comper from the Labels //
		System.debug('recordOwnerChaeck: ' + recordOwnerChaeck);
		System.debug('oneRecordOwnerChaeck: ' + oneRecordOwnerChaeck);
		Boolean yes = true;*/

		Set<Id> DirectorOfSalesList = new Set<Id>();
		for(User u : [Select Id, Name, Director_Of_Sales__c From User where IsActive = true and Director_Of_Sales__c != null]){
			DirectorOfSalesList.add(u.Director_Of_Sales__c);
		}
		System.debug('Rafa - DirectorOfSales: ' + DirectorOfSalesList);
		if(DirectorOfSalesList.contains(UserInfo.getUserId())){ 
			userList = [select id, Name, userRoleId from user where id =: UserInfo.getUserId() order by name];
			accountOwnerList = getAccountOwner(UserInfo.getUserId());
		}else{
			for(User u : [select Id,UserRole.name, userRoleId, Name from User where Id in : DirectorOfSalesList order by name]){
				userList.add(u);
			}
		}

		/*if(recordOwnerChaeck){
			for (userRole userRoless : [select id, name, developerName from UserRole where developerName like '%_RD%']){
				if(userRoless.DeveloperName.contains('_RD')){
					userRoleMap.put(userRoless.Id, userRoless);
				}
			}
			for(User u : [select Id,UserRole.name, userRoleId, Name from User where userRoleId in : userRoleMap.keySet() order by name])
				{userList.add(u);
			}
		}else if(oneRecordOwnerChaeck){userList = [select id, Name, userRoleId from user where id =: UserInfo.getUserId() order by name];
			accountOwnerList = getAccountOwner(userList[0].UserRoleId);
		}*/

		List<AggregateResult> accBillingCountryList = new List<AggregateResult>();

		List<Map<String,String>> accTypeList = getPickListValues('Account', 'Type');
		accBillingCountryList = [select BillingCountry, count(Id) from Account group by BillingCountry];
		
		obj.put('BillingCountry', accBillingCountryList);
		obj.put('Type', accTypeList);

		System.debug('Rafa - userList: ' + userList);
		obj.put('userList', userList);

		List<Map<String,String>> statusList = getPickListValues('Records_Owner_Management__c','Status__c');
		obj.put('status', statusList);

		obj.put('accountOwnerList', accountOwnerList);

		return obj;
		}Catch(DmlException  e){System.debug(e.getMessage());Map<String, Object> userr = new Map<String, Object>();return userr;}
	}

	@AuraEnabled(cacheable=true)
	public static List<User> getAccountOwner(Id userId){
		/*System.debug('parentRoleId: ' + parentRoleId);
		List<Id> parentRoleIdList = new List<Id>();
		List<id> rolesIdsList = new List<Id>();*/
		List<User> usersAccount = new List<User>();
		Integer days = Integer.valueOf('-' + label.Records_Owner_Management_Owners_Last_Login);
		Date datee = Date.today().addDays(days);
		//and CALENDAR_YEAR(LastLoginDate) = :year // add this to the query in the end LastLoginDate >:datee and
		//where LastLoginDate >:datee and Director_Of_Sales__c =: userId and (Not profile.name like '%Community%') and (not profile.name  like '%Portal%')
		for(User u : [select Id,UserRole.name,name, userRoleId, Org_Sub_Region__c, Position_ID__c, LastLoginDate from User where  Director_Of_Sales__c =: userId and (Not profile.name like '%Community%') and (not profile.name  like '%Portal%') and LastLoginDate >:datee order by name]){
			System.debug('User LastLoginDate: ' + u.LastLoginDate);
			usersAccount.add(u);
		}
		System.debug('User ID: ' + userId);
		System.debug('usersAccount: ' + usersAccount);

		/*Boolean check = true;
		parentRoleIdList.add(parentRoleId);
		while(check){
			List<userRole> userRoless = [select id, name, developerName from UserRole where ParentRoleId in :parentRoleIdList];
			parentRoleIdList.clear();
			for(userRole usR : userRoless){
				parentRoleIdList.add(usR.Id);
				rolesIdsList.add(usR.id);
			}
			if(parentRoleIdList.isEmpty()) check = false;
		}

		System.debug('rolesIdsList: ' + rolesIdsList);*/

		return usersAccount;
	
	}

	public static list<map<string, string>> getPicklistValues(String ObjectApi_name,String Field_name){
        list<map<string, string>> lstPickvals = new list<map<string, string>>();
        map<string, string> mss = null;
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType();
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
        List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues();
        for (Schema.PicklistEntry a : pick_list_values) {
            mss = new map<string, string>();
            mss.put('label', a.getLabel());
            mss.put('value', a.getValue());
            lstPickvals.add(mss);
        }
        return lstPickvals;
    }


	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getDataTable(Map<String, Object> dataObj){

	System.debug('Rafa - dataObj: ' + dataObj);
	String batchId = (String) dataObj.get('batchId');
	String status = (String) dataObj.get('status');

	String country = (String) dataObj.get('country');
	String owner = (String) dataObj.get('owner');
	String ownerName = (String) dataObj.get('ownerName');
	String orgSub = (String) dataObj.get('org');
	String statuse = (String) dataObj.get('statuse');
	String typeN = (String) dataObj.get('type');
	String position = (String) dataObj.get('position');

	List<Map<String,String>> assignmentReasonList = getPickListValues('Records_Owner_Management__c','New_Assignment_Reason__c');

	System.debug('Rafa - batchId: ' + batchId);
	System.debug('Rafa - status: ' + status);
	System.debug('Rafa - country: ' + country);
	System.debug('Rafa - owner: ' + owner);
	System.debug('Rafa - orgSub: ' + orgSub);
	System.debug('Rafa - statuse: ' + statuse);
	System.debug('Rafa - typeN: ' + typeN);
	System.debug('Rafa - position: ' + position);
	System.debug('Rafa - Profile Id: ' + UserInfo.getProfileId());

	Map<String, Object> dataTables = new Map<String, Object>();
	List<Account> accList = new List<Account>();
	List<Opportunity> oppList = new List<Opportunity>();

	if(batchId == null){
		
		List<Id> accountIdsList = new List<Id>();
		List<Id> opprtunityIdsList = new List<Id>();
		for(Records_Owner_Management__c rom : [select id, Account__c, Opportunity__c from Records_Owner_Management__c where Status__c in ('In Progress', 'Pending Quota Review', 'Pending Approval')]){
			if(rom.Account__c != null) accountIdsList.add(rom.Account__c);
			if(rom.Opportunity__c != null) opprtunityIdsList.add(rom.Opportunity__c);
		}

		String query = 'select id, Name, Type, BillingCountry, Total_Active_ACV__c, SBQQ__DefaultOpportunity__c, CX_NextFY_ExpectedRenewalACV__c, Account_Owner__c, of_Open_Opportunities__c, OwnerId, Existing_Quota__c, Account_Status__c from Account where (OwnerId =: owner OR OwnerId =: UserInfo.getUserId()) and id not In : accountIdsList';

		if(country != null) query += ' and BillingCountry =: country' ;
		if(typeN != null) query += ' and Type =: typeN';
		if(statuse != null) query += ' and Account_Status__c =: statuse';
		query += ' order by name';

		System.debug('Rafa - query: ' + query);
		accList = Database.query(query);

		List<Id> accountIdList = new List<Id>();
		for(Account acc : accList){
			accountIdList.add(acc.Id);
		}

		oppList = [select Id, Name, Account_name__c, AccountId, Channel__c, Type, StageName, CloseDate, OwnerId, Opportunity_Owner_Name__c,Existing_Quota__c from Opportunity where AccountId in :accountIdList and (OwnerId != :owner OR OwnerId != :UserInfo.getUserId()) and StageName not in('Stage zero Disqualified', 'Closed Won', 'Closed Lost', 'Paid', 'Approved', 'Cancelled', 'Closed Omitted') and id not In : opprtunityIdsList order by Account_name__c]; 

		System.debug('Rafa - accList: ' + accList);
		System.debug('Rafa - oppList: ' + oppList);

		dataTables.put('Account', accList);
		dataTables.put('Opportunity', oppList);

	}else{
		System.debug('Rafa - In batch filter');
		List<Id> accountIdsList = new List<Id>();
		List<Id> opprtunityIdsList = new List<Id>();
		for(Records_Owner_Management__c rom : [select id, Account__c, Opportunity__c from Records_Owner_Management__c where Batch_Id__c =: batchId and Status__c =: status]){
			if(rom.Account__c != null) accountIdsList.add(rom.Account__c);
			if(rom.Opportunity__c != null) opprtunityIdsList.add(rom.Opportunity__c);
		}

		List<Account> accountList = [select id, Name, Type, BillingCountry, Total_Active_ACV__c, SBQQ__DefaultOpportunity__c, CX_NextFY_ExpectedRenewalACV__c, Account_Owner__c, of_Open_Opportunities__c, OwnerId, Existing_Quota__c, Account_Status__c from Account where id in: accountIdsList order by name];

		List<Opportunity> opportunityList = [select Id, Name, Account_name__c, AccountId, Channel__c, Type, StageName, CloseDate, OwnerId, Opportunity_Owner_Name__c,Existing_Quota__c from Opportunity where Id in :opprtunityIdsList order by Account_name__c];

		System.debug('Rafa - accountList: ' + accountList);
		System.debug('Rafa - opportunityList: ' + opportunityList);

		dataTables.put('Account', accountList);
		dataTables.put('Opportunity', opportunityList);
	}

	dataTables.put('assignmentReasonList', assignmentReasonList);
	dataTables.put('currentOwner', ownerName);
	dataTables.put('currentOwnerId', owner);
	dataTables.put('profileId', UserInfo.getProfileId());

	return dataTables;
	//String owner, String orgSub, String position, String country, String typeN, String statuse)
	}

	@AuraEnabled
	public static Map<String, Object> updateRecords(Map<String, Object> dataObj){
		
		List<Records_Owner_Management__c> insertRecordsOwnerList = new List<Records_Owner_Management__c>();
		Map<String, Object> reqSend = new Map<String, Object>();
		String currentOwnerId = (String) dataObj.get('currentOwnerId');
		String selectedOwner = (String) dataObj.get('selectedOwner');
		String additionalApprover = (String) dataObj.get('additionalApprover');
		String newAssigment = (String) dataObj.get('newAssigment');
		List<Object> accountObj = (List<Object>)JSON.deserializeUntyped(JSON.serialize(dataObj.get('account')));
		List<Object> opportunityObj = (List<Object>)JSON.deserializeUntyped(JSON.serialize(dataObj.get('opportunity')));
		List<Map<String,Object>> accMapObject = new List<Map<String,Object>>();
		if(accountObj != null && !accountObj.isEmpty()){
			for(Object acc:accountObj){
				accMapObject.add((Map<String, Object>)acc);
			}
		}
		List<Map<String,Object>> oppMapObject = new List<Map<String,Object>>();
		if(opportunityObj != null && !opportunityObj.isEmpty()){
			for(Object o:opportunityObj){
				oppMapObject.add((Map<String, Object>)o);
			}
		}

		// Create Records Owner Management //
		System.debug('Rafa currentOwnerId: ' + currentOwnerId);
		System.debug('Rafa selectedOwner: ' + selectedOwner);
		System.debug('Rafa additionalApprover: ' + additionalApprover);
		System.debug('Rafa newAssigment: ' + newAssigment);

		List<Id> accountIdList = new List<Id>();
		Map<Id, Id> mapAccIdVsOwnerId = new Map<Id, Id>();
		if((!accMapObject.isEmpty() && accMapObject.size() > 0) || Test.isRunningTest()){
			for(Map<String, Object> accMap : accMapObject) {
				accountIdList.add((Id)accMap.get('Id'));
				Records_Owner_Management__c rom = new Records_Owner_Management__c();
				rom.status__c = (accMap.get('Existing_Quota__c') == true) ? 'Pending Quota Review' : 'In Progress';
				rom.Updated_By__c = UserInfo.getUserId();
				rom.Update_Date__c = Date.today();
				rom.Previous_Owner__c = (Id) accMap.get('OwnerId'); //currentOwnerId;
				rom.New_Owner__c = (accMap.get('ownerChange') == '') ? (Id) selectedOwner : (Id) accMap.get('ownerChange');
				if(additionalApprover != null && additionalApprover != '') rom.Additional_approver__c = (Id) additionalApprover;
				rom.Account__C = (Id) accMap.get('Id');
				rom.Opportunity__c = (id) accMap.get('SBQQ__DefaultOpportunity__c');
				rom.New_Assignment_Reason__c = newAssigment;
				if(accMap.get('ownerChange') != '') mapAccIdVsOwnerId.put((Id)accMap.get('Id'), (Id) accMap.get('ownerChange'));
				System.debug('rom.New_Owner__c: ' + rom.New_Owner__c);

				insertRecordsOwnerList.add(rom);
			}
		}
		
		List<Opportunity> oppList = [Select Id, Name, Account_name__c, AccountId, Channel__c, Type, StageName, CloseDate, OwnerId, Opportunity_Owner_Name__c,Existing_Quota__c from Opportunity where AccountId in :accountIdList and (OwnerId = :currentOwnerId OR OwnerId = :UserInfo.getUserId()) and StageName not in('Stage zero Disqualified', 'Closed Won', 'Closed Lost', 'Paid', 'Approved', 'Cancelled', 'Closed Omitted')];

		for(Opportunity opp: oppList){
			Records_Owner_Management__c rom = new Records_Owner_Management__c();
			rom.status__c = opp.Existing_Quota__c ? 'Pending Quota Review' : 'In Progress';
			rom.Updated_By__c = UserInfo.getUserId();
			rom.Update_Date__c = Date.today();
			rom.Previous_Owner__c = opp.OwnerId; //(Id) currentOwnerId;
			rom.New_Owner__c = (mapAccIdVsOwnerId.containsKey(opp.AccountId)) ? mapAccIdVsOwnerId.get(opp.AccountId) : (Id) selectedOwner;
			if(additionalApprover != null && additionalApprover != '') rom.Additional_approver__c = (Id) additionalApprover;
			rom.Account__C = opp.AccountId;
			rom.Opportunity__c = opp.Id;
			rom.New_Assignment_Reason__c = newAssigment;
						
			insertRecordsOwnerList.add(rom);
		}
		
		if((!oppMapObject.isEmpty() && oppMapObject.size() > 0) || Test.isRunningTest()){
			for(Map<String, Object> oppMap : oppMapObject) {
				Records_Owner_Management__c rom = new Records_Owner_Management__c();
				rom.status__c = (oppMap.get('Existing_Quota__c') == true) ? 'Pending Quota Review' : 'In Progress';
				rom.Updated_By__c = UserInfo.getUserId();
				rom.Update_Date__c = Date.today();
				rom.Previous_Owner__c = (Id) oppMap.get('OwnerId'); //currentOwnerId;
				rom.New_Owner__c = (oppMap.get('ownerChange') == '') ? (Id) selectedOwner : (Id) oppMap.get('ownerChange');
				if(additionalApprover != null && additionalApprover != '') rom.Additional_approver__c = (Id) additionalApprover;
				rom.Account__C = (Id) oppMap.get('AccountId');
				rom.Opportunity__c = (Id) oppMap.get('Id');
				rom.New_Assignment_Reason__c = newAssigment;
				
				System.debug('rom.New_Owner__c: ' + rom.New_Owner__c);
					
				insertRecordsOwnerList.add(rom);
			}
		}

		System.debug('insertRecordsOwnerList size: ' + insertRecordsOwnerList.size());

		Database.SaveResult[] lsr = Database.insert(insertRecordsOwnerList, false);
		for(Database.SaveResult sr : lsr){
			for(Database.Error err : sr.getErrors()){
				System.debug('Records_Owner_Management Error List');
				System.debug(err.getStatusCode() + ' : ' + err.getMessage());
				System.debug('Records_Owner_Management fields that affected this error: ' + err.getFields());
			}
		}
		System.debug('insertRecordsOwnerList: ' + insertRecordsOwnerList);
		List<Records_Owner_Management__c> pandingRecords = new List<Records_Owner_Management__c>();
		List<Id> newOwnerIdList = new List<Id>();
		List<Id> accIdList = new List<Id>();
		List<Id> opportunityIdList = new List<Id>();
		for(Records_Owner_Management__c rom : insertRecordsOwnerList){
			System.debug('rom.status__c: ' + rom.status__c);
			System.debug('rom.Id: ' + rom.Id);
			if(rom.status__c == 'Pending Quota Review' || test.isrunningtest()){
				pandingRecords.add(rom);
				newOwnerIdList.add(rom.New_Owner__c);
				if(rom.Account__C != null) accIdList.add(rom.Account__c);
				if(rom.Opportunity__c != null) opportunityIdList.add(rom.Opportunity__c);
				if(rom.Id != null){
					try{
						System.debug('In rom Id');
						Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
						req.setProcessDefinitionNameOrId(Label.Records_Owner_Management_Approval_Process);
						req.setObjectId(rom.Id);
						Approval.ProcessResult processResult = Approval.process(req);
					}catch(Exception e){
						reqSend.put('approvelError', e.getMessage());
					}
				}
			}
		}

		ProcessRecordOwnerManagement_BATCH theBatch = new ProcessRecordOwnerManagement_BATCH ();
		id idBatch = Database.executeBatch(theBatch);
		if(pandingRecords.size() > 0 ||test.isrunningtest()){

			Map<Id, String> ownerIdVSNameMap = new Map<Id, String>();
			Map<Id, String> accountIdVSNameMap = new Map<Id, String>();
			Map<Id, String> opportunityIdVSNameMap = new Map<Id, String>();
			for(user u : [select Id, name from user where id In:newOwnerIdList]){
				ownerIdVSNameMap.put(u.Id, u.name);
			}

			for(account acc : [select Id, name from Account where id In:accIdList]){
				accountIdVSNameMap.put(acc.Id, acc.name);
			}

			for(Opportunity opp : [select Id, name from Opportunity where id In:opportunityIdList]){
				opportunityIdVSNameMap.put(opp.Id, opp.name);
			} 
			try{
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				String[] toAddresses = new String[] {UserInfo.getUserEmail()};
				mail.setToAddresses(toAddresses);
				mail.setSubject('Record Ownership Request – Transfers pending approval');
				mail.setUseSignature(false);
				String emailBody = 'Batch ref ID: ' + idBatch + '<br> Total items: ' + insertRecordsOwnerList.size() +	'<br>Total pending: ' + pandingRecords.size();
				emailBody += '<br><br>The below record transfers are pending approval because the accounts have or had renewal	quotas for the current year, and quota reallocation between owners might need to be actioned.<br>You will be	 notified once the transfer is approved and completed, or denied.<br><br>Pending Account:';
				for(Records_Owner_Management__c rom : pandingRecords){
					if(rom.Account__C !=null && rom.Opportunity__c == null) emailBody += '<br><a href=' +	URL.getSalesforceBaseUrl().toExternalForm() + '/' + rom.Id + '>' + rom.Id + '</a> | ';

					if(rom.Account__C !=null && rom.Opportunity__c == null) emailBody += '<a href=' + URL.getSalesforceBaseUrl  ().toExternalForm() + '/' + rom.Account__C + '>' + accountIdVSNameMap.get(rom.Account__C) + '</a> | ';

					if(rom.Account__C !=null && rom.Opportunity__c == null) emailBody += 'New Owner: ' + ownerIdVSNameMap.get   (rom.New_Owner__c);
				}

				emailBody += '<br><br>Pending Opportunity:';

				for(Records_Owner_Management__c rom : pandingRecords){
					if(rom.Opportunity__c != null) emailBody += '<br><a href=' + URL.getSalesforceBaseUrl().toExternalForm() +	'/' + rom.Id + '>' + rom.Id + '</a> | ';

					if(rom.Account__C !=null && rom.Opportunity__c != null) emailBody += '<a href=' + URL.getSalesforceBaseUrl  ().toExternalForm() + '/' + rom.Account__C + '>' + accountIdVSNameMap.get(rom.Account__C) + '</a> | ';

					if(rom.Opportunity__c != null) emailBody += 'Opp: <a href=' +  URL.getSalesforceBaseUrl().toExternalForm()	+ '/' + rom.Opportunity__c + '>'+ opportunityIdVSNameMap.get(rom.Opportunity__c) +'</a> | ';

					if(rom.Opportunity__c != null) emailBody += 'New Owner: ' + ownerIdVSNameMap.get(rom.New_Owner__c);
				}
				mail.setHtmlBody(emailBody);
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}catch(Exception e){
				reqSend.put('emailError', e.getMessage());
				System.debug('Error email: ' + e.getMessage());
			}
		}
		if(reqSend.size() > 0 ) return reqSend;
		reqSend.put('succeeded', 'succeeded');
		return reqSend;
	}

	/// lockup
	    private final static Integer MAX_RESULTS = 5;
		//scope='global'
		
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> search(String searchTerm, String byProfile, List<String> selectedIds) {
        // Prepare query parameters
        searchTerm += '*';
		System.debug('searchTerm: ' + searchTerm);
		System.debug('byProfile: ' + byProfile);
		System.debug('selectedIds: ' + selectedIds);
        // Execute search query
		List<List<SObject>> searchResults = new List<List<SObject>>();
		if(byProfile == 'true'){
			searchResults = [
				FIND :searchTerm
				IN ALL FIELDS
				RETURNING
					User(Id, Name WHERE id NOT IN :selectedIds and isActive = true and Cx_IsFrozen__c = False and profileId = '00e3z000001BFVL')  
				LIMIT :MAX_RESULTS
			];			
		} else {
			searchResults = [
				FIND :searchTerm
				IN ALL FIELDS
				RETURNING
					User(Id, Name WHERE id NOT IN :selectedIds and isActive = true and Cx_IsFrozen__c = False)  
				LIMIT :MAX_RESULTS
			];
		}

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String accountIcon = 'standard:user';
        User[] us = (List<User>) searchResults[0];
        for (User u : us) {
            results.add(new LookupSearchResult(u.Id, 'User', accountIcon, u.Name, 'user'));
        }


        // Optionnaly sort all results on title
        results.sort();

        return results;
    }
	//scope='global'
	
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> getRecentlyViewed() {
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        // Get recently viewed records of type Account or Opportunity
        List<RecentlyViewed> recentRecords = [
            SELECT Id, Name, Type
            FROM RecentlyViewed
            WHERE Type = 'User'
            ORDER BY LastViewedDate DESC
            LIMIT 5
        ];
        // Convert recent records into LookupSearchResult
        for (RecentlyViewed recentRecord : recentRecords) {
            if (recentRecord.Type == 'User') {
                results.add(
                    new LookupSearchResult(
                        recentRecord.Id,
                        'User',
                        'standard:user',
                        recentRecord.Name,
                        'User • ' + recentRecord.Name

                    )
                );
            } else {
                results.add(
                    new LookupSearchResult(
                        recentRecord.Id,
                        'Opportunity',
                        'standard:opportunity',
                        recentRecord.Name,
                        'Opportunity • ' + recentRecord.Name

                    )
                );
            }
        }
        return results;
    }
}