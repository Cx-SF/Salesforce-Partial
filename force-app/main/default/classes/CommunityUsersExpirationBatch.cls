global class CommunityUsersExpirationBatch implements Database.Batchable<sObject>, Database.Stateful {
    global List<Contact> contactToUpdate = new List<Contact>();
    global List<Grace_Period_days__mdt> Grace_Period_days;
    List<String> accountsToProccess = new List<String>();

    public CommunityUsersExpirationBatch(List<String> accountsToProccess){
        this.accountsToProccess = accountsToProccess;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){   
        //AND Id IN :accountsToProccess -only for testing
        String query = 'SELECT ID,Service_Availability__c,(SELECT isactive,ID,ContactId,CreatedDate,Contact.OverrideExpirationDate__c,Expiration_Date__c, UserType, Contact.CX_POC_user__c FROM USERS '+
             'where isActive=true or (isActive = false and Expiration_Date__c != null) ),'+
                                         '(SELECT ID , EndDate FROM Contracts where EndDate!=NULL )  FROM ACCOUNT '+
              ' WHERE Id IN (SELECT AccountId FROM USER where isActive=true or (isActive = false and Expiration_Date__c != null)) ' ;
        if(accountsToProccess != null && accountsToProccess.size()>0)
        	query += ' AND Id IN :accountsToProccess ';
        return Database.getQueryLocator(query);
    }
        
    global void execute(Database.BatchableContext BC, List<Account> scope){
        User_deactivation_settings__mdt userActivation = [SELECT Default_activation_period__c FROM User_deactivation_settings__mdt  LIMIT 1];
        Integer activationPeriod  = Integer.valueOf(userActivation.Default_activation_period__c);//Use for user that not have contract
        Boolean inActive = false;
        Map<Id,User> usersToUpdate = new Map<Id,User>();
        
        for(Account acc : scope){
            Date maxContractendDate;
            if(acc.Service_Availability__c != 'Default'){
                for(Contract con:acc.contracts){
                    if(maxContractendDate==null){
                        maxContractendDate=con.EndDate;
                    }
                    else if(con.EndDate>maxContractendDate){
                        maxContractendDate=con.EndDate;
                    }
                }
            }
            system.debug('***maxContractendDate: '+maxContractendDate);
            
            // Anat 27/10/21: 
            // Get Contracts grace period
            
               Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
               Integer graceDays = (Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c));
             // Anat 27/10/21: 
            
            for(User usr:acc.Users)
                if (usr.UserType!='PowerPartner')
{
              
                if(usr.ContactId!=null && usr.Contact.OverrideExpirationDate__c!=null){//Update user.Expiration_Date to contact.OverrideExpirationDate when have OverrideExpirationDate to contact
                    if(usr.Contact.OverrideExpirationDate__c!=usr.Expiration_Date__c){
                        usr.Expiration_Date__c = usr.Contact.OverrideExpirationDate__c;
                        usersToUpdate.put(usr.Id,usr);
                    }
                }
                // Anat 27/10/21:
                // User with active contract
                
                //else if(maxContractendDate!=null && (usr.Expiration_Date__c==null || usr.Expiration_Date__c<maxContractendDate))
				// Rafa add Contact.CX_POC_user__c == false) 12/07/22
                else if(maxContractendDate!=null && (usr.Expiration_Date__c==null || usr.Expiration_Date__c<maxContractendDate.addDays(graceDays)) && usr.Contact.CX_POC_user__c == false)
                            
                
                {// if user.Expiration_Date null or less from endDate of max contract + grace period
                    // Anat 27/10/21
                       //Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
                       //Integer graceDays = (Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c));
                    // Anat 27/10/21
                    usr.Expiration_Date__c = maxContractendDate.addDays(graceDays);//Add grec to date
                    usersToUpdate.put(usr.Id,usr);

                }
                // User without active contract
                //else if(maxContractendDate==null &&  usr.Expiration_Date__c != usr.createdDate.addDays(activationPeriod).date() ) {// No have contracts
				// Rafa add Contact.CX_POC_user__c == false) 12/07/22
                else if(maxContractendDate==null &&  usr.Expiration_Date__c == null && usr.Contact.CX_POC_user__c == false) {
                    usr.Expiration_Date__c = DateTime.now().addDays(activationPeriod).date();
                    system.debug('*57**usr.Expiration_Date__c: '+usr.Expiration_Date__c);
                    usersToUpdate.put(usr.Id,usr);
                }
                if(usr.Expiration_Date__c<=Date.today() && usr.isActive==true ){
                    usr.Expiration_Date__c = NULL; // Nullify expiration date
                    usr.isActive = false;
                    inActive = true;
                    usersToUpdate.put(usr.Id,usr);
                    system.debug('*65**usr.Expiration_Date__c: '+usr.Expiration_Date__c);
                }else if(usr.Expiration_Date__c != NULL && usr.IsActive == false ){
                    usr.Expiration_Date__c = NULL; // Nullify expiration date
                    usersToUpdate.put(usr.Id,usr);
                    system.debug('*69**usr.Expiration_Date__c: '+usr.Expiration_Date__c);
                }
                Contact cont;
                if(inActive){
                    cont = new Contact(Id = usr.ContactId,Expiration_Date__c =usr.Expiration_Date__c, CX_Auto_Update_Expiration_Date__c = Date.today());
                }else{
                    cont = new Contact(Id = usr.ContactId,Expiration_Date__c =usr.Expiration_Date__c);
                } 
                contactToUpdate.add(cont);
            }
        }
        Update usersToUpdate.values();
        
    }
    
    global void finish(Database.BatchableContext BC){
        UpdateContCommunityUserExpirationBatch  UpdatBatch = new UpdateContCommunityUserExpirationBatch(contactToUpdate);
        Database.executeBatch(UpdatBatch);      
    }
}