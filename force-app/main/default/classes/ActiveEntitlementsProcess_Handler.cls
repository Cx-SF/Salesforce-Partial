/*
	Date: 01/04/2023
	Developer Name : Refael Dabush
	Version : 1.0
	Class functionality - Holds function for ActiveEntitlementsProcess_Batch
*/
public class ActiveEntitlementsProcess_Handler  {
	private static List<Grace_Period_days__mdt> Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
	private static DateTime dT = system.today();

	// getData Function sending the data for ActiveEntitlementsProcess_Batch based on the run number 
	public static Map<String, Object> getData (Integer numberOfRun){
		Map<String, Object> objMap = new Map<String, Object>();
		if(numberOfRun == 1){
			List<String> accountsId = new List<String>();
			if(Grace_Period_days.size()>0){
				dT = system.today().addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c))*-1);
			}
			String currentDateWithPerioddays =dT.format('yyyy-MM-dd');
			List<AggregateResult> res = [SELECT accountid FROM contract WHERE endDate>=:dt.date() group by accountid];
			for (AggregateResult r : res){
				accountsId.add((String)r.get('AccountId'));
			}

			String q = 'SELECT Name,Id,Service_Availability__c,Override_Service_Availability__c,Maximum_Portal_Users__c,Override_maximum_Portal_Users__c,of_Open_Opportunities__c,CX_GS_Segmentation__c,Strategic_Account__c';
			q+=',(SELECT Id, Name, AccountId, StartDate, EndDate, SlaProcessId,status,Case_Priority__c,Type,Number_Of_Users__c,Service_Availability__c FROM Entitlements where status=\'Active\')';
            q+=',(SELECT id,Service_Availability__c,CreatedDate,endDate FROM contracts WHERE   endDate>= '+currentDateWithPerioddays+'  And Status!=\'Terminated\'  And Status!=\'Expired\' )';
            q+=',(SELECT AccountId,isActive,CreatedDate FROM users ) ';        
			q+='FROM account WHERE   id IN: accountsId';

			objMap.put('q', q);
			objMap.put('accountsId', accountsId);
		}else if(numberOfRun == 2){
			System.debug('In number Run 2');
			List<Contract> contractList = [select Partner_Account__r.name, ContractNumber, Account.name,  Partner_Account__r.Service_Availability__c, Active__c, EndDate, Service_Availability__c from Contract where Active__c = true and Partner_Account__r.name != null and (Partner_Account__r.Service_Availability__c = null or Partner_Account__r.Service_Availability__c = 'Default') Order by Partner_Account__r.name];
			Map<Id, Contract> partnerAccountIdVSContractMap = new Map<Id, Contract>();
			for(Contract con : contractList) {partnerAccountIdVSContractMap.put(con.Partner_Account__r.Id, con);}

			 String q = 'Select Name, Service_Availability__c, CX_GS_Segmentation__c,Strategic_Account__c,(Select ContractNumber, Active__c, EndDate, Service_Availability__c from Contracts where Active__c = true) from Account Where Id In : partnerAccIdList Order by name';

			objMap.put('partnerAccountIdVSContractMap', partnerAccountIdVSContractMap);
			objMap.put('q', q);
		}else if(numberOfRun == 3){

			if(Grace_Period_days.size()>0){
				dT = system.today().addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c))*-1);
			}
			String currentDateWithPerioddays =dT.format('yyyy-MM-dd');

			String q = 'SELECT Name, Id, CX_ConsolidatedAccount__r.NAME, CX_ConsolidatedAccount__r.Service_Availability__c, Service_Availability__c, Override_Service_Availability__c, Maximum_Portal_Users__c, Override_maximum_Portal_Users__c, of_Open_Opportunities__c,CX_GS_Segmentation__c,Strategic_Account__c';
			q+=',(SELECT Id, Name, AccountId, StartDate, EndDate, SlaProcessId,status,Case_Priority__c,Type,Number_Of_Users__c,Service_Availability__c FROM Entitlements where status=\'Active\')';
            q+=',(SELECT id,Service_Availability__c,CreatedDate,endDate FROM contracts WHERE   endDate>= '+currentDateWithPerioddays+'  And Status!=\'Terminated\'  And Status!=\'Expired\' )';
            q+=',(SELECT AccountId,isActive,CreatedDate FROM users ) ';        
			q+='FROM account WHERE   CX_ConsolidatedAccount__r.NAME != NULL AND (Service_Availability__c = NULL OR Service_Availability__c = \'Default\') ORDER BY CX_ConsolidatedAccount__r.NAME';
			objMap.put('q', q);
		}else if(numberOfRun == 4){
		}else if(numberOfRun == 5){
		}else if(numberOfRun == 6){
		}

		return objMap;
	}

	public static Map<String, Object> getUpdateInsertEntitlemrnt(List<Account> accountList){
	    List<EntitlementProcessErrorHandling.SaveResultClass> upsertAccountListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
		Map<String, Object> resMap = new Map<String, Object>();
		Map<String,Id> SlaProcessMap;
		boolean isExist;
        decimal accountNumberOfUser;
        string accountServiceAvailability;
        //List<Entitlement> upsertEntitlementList=new List<Entitlement>();
        //upsertEntitlementList.clear();
		List<Account> updateAccountList = new List<Account>();
		List<Entitlement> updateEntitlementList = new List<Entitlement>();
		List<Entitlement> insertEntitlementList = new List<Entitlement>();
        List<Account> accountToChangeStatus = new List<Account>();
        // Loop - all Accounts fetched above, 
		Map<String,Service_Availability__mdt> ServiceAvailabilityMap = new Map<String,Service_Availability__mdt>();
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
        for(Account acc:accountList)
        {
            
            system.debug('***IN acc.contracts: '+acc.contracts);
            
            // Sep. 2022 - new Default Logic
            // Add a new flag to account to mark accounts that will use a new default logic
            if (acc.of_Open_Opportunities__c > 0 && acc.Service_Availability__c == null) acc.Default_Entitlements_New_Process__c = true; //put in the try
            
            /*if(acc.contracts==null || acc.contracts.isEmpty()){
                
                // 9.6 : Check if need to udpate entitlements for Accounts that has active Contracts
                if(acc.Service_Availability__c==NULL || acc.Service_Availability__c=='Default'){
                    accountToChangeStatus.add(acc);
                }
                continue;
            }*/
            system.debug('TESTING *****1');
            try {
                
                system.debug('TESTING *****1');
                accountNumberOfUser=null;
				/// Rafa -- 16/4
                string serviceAvailability=[select Label,Order__c from Service_Availability__mdt order by Order__c desc limit 1].label;
                
                Contract maxContract=acc.contracts[0];
               //Sep 2022 Remove ->  Contract maxContract = null;
                if (acc!=null && acc.contracts.size()>0) maxContract=acc.contracts[0];
                //Get contract end date by order of service availability 
                //Sep 2022 Remove ->if (acc!=null && acc.contracts!=null && acc.contracts.size()>0) 
                    for(Contract con:acc.contracts)
                {
 
                    string contractServiceAvailability=con.Service_Availability__c; 
                    if((ServiceAvailabilityMap.get(serviceAvailability)).Order__c>(ServiceAvailabilityMap.get(contractServiceAvailability)).Order__c)
                    {
                        serviceAvailability=contractServiceAvailability; 
                        maxContract=con;
                    }
                    
                }

				////// 
				//entitlement prosses lokup object in Account

				/// Rafa - add additional level service availability Tier /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				if(ServiceAvailabilityMap.get(serviceAvailability).Order__c == 3){
					String CX_GS_Segmentation = acc.CX_GS_Segmentation__c;
					list<Checkmarx_SLA__mdt> cmslaListExpectedFromContract=new list<Checkmarx_SLA__mdt>();
					cmslaListExpectedFromContract = CheckmarxSLAMap.get(serviceAvailability);
				} 
                system.debug('TESTING *****1');
                
                //Sep 2022 Remove ->
                //Date maxContractendDate= null;
                //if (maxcontract!=null) maxContractendDate = maxContract.EndDate;
                //Sep 2022 Remove ->
          		Date maxContractendDate=maxContract.EndDate;
                
                //Sep 2022 Remove ->
                //if(Grace_Period_days.size()>0 && maxcontract!=null)
                //Sep 2022 Remove ->
                  if(Grace_Period_days.size()>0)
                {
                    maxContractendDate = maxContract.EndDate.addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c)));
                }
                

                accountServiceAvailability=serviceAvailability;
                system.debug('TESTING accountServiceAvailability is '+accountServiceAvailability);
                list<Checkmarx_SLA__mdt> cmslaListExpectedFromContract=new list<Checkmarx_SLA__mdt>();
                if(CheckmarxSLAMap.get(accountServiceAvailability)!=null){
                    cmslaListExpectedFromContract=CheckmarxSLAMap.get(serviceAvailability);
                    for(Checkmarx_SLA__mdt sla:cmslaListExpectedFromContract)
                        if(sla.Type__c=='User Managment'){
                            accountNumberOfUser=sla.Number_Of_Users__c;
                            system.debug('TESTING accountNumberOfUser updated');
                            break;
                        }
                    
                }
                /// Rafa --16/4 End
                system.debug('TESTING *****1');
                
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
                            //Sep 2022 Remove ->
                            //if (maxContract!=null) e.StartDate=date.newinstance(maxContract.CreatedDate.year(), maxContract.CreatedDate.month(), maxContract.CreatedDate.day());
                            //Sep 2022 Remove ->
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
                    updateEntitlementList.add(e);
                }
                system.debug('TESTING *****1');
                
                for(Checkmarx_SLA__mdt cl:cmslaListExpected)
                {


                    Entitlement e=new Entitlement();
                    e.AccountId=acc.Id;
                    //Sep 2022 Remove ->
                    //if (maxContract!=null) e.StartDate=date.newinstance(maxContract.CreatedDate.year(), maxContract.CreatedDate.month(), maxContract.CreatedDate.day());
                    //Sep 2022 Remove ->
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
                    insertEntitlementList.add(e);
					
                }
                
                //for test of EntitlementProcessErrorHandling
                if(Test.isRunningTest()){
                    acc.name='';
                }
                
                system.debug('TESTING ******1');
                acc.Maximum_Portal_Users__c=accountNumberOfUser;
                acc.Service_availability__c=accountServiceAvailability;
				acc.Support_Entitlements_Sub_Process__c = 'Contract';
				updateAccountList.add(acc);
            }catch(Exception ex){
                upsertAccountListError.add(new EntitlementProcessErrorHandling.SaveResultClass(acc.Id,ex.getMessage()+'. Stacktrace:'+ex.getStackTraceString()));
            }
        }
		resMap.put('updateEntitlementList', updateEntitlementList);
		resMap.put('insertEntitlementList', insertEntitlementList);
		resMap.put('updateAccountList', updateAccountList);
		resMap.put('upsertAccountListError', upsertAccountListError);
		return resMap; 
	} 
}