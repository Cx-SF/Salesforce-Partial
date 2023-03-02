public without sharing class CommunityUserManagementServiceCtrl {
    private static String TAG = 'Community User Management Service';
    private static Map<String,Community_user_management_allowed__mdt> allowedActionsByProfileMAp;
    @AuraEnabled
    public static string createScheduledJob(String jobName) {
        User cu = [SELECT id, Profile.Name FROM USER Where id = :UserInfo.getUserId()];
        if (cu.Profile.Name == 'System Administrator') {
            String defaultJobName = 'Community user requests handler';
            createScheduledJob(1, (jobName == '' || jobName == null ) ? defaultJobName : jobName);
            return 'Jobs were started';
        }
        return 'You have no permission to perform this operation';
    }
    
    @AuraEnabled
    public static String abortAllJobs(String jobName) {
        jobName = (jobName == null || jobName == '') ? 'Community user requests handler' : jobName; 
        User cu = [SELECT id, Profile.Name FROM USER Where id = :UserInfo.getUserId()];
        if (cu.Profile.Name == 'System Administrator') {
            List<CronTrigger> cts = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE :'%'+jobName+'%' ];
            System.debug(cts);
            Integer countAborted = 0;
            for (CronTrigger ct : cts) {
                try {
                    System.abortJob(ct.Id);
                    countAborted++;
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                }
            }
            return (countAborted == 0) ? 'No Scheduled Jobs were aborted' : countAborted + ' were aborted';
        }
        return 'You have no permission to perform this operation';
    }
    
    @AuraEnabled
    public static Boolean areJobsRunning(String jobName) {
        jobName = (jobName == null || jobName == '') ? 'Community user requests handler' : jobName; 
        User cu = [SELECT id, Profile.Name FROM USER Where id = :UserInfo.getUserId()];
        if (cu.Profile.Name == 'System Administrator') {
            List<CronTrigger> cts = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE :'%'+jobName+'%' ];
            if (cts.isEmpty()) {
                return false;
            } else return true;
        }
        return false;
    }
    
    public static void createScheduledJob(Integer step, String jobName) {
        
        CommunityUserManagementScheduledJob myBatchObject = new CommunityUserManagementScheduledJob(step);
        Integer min = Math.mod(Datetime.now().minute() + 1, 60);
        String cron = '0 ' + String.valueOf(min) + ' * * * ?';
        String jobID = System.schedule(jobName +' every ' + step + ' minute', cron, myBatchObject);
    }
    
    public static Map<Id, Boolean> getCommunityUsersAdminMap(List<Id> userIds, String customPermission) {
        ApexUtil.enableLog();
            System.debug('Rafa - getCommunityUsersAdminMap Start');
        
        Map<Id, Boolean> usersCommunityAdminMap = new Map<Id, Boolean>();
        for (Id userId : userIds) {
            usersCommunityAdminMap.put(userId, false);
        }
		System.debug('Rafa - usersCommunityAdminMap: ' + usersCommunityAdminMap);
        ApexUtil.log(TAG, 'usersCommunityAdminMap' , usersCommunityAdminMap );
        List<SetupEntityAccess> permSetIds = [
            SELECT ParentId
            FROM SetupEntityAccess
            WHERE SetupEntityId IN (SELECT Id
                                    FROM CustomPermission
                                    WHERE DeveloperName = :customPermission)
        ];
        ApexUtil.log(TAG, 'permSetIds' , permSetIds );                                     	
		System.debug('Rafa - permSetIds: ' + permSetIds);
        
        List<Id> ids = new List<Id>();
        
        for (SetupEntityAccess access : permSetIds) {
            ids.add(access.ParentId);
        }
        
        List<PermissionSetAssignment> permissions = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds AND PermissionSetId IN :ids
        ];
        ApexUtil.log(TAG, 'permissions' , permissions );
        for (PermissionSetAssignment permission : permissions) {
            usersCommunityAdminMap.put(permission.AssigneeId, true);
        }
        ApexUtil.log (TAG, 'usersCommunityAdminMap', usersCommunityAdminMap);
        return usersCommunityAdminMap;
    }
    
    
    
    @AuraEnabled
    public static void createRequestForNewContact(String newContactId, String accountId) {
        Portal_user_update__c request = new Portal_user_update__c(
            Contact__c = newContactId,
            New_user_state__c = true,
            Type__c = 'Status',
            Status__c = 'Pending', 
            Account__c = accountId
        );
        System.debug(request);
        insert request;
        System.debug('request ' + request);
    }
    
    @AuraEnabled
    public static Boolean createRequests(String rowsJSON, String accountId) {
        
        String currentUserId = UserInfo.getUserId();
        List<User> cUser = [
            SELECT Id, Name, UserType, Contact.Id, Contact.Account.Id, Contact.Account.Name, Contact.Account.Maximum_Portal_Users__c, Contact.Account.Override_maximum_Portal_Users__c, Profile.Name, POC_Extension_Counter__c
            FROM User
            WHERE Id = :currentUserId
        ];
        Boolean isStandard = cUser[0].UserType.toLowerCase() == 'standard';
        
        System.debug('"' + rowsJSON + '"');
        
        List<ContactWrapper> userList = (List<ContactWrapper>)JSON.deserialize(rowsJSON, List<ContactWrapper>.class);
		System.debug('Rafa - userList: ' + userList);
        List<Portal_user_update__c> requests = new List<Portal_user_update__c>();
        
        List<Contact> toUpdate = new List<Contact>();
        List<User> toUserUpdate = new List<User>();
        
        for (ContactWrapper userRequest : userList) {
            
            // skip the request creation     if the previous request is not Success
            if (userRequest.requestStatus != '') {
                System.debug('Skipped ' + userRequest);
                System.debug('requestStatus ' + userRequest.requestStatus);
                continue;
            }
            
            String Type = '';
            Boolean New_user_state = (userRequest.userIsActive == null) ? false : userRequest.userIsActive;
            if (userRequest.changeUserState) {
                System.debug('STATE CHANGE REQUEST');
                New_user_state = !New_user_state;
                Type = (userRequest.pocUser) ? 'Poc Status' : 'Status';
				if(userRequest.pocUser){
					Integer numOfDays = Integer.valueOf(Label.POC_Extension_Time_Frame);
					System.debug('Rafa - numberOfDays: ' + numOfDays);
					System.debug('Rafa - date today: ' + Date.today());
					Date ExpirationDate = Date.today().addDays(numOfDays);
					System.debug('Rafa - ExpirationDate: ' + ExpirationDate);
					if(New_user_state){
						if(isStandard){
							toUpdate.add(new Contact(Id = userRequest.contactId, Community_User_Management_Status__c= 'Active', CX_POC_user__c = true, Expiration_Date__c = ExpirationDate)); 
							toUserUpdate.add(new User(Id = userRequest.userId, Expiration_Date__c = ExpirationDate));
						}else{
							 toUpdate.add(new Contact(Id = userRequest.contactId, Community_User_Management_Status__c= 'Pending', CX_POC_user__c = true, Expiration_Date__c = ExpirationDate));
							 toUserUpdate.add(new User(Id = userRequest.userId, Expiration_Date__c = ExpirationDate));
						}
					}else{
						toUpdate.add(new Contact(Id = userRequest.contactId, CX_POC_user__c = true, Expiration_Date__c = ExpirationDate));
						toUserUpdate.add(new User(Id = userRequest.userId, Expiration_Date__c = ExpirationDate));
					}
				}else{
					if (New_user_state) {
					    if (isStandard){
					        toUpdate.add(new Contact(Id = userRequest.contactId, Community_User_Management_Status__c= 'Active', CX_POC_user__c = false));
					    }else {
					        toUpdate.add(new Contact(Id = userRequest.contactId, Community_User_Management_Status__c= 'Pending', CX_POC_user__c = false ));
					    }
					} else {
							toUpdate.add(new Contact(Id = userRequest.contactId, Community_User_Management_Status__c= 'Inactive'));
							//toUserUpdate.add(new User(Id = userRequest.userId, Expiration_Date__c = null, POC_Extension_Counter__c = 0));   
					}
				}
            }
            
            Boolean New_user_delegated_admin =
                (userRequest.delegatedAdmin == null) ? false : userRequest.delegatedAdmin;
            if (userRequest.changeDelegatedAdmin) {
                New_user_delegated_admin = !New_user_delegated_admin;
                Type = 'Admin';
            }
            
            //Added by MichalH on 24/07/19 Start
            Boolean execute_ResetPassword=userRequest.executeResetPassword;
            if(userRequest.executeResetPassword){
                Type='Reset Password';
            }
            //Added by MichalH on 24/07/19 End

			///Added by Rafa on 19/06/22 Start ///
			if(userRequest.pocExtension) {
				Type = 'pocExtension';
				DOUBLE exCounter = (userRequest.extensionCounter == null) ? 1 : userRequest.extensionCounter + 1;
				Date ExpirationDate = userRequest.expirationDate;
				Integer numOfDays = Integer.valueOf(Label.POC_Extension_Time_Frame);
				Date newExpirationDate = ExpirationDate.addDays(numOfDays);
				System.debug('Rafa - ExpirationDate: ' + ExpirationDate);
				toUpdate.add(new Contact(Id = userRequest.contactId, Expiration_Date__c = newExpirationDate));
				toUserUpdate.add(new user( id = userRequest.userId, POC_Extension_Counter__c = exCounter, Expiration_Date__c = newExpirationDate));
			}
			///Added by Rafa on 19/06/22 End ///
            
            requests.add(new Portal_user_update__c(
                Contact__c = userRequest.contactId,
                New_user_state__c = New_user_state,
                New_user_delegated_admin__c = New_user_delegated_admin,
                Reset_Password__c = execute_ResetPassword,
                Type__c = Type,
                Status__c = 'Pending',
                Account__c = accountId
            ));
        }
		System.debug('Rafa - requests: ' + requests);
        insert requests;
        if (!toUpdate.isEmpty()) {
			System.debug('Rafa - toUpdate: ' + toUpdate);
            update toUpdate;
        }
		System.debug('Rafa - toUserUpdate: ' + toUserUpdate);
		if(!toUserUpdate.isEmpty()) update toUserUpdate;
        //        EventBus.publish(events);
        
        return true;
        
    }
    
    @AuraEnabled
    public static List<RequestWrapper> getRequests(Id contactId) {
        
        List<RequestWrapper> communityRequests = new List<RequestWrapper>();
        
        // requests created for current contact
        for (
            Portal_user_update__c request
            :
            [
                SELECT
                Name, Status__c, CreatedBy.Name, Contact__c, Contact__r.Name, Contact__r.AccountId,
                New_user_state__c, New_user_delegated_admin__c, CreatedDate, Type__c, Reject_Reason__c,Reset_Password__c
                FROM Portal_user_update__c
                WHERE Contact__r.Id = :contactId
                ORDER BY CreatedDate DESC
            ]) {
                communityRequests.add(new RequestWrapper(request));
            }
        
        return communityRequests;
    }
    
    
    @AuraEnabled
    public static InitialData getInitialData(Id accountId) {
        allowedActionsByProfileMAp = getAllowedActionsByProfileMAp();
        InitialData initd = new InitialData();
        
        //String currentUserId = '0050E000004UNIGQA4';
        String currentUserId = UserInfo.getUserId();
        List<User> cUser = [
            SELECT Id, Name, UserType, Contact.Id, Contact.Account.Id, Contact.Account.Name,Contact.Account.type, Contact.Account.Maximum_Portal_Users__c, Contact.Account.Override_maximum_Portal_Users__c, Profile.Name, ProfileId, Contact.Account.Account_Status__c
            FROM User
            WHERE Id = :currentUserId
        ];
		String pocGrop = System.Label.Poc_Button_Visibility;
		List<String> pocGropList = pocGrop.split(';');
		List<GroupMember> gropMem = [select Id, GroupId, UserOrGroupId  from GroupMember where GroupId in :  pocGropList];
		List<Id> userInPocGroup = new List<Id>();
		for(GroupMember g : gropMem){
			userInPocGroup.add(g.UserOrGroupId);
		}
		List<String> cantActivetList = System.Label.User_Management_Hide_Activate.split(';');
		System.debug('Rafa - cantActivetList: ' + cantActivetList);
		initd.isPoc = (userInPocGroup.contains(UserInfo.getUserId()) || pocGropList.contains(UserInfo.getProfileId())) ? true : false;
		initd.cantActivte = cantActivetList.contains(cUser[0].ProfileId);
		System.debug('Rafa - Profile.Name.toLowerCase(): ' + cUser[0].Profile.Name.toLowerCase());
        initd.isSystemAdmin = cUser[0].Profile.Name == 'System Administrator';
        initd.isStandard = cUser[0].UserType.toLowerCase() == 'standard';
		initd.isCommunity = cUser[0].Profile.Name.toLowerCase().contains('community');
        initd.userType = cUser[0].UserType;
        List<ContactWrapper> communityUsers = new List<ContactWrapper>();
        //List<RequestWrapper> communityRequests = new List<RequestWrapper>();
        
        Account userAccount;
        
        if (cUser.size() != 0) {
            Contact userContact = cUser[0].Contact;
            
            System.debug('cUser[0] ' + cUser[0]);
            System.debug('cUser[0].Contact ' + cUser[0].Contact);
            
            if (userContact != null) {
                userAccount = userContact.Account;
            } else {
                //
                for (
                    Account acc
                    :
                    [
                        SELECT Id, Name,Type, Maximum_Portal_Users__c, Override_maximum_Portal_Users__c, Account_Status__c
                        FROM Account
                        WHERE Account.Id = :accountId
                    ]) {
                        userAccount = acc;
                    }
            }
        }
        
        if (userAccount == null) {
            
            initd.accounts = [SELECT Id, Name FROM Account];
            //System.debug('Need to select account.');
            
        } else {
            System.debug('Rafa - userAccount: ' + userAccount);
            initd.userAccountName = userAccount.Name;
            initd.userAccountId = userAccount.Id;
            initd.accountType = userAccount.Type;
			if(!Test.isRunningTest()) initd.accountStatus = userAccount.Account_Status__c; // Added by Rafa on 14/06/22
            initd.maxPortalUsers = ( userAccount.Maximum_Portal_Users__c == null && userAccount.Override_maximum_Portal_Users__c == null )? 0 : ( userAccount.Override_maximum_Portal_Users__c == null )? userAccount.Maximum_Portal_Users__c : userAccount.Override_maximum_Portal_Users__c;
            initd.availableUsers = initd.maxPortalUsers;
            initd.activeUsers = initd.maxPortalUsers - initd.availableUsers;
            
            Set<Id> processInstancesIds = new Set<Id>();
            for ( Contact cContact  : [
                SELECT
                Account.Id, Account.Name, Account.Maximum_Portal_Users__c, Account.Override_maximum_Portal_Users__c, Id, Name, MailingCountry, Email,
                LastName, FirstName, Community_User_Management_Status__c, Community_User_Management_Reject_Reason__c,Expiration_Date__c,
                Can_see_all_account_cases__c, CX_POC_user__c, // Added by Alex Levchenko on 12/07/2019
                (SELECT Id, Name, IsActive, LastLoginDate,LastReset__c,Profile.name, Poc_Extension_Counter__c FROM Users), (SELECT id, Status FROM ProcessInstances ORDER BY CompletedDate DESC LIMIT 1)
                FROM Contact
                WHERE Account.Id = :userAccount.Id
                ORDER BY Name
            ]) {
                communityUsers.add(new ContactWrapper(cContact));
                for (ProcessInstance p : cContact.ProcessInstances) {
                    processInstancesIds.add(p.id);
                }
            }
            
            for ( Contact cContact  : [
                SELECT
                Account.Id, Account.Name, Account.Maximum_Portal_Users__c, Account.Override_maximum_Portal_Users__c, Id, Name, MailingCountry, Email,
                LastName, FirstName, Community_User_Management_Status__c, Community_User_Management_Reject_Reason__c,Expiration_Date__c
                , Can_see_all_account_cases__c, CX_POC_user__c, // Added by Alex Levchenko on 12/07/2019
                (SELECT Id, Name, IsActive, LastLoginDate,LastReset__c,Profile.name, Poc_Extension_Counter__c FROM Users), (SELECT id, Status FROM ProcessInstances ORDER BY CompletedDate DESC LIMIT 1)
                FROM Contact
                WHERE AccountId = null
                AND   Id in (select contact__c from portal_user_update__c where account__c = :userAccount.Id and status__c != 'Success')
                ORDER BY Name
            ]) {
                communityUsers.add(new ContactWrapper(cContact));
                for (ProcessInstance p : cContact.ProcessInstances) {
                    processInstancesIds.add(p.id);
                }
            }
            
            Map<Id, ProcessInstance> processInstances =new map<Id, ProcessInstance>([SELECT id, Status,(select id, actor.name from Workitems),
                                                                                     (SELECT Id, StepStatus, Comments, Actor.Name FROM Steps ORDER BY CreatedDate DESC LIMIT 1)
                                                                                     FROM ProcessInstance WHERE id IN:processInstancesIds ORDER BY CompletedDate]);
            List<Id> userIds = new List<Id>();
            
            for (ContactWrapper cContact : communityUsers) {
                if (cContact.userIsActive == true) {
                    initd.availableUsers--;
                    initd.activeUsers++;
                }
                
                if (cContact.userId != null) {
                    userIds.add(cContact.userId);
                }
                
                for(ProcessInstance p: cContact.processInstances) {
                    ProcessInstance pp = processInstances.get(p.id); 
                    if (!pp.Steps.isEmpty()) {
                        cContact.lastApprovalMessage = pp.Steps[0].Comments;
                    }
                    cContact.lastApprovalStatus = pp.Status;  
                }
            }
            
            String customPermission = 'Community_Delegated_Admin';
            Map <Id, Boolean> communityUsersAdminMap = getCommunityUsersAdminMap(userIds, customPermission);
            
            for (ContactWrapper cContact : communityUsers) {
                if (cContact.userId != null) {
                    cContact.delegatedAdmin = communityUsersAdminMap.get(cContact.userId);
                    if (cContact.delegatedAdmin) {
                        cContact.delegatedAdminText = 'Yes';
                    }
                    if (cContact.canSeeAllAccountCases) {
                        cContact.canSeeAllAccountCasesText = 'Yes';
                    }
                }
            }
            
            Map<Id, ContactWrapper> showedContactMap = new Map<Id, ContactWrapper>();
            for (ContactWrapper commContact : communityUsers) {
                showedContactMap.put(commContact.contactId, commContact);
            }
            
            // all requests for showed contacts by ALL for show NOT Success request status
            for (
                Portal_user_update__c request
                :
                [
                    SELECT
                    Name, Status__c, Type__c, CreatedBy.Name, Contact__c, New_user_state__c, New_user_delegated_admin__c,
                    CreatedDate, Reject_Reason__c,Reset_Password__c
                    FROM Portal_user_update__c
                    WHERE Contact__c IN : showedContactMap.keySet()  ORDER BY LastModifiedDate
                ]) {
                    
                    if (request.Status__c != 'Success') {
                        ContactWrapper commContact = showedContactMap.get(request.Contact__c);
                        if (commContact != null) {
                            commContact.requestStatus = request.Status__c;
                            if(request.Status__c == 'Pending') {
                                if (request.Type__c == 'Status' || request.Type__c == 'Poc Status') {
									System.debug('Rafa - request.Type__c : ' + request.Type__c );
                                    commContact.lastPendingRequestType =  request.Type__c == 'Poc Status' ? 'Activate Poc User' : request.New_user_state__c ? 'Activate user' : 'Deactivate user';
                                    //commContact.lastPendingRequestType = request.New_user_state__c ? 'Activate user' : 'Deactivate user';
                                } else {
                                    commContact.lastPendingRequestType = request.New_user_delegated_admin__c ? 'Grant admin' : 'Remove admin';
                                }
                            }
                            commContact.requestsButtonDisabled = false;
                            
                            Boolean newUserStatus = request.New_user_state__c;
                            Boolean oldUserStatus = commContact.userIsActive;
                            if (oldUserStatus != newUserStatus && request.Status__c == 'Pending' && (request.Type__c== null 
                                || !request.Type__c.containsIgnoreCase('See All Cases'))) {
                                //System.debug('Status changed by differ in statuses');
                                commContact.styleUserState = 'YellowColor';
								if(request.Type__c == 'Poc Status'){
									commContact.userStatus = 'Poc Active';
								}else {
									commContact.userStatus = (newUserStatus) ? 'Active' : 'Inactive';
								}
                            }
                            
                            Boolean newUserAdmin = request.New_user_delegated_admin__c;
                            Boolean oldUserAdmin = commContact.delegatedAdmin;
                            if (oldUserAdmin != newUserAdmin && request.Status__c == 'Pending' && (request.Type__c== null 
                                || !request.Type__c.containsIgnoreCase('See All Cases'))) {
                                //System.debug('Status changed by pending request');
                                commContact.styleAdmin = 'YellowColor';
                                commContact.delegatedAdmin = (newUserAdmin) ? true : false;
                                commContact.delegatedAdminText = (newUserAdmin) ? 'Yes' : 'No';
                            }
                            
                            if (request.Status__c == 'Error') {
                                //commContact.rejectReason = request.Reject_Reason__c;
                                commContact.styleUserState = '';
                                commContact.styleAdmin = '';
								if(request.Type__c == 'Poc Status'){
									//commContact.userStatus = (oldUserStatus != null && oldUserStatus ) ? 'Poc Active' : 'Inactive'; // change by Rafa on 17/07/22
								}
                                //commContact.delegatedAdminText = (oldUserAdmin != null && oldUserAdmin ) ? 'Yes' : 'No';
                            }
                            if(request.Status__c == 'Pending' && (request.Type__c == 'Grant See All Cases' || request.Type__c == 'Revoke See All Cases') ) {
                              	commContact.styleSeeAllCases = 'YellowColor';
                                commContact.canSeeAllAccountCases = request.Type__c == 'Grant See All Cases' ? true : false; 
                                commContact.canSeeAllAccountCasesText = commContact.canSeeAllAccountCases  ? 'Yes' : 'No';
                            }
                            
                        }
                    } else {
                        ContactWrapper commContact = showedContactMap.get(request.Contact__c);
                        if (commContact != null) {
                            commContact.requestsButtonDisabled = false;
                            commContact.requestStatus = request.Status__c;
                            commContact.rejectReason = request.Reject_Reason__c;
                            commContact.styleUserState = '';
                            commContact.styleAdmin = '';
                        }
                    }
                }
            
            initd.communityUsers = communityUsers;
            System.debug('Rafa communityUsers: ' + communityUsers);
            initd.countries = new List<CountryWrapper>();
            List<Schema.PicklistEntry> countries = Contact.MailingCountryCode.getDescribe().getPicklistValues();
            Map<String, List<Schema.PicklistEntry>> dependentStates = ApexUtil.getFieldDependencies('Contact','MailingCountryCode','MailingStateCode');
            for (Schema.PicklistEntry country : countries) {
                initd.countries.add(new CountryWrapper(country, dependentStates.get(country.Label)));
            }
            
        }
        
        //System.debug(initd.countries);
        return initd;
    }
    
    // Added by Alex Levchenko on 12/07/2019: Start
    @AuraEnabled
    public static void setCanSeeAllCasesFlag(String contactId, Boolean canSeeAllCases) {
		User communityUsr = new User();
        if(!Test.isRunningTest()) communityUsr = [SELECT Id,Contact.AccountId FROM User WHERE contactId=:contactId];
        Contact con = new Contact(Id=contactId);
        String type;
        if(canSeeAllCases){
            type = 'Grant See All Cases';
            
        } else {
            type = 'Revoke See All Cases';
           
        }
        Portal_user_update__c request = new Portal_user_update__c(
            Contact__c = contactId,
            Type__c = type,
            Status__c = 'Pending',
            Account__c = (!Test.isRunningTest()) ? communityUsr.Contact.AccountId : null
        );
        insert request;
    }
    
    /*@AuraEnabled 
    public static void updateSeeAllCasesResult(Portal_user_update__c request){
        Contact con = new Contact(Id=request.Contact__c);
        if(request.Type__c ==  'Grant See All Cases'){
            con.Can_see_all_account_cases__c = true;
        } else {
            con.Can_see_all_account_cases__c = false;
        }
        update con;
        insert request;
    }*/
    
    // Added by Alex Levchenko on 12/07/2019: End
    
    public class InitialData {
        @AuraEnabled public String userAccountName {get; set;}
        @AuraEnabled public String userAccountId {get; set;}
        @AuraEnabled public Decimal maxPortalUsers {get; set;}
        @AuraEnabled public Decimal availableUsers {get; set;}
        @AuraEnabled public Decimal activeUsers {get; set;}
        @AuraEnabled public List<ContactWrapper> communityUsers {get; set;}
        //@AuraEnabled public List<RequestWrapper> communityRequests {get;set;}
        @AuraEnabled public List<Account> accounts {get; set;}
        @AuraEnabled public List<CountryWrapper> countries {get; set;}
        @AuraEnabled public Boolean isSystemAdmin {get; set;}
        @AuraEnabled public Boolean isStandard {get; set;} 
        @AuraEnabled public Boolean isPoc {get; set;}
        @AuraEnabled public Boolean cantActivte {get; set;} // added by Rafa on 08/12/22
        @AuraEnabled public String accountType {get; set;}
        @AuraEnabled public String userType {get; set;}
        @AuraEnabled public String accountStatus {get; set;} // added by Rafa on 14/06/22
        @AuraEnabled public Boolean isCommunity {get; set;} // added by Rafa on 08/12/22

    }
    
    public class ContactWrapper {
        @AuraEnabled public Boolean selected {get; set;}
        @AuraEnabled public Boolean actionDisabled {get; set;}
        @AuraEnabled public Boolean delegatedAdmin {get; set;}
        @AuraEnabled public String delegatedAdminText {get; set;}
        @AuraEnabled public Boolean changeDelegatedAdmin {get; set;}
        @AuraEnabled public Boolean changeUserState {get; set;}
        @AuraEnabled public String accountName {get; set;}
        @AuraEnabled public String accountId {get; set;}
        @AuraEnabled public String contactName {get; set;}
        @AuraEnabled public String contactFirstName {get; set;}
        @AuraEnabled public String contactLastName {get; set;}
        @AuraEnabled public String contactCountry {get; set;}
        @AuraEnabled public String contactEmail {get; set;}
        @AuraEnabled public String contactId {get; set;}
        @AuraEnabled public String contactIdUrl {get ; set;}
        @AuraEnabled public String userName {get; set;}
        @AuraEnabled public String userId {get; set;}
        @AuraEnabled public Datetime lastLogin {get; set;}
        @AuraEnabled public Date expirationDate {get; set;} // added by Rafa on 09/06/2022
        @AuraEnabled public Boolean userIsActive {get; set;}
        @AuraEnabled public String userStatus {get; set;}
        @AuraEnabled public String requestStatus {get; set;}
        @AuraEnabled public String styleUserState {get; set;}
        @AuraEnabled public String styleAdmin {get; set;}
        @AuraEnabled public String rejectReason {get; set;}
        @AuraEnabled public Boolean requestsButtonDisabled {get; set;}
        @AuraEnabled public String contactUserStatus {get; set;}
        @AuraEnabled public List<ProcessInstance> processInstances {get; set;}
        @AuraEnabled public String lastApprovalMessage {get; set;}
        @AuraEnabled public String lastApprovalStatus {get; set;}
        @AuraEnabled public String lastPendingRequestType {get; set;}
        @AuraEnabled public Boolean canSeeAllAccountCases {get; set;} // Added by Alex Levchenko on 12/07/2019
        @AuraEnabled public String styleSeeAllCases {get; set;}
        @AuraEnabled public String canSeeAllAccountCasesText {get; set;} // Added by Alex Levchenko on 12/07/2019
        @AuraEnabled public Boolean changeSeeAllAccountCases {get; set;} // Added by Alex Levchenko on 12/07/2019
        @AuraEnabled public Boolean executeResetPassword {get; set;} //Added by Michal Havshush on 24/07/19
        @AuraEnabled public Datetime lastReset {get; set;} //Added by Michal Havshush on 25/07/19
        @AuraEnabled public Boolean seeAllCasesEnabled {get; set;} 
        @AuraEnabled public Boolean deactivateEnabled {get; set;} 
        @AuraEnabled public Boolean pocUser {get; set;} //Addedby Rafa on 14/06/22 extension
        @AuraEnabled public Boolean pocExtension {get; set;} //Addedby Rafa on 19/06/22
		@AuraEnabled public Double extensionCounter {get; set;}
        @AuraEnabled public String commmunityPrivileges {get; set;}
        @AuraEnabled public String OutOfOfficeMessage {get; set;} 
        //@AuraEnabled public String cxPocUser {get; set;} //Addedby Rafa on 14/06/22
        
        public ContactWrapper(Contact cContact) {
            deactivateEnabled = true;
            seeAllCasesEnabled = true;
            selected = false;
            actionDisabled = true;
            delegatedAdmin = false;
            delegatedAdminText = 'No';
            changeDelegatedAdmin = false;
            changeUserState = false;
			pocUser = false;
			pocExtension = false;
			expirationDate = cContact.Expiration_Date__c;
            accountName = cContact.Account.Name;
            accountId = cContact.AccountId;
            contactName = cContact.Name;
            contactFirstName = cContact.FirstName;
            contactLastName = cContact.LastName;
            contactName = cContact.Name;
            contactCountry = cContact.MailingCountry;
            contactEmail = cContact.Email;
            contactId = cContact.Id;
            contactIdUrl ='/' +contactId;
            contactUserStatus = cContact.Community_User_Management_Status__c;
            //System.debug(contactName);
            //System.debug(cContact.Users.size());
            //System.debug(cContact.Users);
            //System.debug('--------------------------');
            if (cContact.Users.size() > 0) {
                User user = cContact.Users[0];
                userName = user.Name;
                userId = user.Id;
                lastLogin = user.LastLoginDate;
                lastReset=user.LastReset__c;
				extensionCounter = user.POC_Extension_Counter__c;
                userIsActive = user.IsActive;
				System.debug('Rafa - Contact: ' + cContact.Id + ' Cx_Poc_User: ' + cContact.CX_POC_user__c);
				userStatus = (cContact.CX_POC_user__c && user.IsActive) ? 'Poc Active' : (user.IsActive) ? 'Active' : 'Inactive';
				System.debug('Rafa - user status: ' + userStatus);
                Community_user_management_allowed__mdt permissionRec = allowedActionsByProfileMAp.get(user.Profile.Name);
                seeAllCasesEnabled 		  = permissionRec!=null ? permissionRec.Allow_see_all_cases__c : true;
                deactivateEnabled 		  = permissionRec!=null ? permissionRec.Allow_deactivation__c : true;
                commmunityPrivileges	  = permissionRec!=null ? permissionRec.Community_Privileges__c : '';
                canSeeAllAccountCases     = permissionRec!=null ? permissionRec.See_All_Cases_Attribute__c : true ; // Added by Liron Sarel on 21/04/2020
            	canSeeAllAccountCasesText = canSeeAllAccountCases ? 'Yes' : 'No'; // Added by Liron Sarel on 21/04/2020
          
            } else {
                userStatus = 'Inactive';
                seeAllCasesEnabled = true;
                deactivateEnabled = true;
                canSeeAllAccountCasesText = 'No';
                //if (cContact.Community_User_Management_Status__c == 'Pending' || cContact.Community_User_Management_Status__c == 'Rejected' ) {
                //	rejectReason = cContact.Community_User_Management_Reject_Reason__c;
                //	userStatus = 'Inactive';
                //} else {
                //	userStatus = 'Inactive';
                //}
            }
            requestStatus = '_';
            requestsButtonDisabled = true;
            processInstances = cContact.ProcessInstances;
            changeSeeAllAccountCases = false; // Added by Alex Levchenko on 12/07/2019
       //     canSeeAllAccountCases = cContact.Can_see_all_account_cases__c; // Added by Alex Levchenko on 12/07/2019
       //     canSeeAllAccountCasesText = cContact.Can_see_all_account_cases__c ? 'Yes' : 'No'; // Added by Alex Levchenko on 12/07/2019
             executeResetPassword=false; //Added by Michal Havshush on 24/07/19
            
        }
    }
    
    public class RequestWrapper {
        @AuraEnabled public String request {get; set;}
        @AuraEnabled public String contact {get; set;}
        @AuraEnabled public String action {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public String reason {get; set;}
        @AuraEnabled public DateTime createdDate {get; set;}
        public RequestWrapper(Portal_user_update__c r) {
            
            //System.debug(r);
            request = r.Name;
            createdDate = r.createdDate;
            contact = r.Contact__r.Name;
            status = r.Status__c;
            reason = r.Reject_Reason__c;
            if (r.Type__c == 'Status') {
                action = r.New_user_state__c ? 'Activate user' : 'Deactivate user';
            } else if (r.Type__c == 'Admin'){
                action = r.New_user_delegated_admin__c ? 'Grant admin' : 'Remove admin';
            }
            //Added by MichalH 25/07/19
            else if(r.Type__c == 'Reset Password'){
                action = 'Reset Password';
            }
			//Added by Rafa 15/06/22
			else if(r.Type__c == 'Poc Status'){
				action = 'Activate Poc User';
			}
            else {
                action = r.Type__c ;
            }
        }
    }
    
    public class CountryWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        @AuraEnabled public List<StateWrapper> states {get; set;}
        public CountryWrapper(Schema.PicklistEntry country) {
            label = country.Label;
            value = country.Value;
        }
        
        public CountryWrapper(Schema.PicklistEntry country, List<Schema.PicklistEntry> states) {
            label = country.Label;
            value = country.Value;
            this.states = new List<StateWrapper>();
            for (Schema.PicklistEntry pe : states){
                this.states.add(new StateWrapper(pe));
            }
        }
    }
    
    public class StateWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        
        public StateWrapper(Schema.PicklistEntry state) {
            label = state.Label;
            value = state.Value;
        }
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }
    
    private static  Map<String,Community_user_management_allowed__mdt> getAllowedActionsByProfileMAp(){
        Map<String,Community_user_management_allowed__mdt> resultMap = new Map<String,Community_user_management_allowed__mdt>();
        for(Community_user_management_allowed__mdt cuma : [SELECT Label,Community_Privileges__c,Allow_see_all_cases__c,See_All_Cases_Attribute__c, Allow_deactivation__c FROM Community_user_management_allowed__mdt]){
            resultMap.put(cuma.Label,cuma);
        }
        return resultMap;
    }
    
}