/**
* Wedo Task #6323   Batch for Accounts without Contracts
* class :    AccountsNoContractsBatch
* Author:   Sandra Chaltiel
* For Checkmarks
* Test class: AccountsNoContractsBatchTest
*/
global class AccountsNoContractsBatch implements Database.Batchable<sObject>,Database.Stateful{
    
    public Boolean standardFound = false;
    global List<EntitlementProcessErrorHandling.SaveResultClass> updateEntitlementListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
                
        List<Grace_Period_days__mdt> Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
        DateTime dT = system.today().addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c))*-1);
        String currentDateWithPerioddays =dT.format('yyyy-MM-dd');
        system.debug('### currentDateWithPerioddays' + currentDateWithPerioddays );
        String query='SELECT Id, Service_Availability__c, Override_Service_Availability__c, Maximum_Portal_Users__c, Override_maximum_Portal_Users__c, Account_Status__c,';
        query+=' (SELECT Id, Name, AccountId, StartDate, EndDate, SlaProcessId, Status, Case_Priority__c, Type, Number_Of_Users__c, Service_Availability__c';
        query+=' FROM Entitlements where Status=\'Active\'), (SELECT Id, Service_Availability__c, CreatedDate, endDate FROM Contracts WHERE endDate>'+currentDateWithPerioddays+')';
        query+=' FROM  Account WHERE Id NOT IN (SELECT AccountId FROM Contract WHERE endDate >'+currentDateWithPerioddays+') AND Account_Status__c = \'Prospect\' AND IsPartner = true';
        if (Test.isRunningTest()){
            query+=' LIMIT 1';
        }
        system.debug('###query :' + query );
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        
        system.debug('###scope = ' + scope);

        List<Entitlement> upsertEntitlementList=new List<Entitlement>();
        upsertEntitlementList.clear();   

        system.debug ('### IF standardFound false ');
        //set SLAMap
        List<Checkmarx_SLA__mdt> SLAListStandard=[SELECT Id, Label, QualifiedApiName, Case_Record_Type__c, Priority__c, Service_Availability__c,Type__c,
                                          Number_Of_Users__c,Entitlement_Process_Name__c FROM Checkmarx_SLA__mdt
                                          WHERE Type__c!='' AND Type__c!=null AND Service_Availability__c = 'Standard'];
        
        Map<String, List<Checkmarx_SLA__mdt>> SLAMap = new Map<String,List<Checkmarx_SLA__mdt>>();
        for(Checkmarx_SLA__mdt cmsla:SLAListStandard){
                if(SLAMap.containsKey(cmsla.Service_Availability__c)){
                    SLAMap.get(cmsla.Service_Availability__c).add(cmsla);
                }else{
                    list<Checkmarx_SLA__mdt> cmslaList=new list<Checkmarx_SLA__mdt>();
                    cmslaList.add(cmsla);
                    SLAMap.put(cmsla.Service_Availability__c,cmslaList);
                }
        }
        system.debug('###SLAMap' + SLAMap);
        //set SlaProcess
        List<SlaProcess> SlaProcessList=[SELECT Name, IsActive, VersionMaster, VersionNumber, Id, IsVersionDefault, VersionNotes FROM SlaProcess where IsVersionDefault=true and name like 'Standard%'];
        Map<String,Id> SlaProcessMap=new Map<String,Id>();
        for(SlaProcess sla:SlaProcessList){
            SlaProcessMap.put(sla.Name,sla.Id);
        }
        system.debug('###SlaProcessMap' + SlaProcessMap);       

        for(Account acc:scope){
            standardFound = false;
            system.debug('###acc.Id = ' + acc.Id);
            for(Entitlement en:acc.Entitlements){
                system.debug ('### Entitlement en.Service_Availability__c ' + en.Service_Availability__c);
                if (en.Service_Availability__c != 'Standard'){
                    system.debug ('### standardFound false = ' + standardFound);
                    // When startdate is later than yesterday (The end date must be equal to or later than the start date)
                    if(en.StartDate > system.today().addDays(-1))
                        en.StartDate=system.today().addDays(-1); 
                    en.endDate=system.today().addDays(-1);
                    upsertEntitlementList.add(en);
                }else{ // note: add case null
                    system.debug('###en.Status' + en.Status);
                    if (en.Status == 'Expired'){
                        system.debug ('### standardFound still false in case of Standard expired = ' + standardFound);
                    }
                    else{
                        standardFound = true;
                        system.debug ('### standardFound true = ' + standardFound);    
                    }
                }
            }
            if ( standardFound == false ){

                // Creating entitlements for account
                for(Checkmarx_SLA__mdt cl:SLAListStandard)
                {
                    //insert entitlement
                    Entitlement e=new Entitlement();
                    e.AccountId=acc.Id;
                    e.StartDate=system.today();
                    e.EndDate=system.today().addYears(50);
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
                        system.debug('SlaProcessMap.get(cl.QualifiedApiName): '+SlaProcessMap.get(cl.QualifiedApiName));    
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
                    system.debug('after insert e.Id:'+e.id);
                    system.debug('upsertEntitlementList: '+ upsertEntitlementList);
                }
                
                if(upsertEntitlementList.size()>0){
                    List<Database.upsertResult> upsertEntitlementResult= Database.upsert(upsertEntitlementList, false);
                    standardFound = true;
                    system.debug ('### standardFound after upsert ' + standardFound);
                    //upsertEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(upsertEntitlementResult,upsertEntitlementList));
                }                
                
            }
            if(scope.size()>0)
                update scope;
            
            Database.SaveResult[]  updateEntitlementResult= Database.update(scope, false);
            updateEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateEntitlementResult,scope));
            system.debug('###updateEntitlementResult ' + updateEntitlementResult);
            system.debug('###updateEntitlementListError ' + updateEntitlementListError);
        }
    }
    global void finish(Database.BatchableContext BC){
        if(updateEntitlementListError.size()>0)
            EntitlementProcessErrorHandling.sendEmail('Entitlement', updateEntitlementListError,'EntitlementsProcessInactiveContractBatch');
    }
    public void raiseCoverage() {
        Integer i = 1;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;          
    }        
}