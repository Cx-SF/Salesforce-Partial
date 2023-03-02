public with sharing class CommunityUserManagementScheduledJob implements Schedulable {
    private static String TAG = 'Community User Management Service Schedule';
    private static List<Portal_user_update__c> events = new List<Portal_user_update__c>();
    private Integer delayInMinutes;
    private CronTrigger mainJob;
    
    // Constructor of Main job
    public CommunityUserManagementScheduledJob( Integer delayInMinutes ) {
        this.delayInMinutes = delayInMinutes;
		System.debug('Rafa - CommunityUserManagementScheduledJob Start');
    }
    
    public CommunityUserManagementScheduledJob ( Integer delayInMinutes, CronTrigger parentJob ) {
        this(delayInMinutes);
        mainJob = parentJob;
    }
    
    public void execute(SchedulableContext sc) {
        Id jobId = sc.getTriggerId();
        if (mainJob == null || mainJob.Id == jobId) {
            mainJob = [
                SELECT CronJobDetail.Name, NextFireTime
                FROM CronTrigger WHERE Id = :jobId
            ];
        } else {
            System.abortJob(jobId);
        }
        
        Datetime nextWorkerRun = Datetime.now().addMinutes(delayInMinutes);
        if (nextWorkerRun.addMinutes(delayInMinutes) < mainJob.NextFireTime) {
            String cronExp = nextWorkerRun.second() + ' ' + nextWorkerRun.minute() + ' ' + nextWorkerRun.hour() + ' ' + nextWorkerRun.day() + ' ' + nextWorkerRun.month() + ' ? ' + nextWorkerRun.year();
            System.schedule(mainJob.CronJobDetail.Name + ' (worker)', cronExp, new CommunityUserManagementScheduledJob(delayInMinutes, mainJob));
        }
        
        handleCommunityUsersEvent();
        
    }      
    
    public static void handleCommunityUsersEvent() {
        try {
            ApexUtil.enableLog();
            ApexUtil.setCollectionLogLimit(50);
            
            events = [SELECT Id, Changed_TO__c,Name, Account__c,  New_user_state__c, New_user_delegated_admin__c, Type__c, Status__c, 
                      Contact__c, Contact__r.Id, Contact__r.FirstName, Contact__r.LastName, Contact__r.Email, 
                      Contact__r.Account.Id, Contact__r.Account.Name, Contact__r.Account.Maximum_Portal_Users__c, Contact__r.Account.Override_maximum_Portal_Users__c, 
                      Contact__r.Community_User_Management_Status__c, Contact__r.Account.Type,
                      Reject_Reason__c,Reset_Password__c 
                      FROM Portal_user_update__c 
                      WHERE Status__c != 'Success' AND Status__c != 'Error' AND Contact__r.Community_User_Management_Status__c != 'Pending'  LIMIT 1];
            ApexUtil.log(TAG, 'Proccessing all events : ' + (events.size() != 50) );
            ApexUtil.log(TAG, 'events' , events );
			System.debug('Rafa - event: ' + events);
            updateContactsAccounts(JSON.serialize(events));
            
            
            
            Map<Id, Portal_user_update__c> eventsMap = new Map<Id, Portal_user_update__c>();
            for (Portal_user_update__c event : events) {
                eventsMap.put(event.Contact__c, event);
            }
            List<User> cUsers = [
                SELECT Id, Name, IsActive, ContactId,profile.Name
                FROM User
                WHERE ContactId IN :eventsMap.keySet()
            ];
            
            System.debug('Rafa - cUser: ' + cUsers);
            ApexUtil.log(TAG, 'cUsers' , cUsers );
            
            Map<Id, Id> userContactsMap = new Map<Id, Id>();
            Map<Id, User> contactUsersMap = new Map<Id, User>();
            List<Id> userIds = new List<Id>();
            for (User cUser : cUsers) {
                contactUsersMap.put(cUser.ContactId, cUser);
                userContactsMap.put(cUser.Id, cUser.ContactId);
                userIds.add(cUser.Id);
            }
            
            String customPermission = 'Community_Delegated_Admin';
            Map <Id, Boolean> communityUsersAdminMap = CommunityUserManagementServiceCtrl.getCommunityUsersAdminMap(userIds, customPermission);
            System.debug('Rafa - communityUsersAdminMap: ' + communityUsersAdminMap);
            ApexUtil.log(TAG, 'communityUsersAdminMap' , communityUsersAdminMap );
            
            List<SetupEntityAccess> permSetIds = [
                SELECT ParentId
                FROM SetupEntityAccess
                WHERE SetupEntityId IN (SELECT Id
                                        FROM CustomPermission
                                        WHERE DeveloperName = :customPermission)
            ];	
            
            ApexUtil.log(TAG, 'permSetIds' , permSetIds );
            System.debug('Rafa - permSetIds: ' + permSetIds);

            
            Id customPermissionId = null;
            for (SetupEntityAccess access : permSetIds) {
                customPermissionId = access.ParentId;
            }
            
            // fill map with account active users
            List<AggregateResult> accountActiveUsers = [
                SELECT Account.Id AccountId, COUNT(Id) ActiveUsers
                FROM User
                WHERE ContactId <> '' AND IsActive = TRUE
                GROUP BY Account.Id, Account.Name
            ];
            
            ApexUtil.log(TAG, 'accountActiveUsers' , accountActiveUsers );	
            System.debug('Rafa - accountActiveUsers: ' + accountActiveUsers);
			
            
            Map<Id, Decimal> accountActiveUsersMap = new Map<Id, Decimal>();
            for (AggregateResult avail : accountActiveUsers) {
                accountActiveUsersMap.put((Id)avail.get('AccountId'), (Decimal)avail.get('ActiveUsers'));
            } //System.debug(accountAvailableUsersMap);
            
            // profile for new users
            String defaultCommUsrProfile ;
            String usernameSufix;
            String usernamePrefix;
            
            String seeAllCasesProfileName;
            
            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                SELECT See_All_cases__c,Label, Username_Prefix__c, Username_Sufix__c
                FROM CommunityUserDefaultProfile__mdt 
            ]) {
                if(defaultCommunityUserProfiles.See_All_cases__c){
                    seeAllCasesProfileName = defaultCommunityUserProfiles.Label;
                } else {
                    defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                    usernameSufix = defaultCommunityUserProfiles.Username_Sufix__c;
                    usernamePrefix = defaultCommunityUserProfiles.Username_Prefix__c;
                }
            }
            usernamePrefix = (usernamePrefix == null) ? '' : usernamePrefix;
            usernameSufix = (usernameSufix == null) ? '' : usernameSufix;
            defaultCommUsrProfile = (defaultCommUsrProfile != null) ? defaultCommUsrProfile : 'Custom Customer Portal';
            
            
            List<Profile> pfList = [
                SELECT Id, Name
                FROM Profile
                WHERE Name = :defaultCommUsrProfile OR Name = :seeAllCasesProfileName  ];
            Profile defaultProfile;
            Profile seeAllCasesProfile;
            for(Profile prof: pfList ){
                if(prof.Name==defaultCommUsrProfile){
                    defaultProfile = prof;
                }
                if(prof.Name==seeAllCasesProfileName){
                    seeAllCasesProfile =  prof;
                }
            }
            
            // user lists for next "upsert"
            List<User> existingUsers = new List<User>();
            List<Contact> deactivateContacts = new List<Contact>();
            List<User> newUsers = new List<User>();
            List<user> userResetPasslist=new List<user>();
            //Map<Id, List<Id>> contactNewUsersToEvents = new Map<Id, List<Id>>();
            //Map<Id, List<Id>> changedExistingUsersToEvents = new Map<Id, List<Id>>();
            List<PermissionSetAssignment> toInsertNewAdminsPermissions = new List<PermissionSetAssignment>();
            Map<Id, PermissionSetAssignment> toDeleteNewAdminsPermissions = new Map<Id, PermissionSetAssignment>();
            // main events loop
            for (Portal_user_update__c event : eventsMap.values()) {
                ApexUtil.log(TAG, 'event', event);
                System.debug('Rafa - event: ' + event);
                User cUser = contactUsersMap.get(event.Contact__c);
                ApexUtil.log(TAG, 'cUser', cUser);
                System.debug('Rafa - cUser: ' + cUser);

                
                
                if (event.Type__c == 'Admin') {
                    
                    // delegate admin handle
                    if (cUser != null) {
                        Boolean isCurrentUserAdmin = communityUsersAdminMap.get(cUser.Id);
                        Boolean newUserAdminStatus = event.New_user_delegated_admin__c;
                        
                        if (isCurrentUserAdmin != newUserAdminStatus) {
                            
                            if (newUserAdminStatus) { //grant admin
                                
                                PermissionSetAssignment psa = new PermissionSetAssignment
                                    (PermissionSetId = customPermissionId, AssigneeId = cUser.Id);
                                
                                //insert psa;
                                toInsertNewAdminsPermissions.add(psa);
                                event.Changed_TO__c= 'Admin';
                                //event.Status__c = 'Success';
                                //event.Reject_Reason__c = '';
                                
                            } else { //remove admin
                                
                                /*Integer countOfAdmin = 0;
for (Boolean userHaveAdmin : communityUsersAdminMap.values()) {
if (userHaveAdmin) {
countOfAdmin++;
}
}
if (countOfAdmin == 1) {
event.Status__c = 'Error';
event.Reject_Reason__c = 'Account must have at least one delegated admin user';
continue; // Account must have at least one delegated admin user
} else { 
// update map of admin for decrease countOfAdmin
communityUsersAdminMap.put(cUser.Id, false); Commented by Hananel Cohen*/
                                List<PermissionSetAssignment> ps = [
                                    SELECT Id, AssigneeId
                                    FROM PermissionSetAssignment
                                    WHERE PermissionSetId = :customPermissionId AND AssigneeId = :cUser.Id
                                ];
                                toDeleteNewAdminsPermissions.putAll(ps);
                                event.Status__c = 'Success';
                                event.Changed_TO__c= 'Non-Admin';
                                event.Reject_Reason__c = '';
                                
                                /*} Commented by Hananel Cohen */
                            }
                            
                        } else {
                            event.Status__c = 'Error';
                            if(event.New_user_delegated_admin__c){
                                event.Reject_Reason__c = 'User already admin.';
                            } else {
                                event.Reject_Reason__c = 'User already not admin.';
                            }
                            
                        }
                        
                    }
                    
                } 
                else if(event.Type__c == 'Status' || event.Type__c == 'Poc Status'){
                    
                    if (event.New_user_state__c || event.Type__c == 'Poc Status' ) {
                        if (event.Contact__r.Community_User_Management_Status__c == 'Pending' || event.Contact__r.Community_User_Management_Status__c == 'Inactive') {
                            ApexUtil.log(TAG, 'Contact community user status is not Active (Pending)');
                            continue; // Contact waiting for approval, skip the request handle
                        } else if (event.Contact__r.Community_User_Management_Status__c == 'Rejected' ){
                            ApexUtil.log(TAG, 'Contact was rejected by approver');
                            event.Status__c = 'Error';
                            Event.Reject_Reason__c = 'Contact was rejected by approver';
                            continue;
                        }
                        
                        // need to check available user licences for the account
                        Account userAccount = event.Contact__r.Account;
                        if(userAccount == null) {
                            //event.Status__c = 'Error';
                            //Event.Reject_Reason__c = 'Contact is not connected to account';
                            continue;
                        }
                        Decimal maxPortalUsers =
                            ( userAccount.Maximum_Portal_Users__c == null && userAccount.Override_maximum_Portal_Users__c == null )? 0 : ( userAccount.Override_maximum_Portal_Users__c == null )? userAccount.Maximum_Portal_Users__c : userAccount.Override_maximum_Portal_Users__c;
                        Decimal activeUsers = (Decimal)accountActiveUsersMap.get(userAccount.Id);
                        activeUsers = (activeUsers == null) ? 0 : activeUsers;
                        
                        if (activeUsers >= maxPortalUsers) {
                            ApexUtil.log(TAG, 'Portal Users limit Exceeded');
                            event.Status__c = 'Error';
                            event.Reject_Reason__c = 'No community user licenses available';
                            event.New_user_state__c = true;
                            
                            continue; // No licenses available -> Set Error status of request
                        } else {
                            // increase active users and put it to map for next loop
                            ApexUtil.log(TAG, 'Portal Users Add to next loop');
                            activeUsers++;
                            accountActiveUsersMap.put(userAccount.Id, activeUsers);
                        }
                        
                        if (cUser == null) { 
                            // create a new user
                            
                            ApexUtil.log(TAG, 'User not exist - create new User');
                            
                            Contact cContact = event.Contact__r;
                            if (cContact.FirstName==null || cContact.LastName==null) {
                                event.Status__c = 'Error';
                                event.Reject_Reason__c = 'First name or last name is empty';
                                continue; 
                            }
                            newUsers.add(new User(
                                ContactId = cContact.Id,
                                Username = usernamePrefix + cContact.Email + usernameSufix,
                                FirstName = cContact.FirstName,
                                LastName = cContact.LastName,
                                Email = cContact.Email,
                                CommunityNickname = cContact.LastName + '_' + CommunityUserManagementServiceCtrl.generateRandomString(3),
                                Alias = String.valueOf(
                                    cContact.FirstName.substring(0, 1) + cContact.LastName.substring(0, 1)),
                                ProfileId = defaultProfile.Id,
                                EmailEncodingKey = 'ISO-8859-1',
                                LanguageLocaleKey = 'en_US',
                                LocaleSidKey = 'en_US',
                                TimeZoneSidKey = 'GMT'
                            ));
                            
                        } else {
                            ApexUtil.log(TAG, 'User existed, activate user');
                            cUser.IsActive = true;
                            existingUsers.add(cUser);
                        }
                        
                    } else {
                        // deactivate handle

                        if (cUser == null) {
                            ApexUtil.log(TAG, 'User not existed  - user already deactivated');
                            event.Status__c = 'Success';
                            event.Reject_Reason__c = '';
                        } else {
							
                            ApexUtil.log(TAG, 'User existed  - user was deactivated');
                            cUser.IsActive = false;
                            setProfileBeforeDeactivate(event,cUser);
                            existingUsers.add(cUser);
                            
                            deactivateContacts.add(new Contact(id = cUser.ContactId, Community_User_Management_Status__c = 'Inactive'));
                        }
                    }
                }
                
                //Added by MichalH 25/07/19
                else if(event.Type__c == 'Reset Password'){
                    //Added by MichalH 24/07/19 : Start
                    if(event.Reset_Password__c)
                    { 
                        system.ResetPasswordResult resetResult;
                        try{
                            resetResult=system.resetPasswordWithEmailTemplate(cUser.Id,true,'CommunityChangePasswordEmailTemplate');
                        }     
                        catch (Exception ex) {
                            System.debug(ex.getMessage());
                        }
                        //errorHandle(resetResult,event);
                        if(resetResult!=null){
                            cUser.LastReset__c=system.now();
                            userResetPasslist.add(cUser);
                        }
                        
                    }  
                }
                //Added by MichalH 24/07/19 : End
                
                //Added bu Hananel Cohen , 10/2/20
                else if(event.Type__c == 'Grant See All Cases'){
                    User userToUpdate = contactUsersMap.get(event.Contact__c);
                    userToUpdate.ProfileId = seeAllCasesProfile.Id;
                    existingUsers.add(userToUpdate);
                }
                else if(event.Type__c == 'Revoke See All Cases'){
                    User userToUpdate = contactUsersMap.get(event.Contact__c);
                    userToUpdate.ProfileId = defaultProfile.Id;
                    existingUsers.add(userToUpdate);
                }else if(event.Type__c == 'pocExtension') { /// Added by Rafa on 19/06/22
					event.Status__c = 'Success';
				}
            }
            if (existingUsers.size() > 0) {
                Database.SaveResult[] srList = Database.update(existingUsers, false);
                for (Integer i=0;i<srList.size(); i++) {
                    User usr = existingUsers[i];
                    Database.SaveResult sr = srList[i];
                    Portal_user_update__c e = eventsMap.get(usr.ContactId);
                    errorHandle(sr, e); 
                }
            }
            if (newUsers.size() > 0) {
                Database.SaveResult[] srList ;
                try{
                    srList = Database.insert(newUsers, false);
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                }
                Integer  i = 0;
                for (Database.SaveResult sr : srList) {
                    User u = newUsers.get(i);
                    Portal_user_update__c e = eventsMap.get(u.ContactId);
                    errorHandle(sr, e); 
                    i++;
                }
            }
            /*if (deactivateContacts.size() > 0) {
Database.SaveResult[] srList = Database.update(deactivateContacts, false);
Integer i = 0;
for (Database.SaveResult sr : srList) {
Portal_user_update__c e = eventsMap.get(deactivateContacts[i].Id);
errorHandle(sr, e);
i++;
}
}*/
            if (toInsertNewAdminsPermissions.size() >0 ) {
                Database.SaveResult[] srList = Database.insert(toInsertNewAdminsPermissions, false);
                Integer i = 0;
                for (Database.SaveResult sr : srList) {
                    PermissionSetAssignment psa = toInsertNewAdminsPermissions.get(i);
                    Portal_user_update__c e = eventsMap.get(userContactsMap.get(psa.AssigneeId));
                    errorHandle(sr, e);
                    i++;
                }
            }
            if (toDeleteNewAdminsPermissions.size() > 0 ) {
                Database.DeleteResult[] srList = Database.delete(toDeleteNewAdminsPermissions.values(), false);
                integer i = 0;
                for (Database.DeleteResult sr : srList) {
                    PermissionSetAssignment psa = toDeleteNewAdminsPermissions.get(toDeleteNewAdminsPermissions.values()[i].id);
                    Portal_user_update__c e = eventsMap.get(userContactsMap.get(psa.AssigneeId));
                    errorHandle(sr, e); 
                    i++;
                } 
            }
            
            //Added by MichalH 25/07/19
            if (userResetPasslist.size() > 0) {
                system.debug('userResetPasslist:'+userResetPasslist);
                Database.SaveResult[] srList = Database.update(userResetPasslist, false);
                Integer  i = 0;
                for (Database.SaveResult sr : srList) {
                    User u = userResetPasslist[i];
                    Portal_user_update__c e = eventsMap.get(u.ContactId);
                    errorHandle(sr, e); 
                    i++;
                }
            }
            updateEvents(JSON.serialize(events));
            updateContactsAccounts(JSON.serialize(events));
        } catch(Exception ex) {
            system.debug(ex.getMessage() + ' . '+ex.getStackTraceString());
            for(Portal_user_update__c event : events){
                event.Status__c = 'Error'; 
                event.Reject_Reason__c = 'Code failure : '+ex.getMessage() + ' . '+ex.getStackTraceString();
            }
            updateEvents(JSON.serialize(events));
        }
    }
    
    public static void setProfileBeforeDeactivate(Portal_user_update__c event,User usr){
        String accountType = event.Contact__r.Account.Type;
        System.debug('accountType:'+accountType);
        List<Community_user_management_allowed__mdt> defaultSetting = [SELECT Label 
                                                                       FROM Community_user_management_allowed__mdt
                                                                      WHERE Account_Type__c=:accountType AND Activation_Default_Profile__c = true];
        System.debug('defaultSetting:'+defaultSetting);
        if(defaultSetting.size()==0){
            return ;
        }
        
        List<Profile> defaultProfile = [SELECT Id FROM Profile WHERE Name=:defaultSetting[0].Label]; 
        System.debug('defaultProfile:'+defaultProfile);
         if(defaultProfile.size()==0){
            return ;
        }
        usr.ProfileId = defaultProfile[0].Id;
    }
    
    public static void errorHandle(Database.SaveResult sr, Portal_user_update__c e ) {
        if (!sr.isSuccess()) {
            e.Status__c = 'Error';
            String rr = '';
            for (Database.Error er : sr.getErrors()) {
                rr += er.getMessage() + '\n';
            }
            e.Reject_Reason__c = rr;
        } else {
            e.Status__c = 'Success';	
            e.Reject_Reason__c = '';
        }
    }
    
    public static void errorHandle(Database.DeleteResult sr, Portal_user_update__c e ) {
        if (!sr.isSuccess()) {
            e.Status__c = 'Error';
            String rr = '';
            for (Database.Error er : sr.getErrors()) {
                rr += er.getMessage() + '\n';
            }
            e.Reject_Reason__c = rr;
        } else {
            e.Status__c = 'Success';	
            e.Reject_Reason__c = '';
        }
    }
    
    
    @Future 
    public static void updateEvents (String eventsSerialized) {
		System.debug('Rafa - updateEvents start');
        List<Portal_user_update__c> eventsToUpdate = (List<Portal_user_update__c>) JSON.deserialize(eventsSerialized, List<Portal_user_update__c>.class);
		System.debug('Rafa - eventsToUpdate: ' + eventsToUpdate);
        List<Contact> contactList = new List<Contact>();
        for (Portal_user_update__c event : eventsToUpdate ) {
            if (event.Reject_Reason__c != null){ 
                event.Full_Rejected_Reason__c = event.Reject_Reason__c;
                event.Reject_Reason__c = event.Reject_Reason__c.trim().left(254);
            }
            if(event.Type__c == 'Grant See All Cases' && event.Status__c=='Success' ){
                Contact con = new Contact();
                con.Id = event.Contact__c;
                con.Can_see_all_account_cases__c = true;
                contactList.add(con);
            }
            if(event.Type__c == 'Revoke See All Cases' && event.Status__c=='Success' ){
                Contact con = new Contact();
                con.Id = event.Contact__c;
                con.Can_see_all_account_cases__c = false;
                contactList.add(con);
            }
            if(event.Changed_TO__c!=null && event.Status__c=='Success'){
                Contact con = new Contact();
                con.Id = event.Contact__c;
                con.Community_role__c = event.Changed_TO__c;
                contactList.add(con);
            }
        }
        update contactList;
        update eventsToUpdate;
    }
    
    @Future
    public static void updateContactsAccounts(String eventsM){
	System.debug('Rafa - in the Future func');
	List<Portal_user_update__c> eventList = (List<Portal_user_update__c>) JSON.deserialize(eventsM, List<Portal_user_update__c>.class);
	Map<Id, Portal_user_update__c> userMap = new Map<Id, Portal_user_update__c>();

	System.debug('Rafa - eventsM: ' + eventList);
	for(Portal_user_update__c ev: eventList){
		userMap.put(ev.Id, ev);
	}
        List<Portal_user_update__c> events = [
            SELECT Id, Reject_Reason__c,Account__c, Contact__c, Contact__r.Email, Type__c, Status__c
            FROM Portal_user_update__c
            WHERE Id IN :userMap.keySet()];
        Set<Id> contactsIds = new Set<Id>();
        for(Portal_user_update__c e : events) {
            contactsIds.add(e.Contact__c);
        }
        System.debug('Rafa - events: ' + events);
		List<User> userList = [select id, contactId from user where contactId in : contactsIds];
		Map<Id, user> contactIdAndUserMap  = new Map<Id, user>();
		for(user u : userList){contactIdAndUserMap.put(u.ContactId, u);}
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([SELECT Id, AccountId, Email, Community_Account_Id__c, Is_In_Approval__c,Expiration_Date__c FROM Contact WHERE Id IN:contactsIds]);
        System.debug('Rafa - contactsMap: ' + contactsMap);
        List<Contact> toUpdate = new List<Contact>();
        List<User> toUserUpdate = new List<User>();
        Set<Id> toUpdateIds = new Set<Id>();
        for (Portal_user_update__c e : events){
            System.debug(contactsMap.get(e.Contact__c).Email + ' Contact : ' + contactsMap.get(e.Contact__c).AccountId + ' , event Account: ' + e.Account__c);
            if ( e.Contact__c!=null && !toUpdateIds.contains(e.Contact__c) && contactsMap.get(e.Contact__c).AccountId == null && ( e.Account__c!= null || contactsMap.get(e.Contact__c).Community_Account_Id__c != null)  ){
                String accId = contactsMap.get(e.Contact__c).Community_Account_Id__c;
                System.debug(contactsMap.get(e.Contact__c).Email + '  ' + contactsMap.get(e.Contact__c).Is_In_Approval__c);
                accId = (accId == null) ? e.Account__c : accId;  
                toUpdate.add(new Contact(id = e.Contact__c, accountId = accId, OwnerId = UserInfo.getUserId()));
                //toUpdate.add(new Contact(id = e.Contact__c, accountId = accId));
                toUpdateIds.add(e.Contact__c);
            }
			/// Add by Rafa by 26/06/22 ///
			if(userMap.containsKey(e.Id)){
				if(userMap.get(e.Id).Type__c == 'Poc Status' && userMap.get(e.Id).Status__c == 'Error' && contactsMap.get(e.Contact__c) != null ){
					toUpdate.add(new Contact(id = e.Contact__c, Expiration_Date__c = null));
					toUserUpdate.add(new User(Id = contactIdAndUserMap.get(e.Contact__c).Id, Expiration_Date__c = null));
				}
			}
        }

        System.debug('Contacts Updated size: ' + toUpdate.size());
        System.debug('Contacts Updated: ' + toUpdate);
		if(!toUserUpdate.isEmpty()){Database.update(toUserUpdate, false);}
        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] res = Database.update(toUpdate, false);
            for (Database.SaveResult r : res) {
                if (!r.isSuccess()) {
                    System.debug(r.getErrors());
                } else {
                    
                }
            }
        }
    }
}