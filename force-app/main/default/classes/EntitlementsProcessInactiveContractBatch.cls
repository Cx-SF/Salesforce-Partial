global class EntitlementsProcessInactiveContractBatch implements Database.Batchable<sObject>,Database.Stateful{
    //Test Class: EntitlementProcessControllerTest
    global List<EntitlementProcessErrorHandling.SaveResultClass> updateEntitlementListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
    List<String> accountsToProccess = new List<String>();

    public EntitlementsProcessInactiveContractBatch(List<String> accountsToProccess){
        this.accountsToProccess = accountsToProccess;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('IN start INACTIV');
		 
        // Retrieve contracts which need service availability removal.
         
 		//select accounts that not have user community activ and service_Availability is default
        /*List<AggregateResult> res = [select accountid from contact 
                                     where id not in (select contactid from user where isactive=true )//and Expiration_Date__c != NULL
                                     AND Account.Service_Availability__c='Default'
                                     AND accountid IN:accountsToProccess //only for testing
                                     group by accountid];
        List<AggregateResult> res = [select accountid, count(Id) activeUser   from user 
                                        where   isActive = true
                                        AND Account.Service_Availability__c='Default'
                                        and Expiration_Date__c != NULL //default account without active user
                                        and accountid IN:accountsToProccess //only for testing
                                        group by accountid];*/
        // for (AggregateResult r : res)
        // {
        //     if((Integer)r.get('activeUser') == 0)
        //         s.add((String)r.get('AccountId'));
        // } 

        List<Account> accWithUser = [SELECT Id,
         (SELECT Id from USERS where  isActive = true )//remove and Expiration_Date__c != NULL becouse first user dont have yet it
                                         FROM Account
                                         WHERE Service_Availability__c='Default'
                                         ];


        Set<Id> accountWithoutActiveUser = new Set<Id>();
        for (Account acc : accWithUser) {
            if(acc.USERS.size() == 0){//if not have active user
                accountWithoutActiveUser.add(acc.Id);
            }
        }
        System.debug('***accountWithoutActiveUser: '+accountWithoutActiveUser);   
        List<Grace_Period_days__mdt> Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];       
        List<AggregateResult> res2 = [select accountid,MAX(endDate) 
                                        from contract 
                                     // anat 10/10/21
                                     // accounts with default service avalability might have expired contracts; we still want to allow add active users for this accounts
                                        where accountid not in (select id from Account where Service_Availability__c='Default')
                                      // anat 10/10/21
                                        group by accountid];
                    
        Set<Id> accWithContractInvalid = new Set<Id>();

        for (AggregateResult r : res2)
        {
            Date endDate = (Date)r.get('expr0');
            Date endDatePlusGrace = endDate.addDays(Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c)) ;
            if(endDatePlusGrace < Date.today()){
                accWithContractInvalid.add((String)r.get('AccountId'));
            }
        }
        System.debug('***accWithContractInvalid: '+accWithContractInvalid);
        String EXPIREDLABEL = 'Expired';
         /*The query select accounts That they have contracts but that invalid.(end date + grace Period) 
         	OR -
           That they not have user community activ and service_Availability is default, select accounts with Entitlements that they not expired*/
        string query='select Id, Override_maximum_Portal_Users__c, (select id, enddate,startdate,Service_Availability__c, Status from Entitlements where Status != :EXPIREDLABEL ),(select id,CreatedDate,endDate from contracts)'; 
        //AND Id IN :accountsToProccess -only for testing
        query+=' from account where   (id in :accWithContractInvalid or id in :accountWithoutActiveUser)';
        if(accountsToProccess != null && accountsToProccess.size()>0)
        	query+=' AND id in :accountsToProccess';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){	
        System.debug('IN execute INACTIVE : '+scope);
        // Upadte all Accounts entitlements relation and fields
        updateAccsEntitlementsRelationAndFields(scope);
        
    }


     public void updateAccsEntitlementsRelationAndFields(List<Account> accs){
        List<Entitlement> upsertEntitlementList=new List<Entitlement>();
   		upsertEntitlementList.clear(); 
         //expired Entitlements of accounts
        for(Account acc: accs){
            System.debug('***acc: '+acc);   
            for(Entitlement en:acc.Entitlements){
                if(en.startdate == Date.today()){
                    en.startdate=system.today().addDays(-2);
                }
                en.endDate=system.today().addDays(-1);
                upsertEntitlementList.add(en);
            }
            acc.Service_Availability__c = NULL;
        }   
        Database.SaveResult[]  updateAccResult= Database.update(accs, false);
        Database.SaveResult[]  updateEntitlementResult= Database.update(upsertEntitlementList, false);
        updateEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateEntitlementResult,accs));
    }
    
    global void finish(Database.BatchableContext BC){
        CommunityUsersExpirationBatch EntBatch = new CommunityUsersExpirationBatch(accountsToProccess);
        string batchId = Database.executeBatch(EntBatch,10);
        if(updateEntitlementListError.size()>0)
            EntitlementProcessErrorHandling.sendEmail('Entitlement', updateEntitlementListError,'EntitlementsProcessInactiveContractBatch');
    }
}