global class EntitlementsProcessActiveContractBatch implements Database.Batchable<sObject>,Database.Stateful {
    //Test Class: EntitlementProcessControllerTest
    //
    global List<EntitlementProcessErrorHandling.SaveResultClass> upsertAccountListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
    global List<EntitlementProcessErrorHandling.SaveResultClass> upsertEntitlementListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
    global List<Grace_Period_days__mdt> Grace_Period_days;
    Map<String,Id> SlaProcessMap;
    List<String> accountsToProccess = new List<String>();

    public EntitlementsProcessActiveContractBatch(List<String> accountsToProccess){
        this.accountsToProccess = accountsToProccess;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){        
        Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
        DateTime dT=system.today();
        if(Grace_Period_days.size()>0){
            dT = system.today().addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c))*-1);
        }
        String currentDateWithPerioddays =dT.format('yyyy-MM-dd');
        
        // Default SLA retrieval - Retrieve all Accounts with Active community users and 
        // Added Expiration_Date__c = NULL, Dec 2020
        List<AggregateResult> res = [select accountid from contact 
                                     where id in (select contactId from user where isactive=true and (Expiration_Date__c > today or Expiration_Date__c = NULL)) //and Expiration_Date__c = NULL
                                     AND Account.Service_Availability__c=''
                                     group by accountid];
        
        system.debug('***IN execute res1: '+res);
        Set<Id> s = new Set<Id>();
        for (AggregateResult r : res)
        {
            s.add((String)r.get('AccountId'));
        }  
        //Retrieve all accounts with active contracts                            
        res = [SELECT accountid FROM contract WHERE endDate>=:dt.date()  group by accountid];//AND accountid IN:accountsToProccess only for testing
        
        for (AggregateResult r : res)
        {
            s.add((String)r.get('AccountId'));
        }

         system.debug('***IN execute res2: '+res);
         string query='SELECT Name,Id,Service_Availability__c,Override_Service_Availability__c,Maximum_Portal_Users__c,Override_maximum_Portal_Users__c';
                query+=',(SELECT Id, Name, AccountId, StartDate, EndDate, SlaProcessId,status,Case_Priority__c,Type,Number_Of_Users__c,Service_Availability__c FROM Entitlements where status=\'Active\')';
                query+=',(SELECT id,Service_Availability__c,CreatedDate,endDate FROM contracts WHERE   endDate>= '+currentDateWithPerioddays+'  And Status!=\'Terminated\'  And Status!=\'Expired\' )';
                query+=',(SELECT AccountId,isActive,CreatedDate FROM users ) ';        
               query+='FROM account WHERE   id IN: s ' ;
        	   if(accountsToProccess != null && accountsToProccess.size()>0)
               		query+= 'AND id IN: accountsToProccess';
        return Database.getQueryLocator(query);
        
        
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        system.debug('***IN execute: '+scope);
		system.debug('***IN scope: '+scope);
        Map<String,Service_Availability__mdt> ServiceAvailabilityMap=new Map<String,Service_Availability__mdt>();
        // Loop all service availability types from metadata 
        for(Service_Availability__mdt sam:[select Label,Order__c from Service_Availability__mdt]){
            if (!(ServiceAvailabilityMap.containsKey(sam.Label))) {
                ServiceAvailabilityMap.put(sam.Label, sam);
            }
        }             
        
        //set CheckmarxSLAMap
        List<Checkmarx_SLA__mdt> checkmarxSLAList=[SELECT Id, Label, QualifiedApiName, Case_Record_Type__c, Priority__c, Service_Availability__c,Type__c,
                                                   Number_Of_Users__c,Entitlement_Process_Name__c FROM Checkmarx_SLA__mdt where Type__c!='' and Type__c!=null];
        Map<String,List<Checkmarx_SLA__mdt>> CheckmarxSLAMap=new Map<String,List<Checkmarx_SLA__mdt>>();
        for(Checkmarx_SLA__mdt cmsla:checkmarxSLAList){
            if(CheckmarxSLAMap.containsKey(cmsla.Service_Availability__c))
            {
                CheckmarxSLAMap.get(cmsla.Service_Availability__c).add(cmsla);
            }
            else
            {
                list<Checkmarx_SLA__mdt> cmslaList=new list<Checkmarx_SLA__mdt>();
                cmslaList.add(cmsla);
                CheckmarxSLAMap.put(cmsla.Service_Availability__c,cmslaList);
            }
        }
        //set SlaProcess
        List<SlaProcess> SlaProcessList=[SELECT Name, IsActive, VersionMaster, VersionNumber,
                                         Id, IsVersionDefault, VersionNotes 
                                         FROM SlaProcess where IsVersionDefault=true];
        SlaProcessMap=new Map<String,Id>();
        for(SlaProcess sla:SlaProcessList){
            SlaProcessMap.put(sla.Name,sla.Id);
        }
        
        boolean isExist;
        decimal accountNumberOfUser;
        string accountServiceAvailability;
        List<Entitlement> upsertEntitlementList=new List<Entitlement>();
        upsertEntitlementList.clear();
        List<Account> accountToChangeStatus = new List<Account>();
        // Loop - all Accounts fetched above, 
        for(Account acc:scope){
            system.debug('***IN acc.contracts: '+acc.contracts);
            if(acc.contracts==null || acc.contracts.isEmpty()){
                
                // 9.6 : Check if need to udpate entitlements for Accounts that has active Contracts
                if(acc.Service_Availability__c==NULL || acc.Service_Availability__c=='Default'){
                    accountToChangeStatus.add(acc);
                }
                continue;
            }
            try {
                accountNumberOfUser=null;
                string serviceAvailability=[select Label,Order__c from Service_Availability__mdt order by Order__c desc limit 1].label;
                Contract maxContract=acc.contracts[0];
                //Get contract end date by order of service availability 
                for(Contract con:acc.contracts)
                {
 
                    string contractServiceAvailability=con.Service_Availability__c; 
                    if((ServiceAvailabilityMap.get(serviceAvailability)).Order__c>(ServiceAvailabilityMap.get(contractServiceAvailability)).Order__c)
                    {
                        serviceAvailability=contractServiceAvailability; 
                        maxContract=con;
                    }
                    
                }
                Date maxContractendDate=maxContract.EndDate;
                if(Grace_Period_days.size()>0){
                    maxContractendDate = maxContract.EndDate.addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c)));
                }
                accountServiceAvailability=serviceAvailability;
                list<Checkmarx_SLA__mdt> cmslaListExpectedFromContract=new list<Checkmarx_SLA__mdt>();
                if(CheckmarxSLAMap.get(accountServiceAvailability)!=null){
                    cmslaListExpectedFromContract=CheckmarxSLAMap.get(serviceAvailability);
                    for(Checkmarx_SLA__mdt sla:cmslaListExpectedFromContract)
                        if(sla.Type__c=='User Managment'){
                            accountNumberOfUser=sla.Number_Of_Users__c;
                            break;
                        }
                    
                }
                
                
                if(acc.Override_Service_Availability__c!=null && acc.Override_Service_Availability__c!='')  
                    serviceAvailability=acc.Override_Service_Availability__c;
                
                
                list<Checkmarx_SLA__mdt> cmslaListExpected=new list<Checkmarx_SLA__mdt>();
                if(CheckmarxSLAMap.get(serviceAvailability)!=null)
                    cmslaListExpected=CheckmarxSLAMap.get(serviceAvailability).clone();  
                system.debug('***IN acc.Entitlements: '+acc.Entitlements);
                for(Entitlement e:acc.Entitlements)
                {
                    isExist=false;
                    integer i=0;
                    while(i<cmslaListExpected.size()){
                        Checkmarx_SLA__mdt cl=cmslaListExpected[i];
                        
                        
                        if(e.Type==cl.Type__c && e.Case_Priority__c==cl.Priority__c && e.Service_Availability__c==cl.Service_Availability__c){
                            //i++;
                            //update SLA/OLA entitlement
                            e.StartDate=date.newinstance(maxContract.CreatedDate.year(), maxContract.CreatedDate.month(), maxContract.CreatedDate.day());
                            e.EndDate=maxContractendDate;
                            e.Case_Priority__c=cl.Priority__c;
                            e.Case_Record_Type__c=cl.Case_Record_Type__c;
                            e.Service_Availability__c=cl.Service_Availability__c;
                            
                            if(e.Type!='User Managment'){
                                if(SlaProcessMap.get(cl.Entitlement_Process_Name__c)!=null)
                                    e.SlaProcessId=SlaProcessMap.get(cl.Entitlement_Process_Name__c);
                                else
                                    e.SlaProcessId=null;
                                if(cl.Priority__c!='' && cl.Priority__c!=null)
                                    e.Name= cl.Type__c+': '+cl.Service_Availability__c+'_'+cl.Priority__c;
                                else
                                    e.Name= cl.Type__c+': '+cl.Service_Availability__c;
                                e.Type=cl.Type__c;
                            }
                            //Update User Managment Entitlement
                            if(e.Type=='User Managment'){
                                if(acc.Override_maximum_Portal_Users__c!=null)  
                                    e.Number_Of_Users__c=acc.Override_maximum_Portal_Users__c;
                                else
                                    e.Number_Of_Users__c=cl.Number_of_users__c;
                                e.Name=cl.Type__c+': '+cl.Service_Availability__c;
                                e.Type=cl.Type__c;
                            }
                            
                            isExist=true;
                            cmslaListExpected.remove(i);
                        }
                        
                        else{
                            i++;}
                        
                    }
                    if(!isExist){
                        //inactive old entitlement
                        //when startdate in later than yesterday (The end date must be equal to or later than the start date)
                        if(e.StartDate>system.today().addDays(-1))
                            e.StartDate=system.today().addDays(-1); 
                        e.EndDate=system.today().addDays(-1);
                    }
                    upsertEntitlementList.add(e);
                }
                for(Checkmarx_SLA__mdt cl:cmslaListExpected)
                {


                    Entitlement e=new Entitlement();
                    e.AccountId=acc.Id;
                    e.StartDate=date.newinstance(maxContract.CreatedDate.year(), maxContract.CreatedDate.month(), maxContract.CreatedDate.day());
                    e.EndDate=maxContractendDate;
                    e.Case_Priority__c=cl.Priority__c;
                    e.Case_Record_Type__c=cl.Case_Record_Type__c;
                    e.Service_Availability__c=cl.Service_Availability__c;
                    
                    //insert SLA entitlement
                    if(cl.Type__c!='User Managment'){
                        if(cl.Priority__c!='' && cl.Priority__c!=null)
                            e.Name= cl.Type__c+': '+cl.Service_Availability__c+'_'+cl.Priority__c;
                        else
                            e.Name= cl.Type__c+': '+cl.Service_Availability__c;
                        e.Type=cl.Type__c;
                        if(SlaProcessMap.get(cl.Entitlement_Process_Name__c)!=null)
                            e.SlaProcessId=SlaProcessMap.get(cl.Entitlement_Process_Name__c);
                        else
                            e.SlaProcessId=null;
                    }
                    //insert user managment entitlement
                    if(cl.Type__c=='User Managment'){
                        if(acc.Override_maximum_Portal_Users__c!=null)  
                            e.Number_Of_Users__c=acc.Override_maximum_Portal_Users__c;
                        else
                            e.Number_Of_Users__c=cl.Number_of_users__c;
                        e.Name=cl.Type__c+': '+cl.Service_Availability__c;
                        e.Type=cl.Type__c;
                    }
                    upsertEntitlementList.add(e);
                }
                
                //for test of EntitlementProcessErrorHandling
                if(Test.isRunningTest()){
                    acc.name='';
                }
                acc.Maximum_Portal_Users__c=accountNumberOfUser;
                acc.Service_availability__c=accountServiceAvailability;
            }catch(Exception ex){
                upsertAccountListError.add(new EntitlementProcessErrorHandling.SaveResultClass(acc.Id,ex.getMessage()+'. Stacktrace:'+ex.getStackTraceString()));
            }
        }
        //end fix entitlements for account with contract
        List<Entitlement> entList = createEntitlementAndUpdateAccount(accountToChangeStatus);
        upsertEntitlementList.addAll(entList);
        
        //update all accounts - (defulat and contracted)
        if(scope.size()>0){
            system.debug('***IN update accounts : '+scope);
            Database.SaveResult[] updateAccountResult = Database.update(scope, false);
            system.debug('***IN updateAccountResult: '+updateAccountResult);
            upsertAccountListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateAccountResult,scope));
        }
        
        if(upsertEntitlementList.size()>0){
            system.debug('***IN upsertEntitlementList: '+upsertEntitlementList);
            List<Database.upsertResult> upsertEntitlementResult= Database.upsert(upsertEntitlementList, false);
            upsertEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(upsertEntitlementResult,upsertEntitlementList));
            system.debug('***IN upsertEntitlementResult: '+upsertEntitlementResult);
        }
    }
    global void finish(Database.BatchableContext BC){
        
        EntitlementsProcessInactiveContractBatch EntBatch = new EntitlementsProcessInactiveContractBatch(accountsToProccess);
        string batchId = Database.executeBatch(EntBatch,10);
        if(upsertAccountListError.size()>0)
            EntitlementProcessErrorHandling.sendEmail('Account', upsertAccountListError,'EntitlementsProcessActiveContractBatch');
        if(upsertEntitlementListError.size()>0)
            EntitlementProcessErrorHandling.sendEmail('Entitlement', upsertEntitlementListError,'EntitlementsProcessActiveContractBatch');
        
    }
    
    @TestVisible 
    private List<Entitlement> createEntitlementAndUpdateAccount(List<Account> accList){
        List<Entitlement> entitlementsToCreate = new List<Entitlement>();
        for(Account acc : accList){
            try {
                Boolean haveActiveUser = false;
                if(acc.Users != null){
                    for(User usr: acc.Users){
                        if(usr.IsActive){
                            haveActiveUser = true;
                            break;
                        }
                    }
                }
                
                if(haveActiveUser && (acc.Service_Availability__c==null || acc.Service_Availability__c=='')){
                    acc.Service_Availability__c='Default';
                    entitlementsToCreate.addAll(createEntitlements(acc));
                }
            }catch(Exception ex){
                upsertAccountListError.add(new EntitlementProcessErrorHandling.SaveResultClass(acc.Id,ex.getMessage()+'. Stacktrace:'+ex.getStackTraceString()));
            }
        }
        //Need to check if update all scope update accList acc - 21-07-2021
        //Database.SaveResult[] updateAccountResult = Database.update(accList, false);
        //upsertAccountListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateAccountResult,accList));

        return entitlementsToCreate;
    }
    
    @TestVisible
    private List<Entitlement> createEntitlements(Account acc){
        User_deactivation_settings__mdt setting = [SELECT Default_SLA_Period_Days__c FROM User_deactivation_settings__mdt LIMIT 1];
        List<Entitlement> resultList = new List<Entitlement>();
        List<Checkmarx_SLA__mdt> checkmarxSLAList=[SELECT Id, Label, QualifiedApiName,
                                                   Case_Record_Type__c, Priority__c,
                                                   Service_Availability__c,
                                                   Type__c,Number_Of_Users__c,
                                                   Entitlement_Process_Name__c FROM Checkmarx_SLA__mdt where 
                                                   Service_Availability__c='Default'];
        for(Checkmarx_SLA__mdt sla : checkmarxSLAList){
            Entitlement e=new Entitlement();
            e.AccountId=acc.Id;
            e.StartDate=getFirstUserCreatedDate(acc);
            Date endD = setting.Default_SLA_Period_Days__c != null ? Date.today().addDays(Integer.valueOf(setting.Default_SLA_Period_Days__c)) :Date.today().addYears(10);
            e.EndDate= endD;
            e.Case_Priority__c=sla.Priority__c;
            e.Case_Record_Type__c=sla.Case_Record_Type__c;
            e.Service_Availability__c=sla.Service_Availability__c;
            e.Type=sla.Type__c;
            e.Number_Of_Users__c=sla.Number_Of_Users__c;
            if(acc.Override_maximum_Portal_Users__c!=null)
                e.Number_Of_Users__c=acc.Override_maximum_Portal_Users__c;
            e.SlaProcessId=SlaProcessMap.get(sla.Entitlement_Process_Name__c);
            if(sla.Priority__c!='' && sla.Priority__c!=null)
                e.Name= sla.Type__c+': '+sla.Service_Availability__c+'_'+sla.Priority__c;
            else
                e.Name= sla.Type__c+': '+sla.Service_Availability__c;
            resultList.add(e);
        }
        return resultList;
    }
    
    private Date getFirstUserCreatedDate(Account acc){
        DateTime defaultDt = DateTime.now();
        //not sure need the below code 14/10/2021
        // for(User usr : acc.Users){
        //     if(usr.CreatedDate < defaultDt ){
        //         defaultDt = usr.CreatedDate;
        //     }
        // }
        Date myDate = date.newinstance(defaultDt.year(), defaultDt.month(), defaultDt.day());
        return myDate;
    }
}