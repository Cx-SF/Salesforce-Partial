/*
	Date: 01/04/2023
	Developer Name : Refael Dabush
	Version : 1.0
	Class functionality - Holds function for ActiveEntitlementsProcess_Batch
*/
public class ActiveEntitlementsProcess_Handler  {
	public static List<Grace_Period_days__mdt> Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
	public static DateTime dT = system.today();
	public static Map<String,List<Checkmarx_SLA__mdt>> CheckmarxSLAMap = getCheckmarxSLAMap(); //getCheckmarxSLAMap();
	public static string serviceAvailability_Default= [select Label,Order__c from Service_Availability__mdt order by Order__c desc limit 1].label;
	public static string serviceAvailability = serviceAvailability_Default;
	public static Map<String,Service_Availability__mdt> ServiceAvailabilityMap = getServiceAvailabilityMap();
	public static Map<String,Id> SlaProcessMap = getSlaProcessMap();
	public static List<Checkmarx_SLA__mdt> CheckmarxSLAStandardTierList = new List<Checkmarx_SLA__mdt>();
	public static Contract maxContract = new Contract(); /// Holds the selected Contract 
	public static List<id> accuntIdPOC_USERList = new List<Id>(); /// Holds the Account ids that are poc 
	public static List<Entitlement> entitlement4Update = new List<Entitlement>();

	// getData Function sending the data for ActiveEntitlementsProcess_Batch based on the run number 
	public static Map<String, Object> getData (Integer numberOfRun, String accId){
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
            q+=',(SELECT id,Service_Availability__c,CreatedDate,EndDate FROM contracts WHERE EndDate != null And EndDate>= '+currentDateWithPerioddays+'  And Status!=\'Terminated\'  And Status!=\'Expired\' )';
            q+=',(SELECT AccountId,isActive,CreatedDate FROM users ) ';        
			if(accId == null || accId == '') q+='FROM account WHERE id IN: accountsId';
			if(accId != null && accId != '') q+='FROM account WHERE id = ' +'\''+accId+'\'';
			System.debug('qqq: ' + q);
			objMap.put('q', q);
			objMap.put('accountsId', accountsId);
		}else if(numberOfRun == 2){
			System.debug('In number Run 2');
			List<Contract> contractList = [select Partner_Account__r.name, ContractNumber, Account.name, AccountId, Partner_Account__r.Service_Availability__c, Active__c, EndDate, Service_Availability__c, CreatedDate from Contract where Active__c = true and Partner_Account__r.name != null and (Partner_Account__r.Service_Availability__c = null or Partner_Account__r.Service_Availability__c = 'Default') order by Service_Availability__c, EndDate desc];
			Map<Id, Contract> partnerAccountIdVSContractMap = new Map<Id, Contract>();
			for(Contract con : contractList) {if(!partnerAccountIdVSContractMap.containsKey(con.Partner_Account__r.Id)) partnerAccountIdVSContractMap.put(con.Partner_Account__r.Id, con);}

			 String q = 'Select Name, Id, Service_Availability__c,Override_Service_Availability__c,Maximum_Portal_Users__c,Override_maximum_Portal_Users__c,of_Open_Opportunities__c,CX_GS_Segmentation__c,Strategic_Account__c, (Select Id,ContractNumber, Active__c, EndDate, Service_Availability__c, CreatedDate from Contracts where Active__c = true) from Account'; 
			 if(accId == null || accId == '') q += ' Where Id In : partnerAccIdList Order by name';
			 if(accId != null && accId != '') q += ' Where Id = ' + '\''+accId+'\'';
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
			Set<Id> accoutIdList = new set<Id>();
			for(Contact con : [Select AccountId from Contact where CX_POC_user__c = True]){accoutIdList.add(con.AccountId);}
			String q = 'Select Service_Availability__c, (SELECT id,Service_Availability__c,CreatedDate,endDate FROM contracts), Name, Id, CX_ConsolidatedAccount__r.NAME, CX_ConsolidatedAccount__r.Service_Availability__c, Override_Service_Availability__c, Maximum_Portal_Users__c, Override_maximum_Portal_Users__c, of_Open_Opportunities__c, CX_GS_Segmentation__c, Strategic_Account__c ';
			q+= 'from Account where id in:accoutIdList And (Service_Availability__c = Null Or Service_Availability__c = \'Default\')';
			objMap.put('accoutIdList', accoutIdList);
			objMap.put('q', q);
		}else if(numberOfRun == 5){
			String q = 'Select Service_Availability__c, (SELECT id,Service_Availability__c,CreatedDate,endDate FROM contracts), Name, Id, CX_ConsolidatedAccount__r.NAME, CX_ConsolidatedAccount__r.Service_Availability__c, Override_Service_Availability__c, Maximum_Portal_Users__c, Override_maximum_Portal_Users__c, of_Open_Opportunities__c, CX_GS_Segmentation__c, Strategic_Account__c ';
			q = 'From Account where of_Open_Opportunities__c > 0 And (Service_Availability__c = Null Or Service_Availability__c = \'Default\')';
			objMap.put('q', q);
		}else if(numberOfRun == 6){
		}

		return objMap;
	}

	// This function is the prosses for rtun number 1 and 3 
	public static Map<String, Object> getUpdateInsertEntitlemrntRun1(List<Account> accountList, Integer runNum){
	    List<EntitlementProcessErrorHandling.SaveResultClass> upsertAccountListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
		Map<String, Object> resMap = new Map<String, Object>();
		boolean isExist;
        decimal accountNumberOfUser;
		List<Account> updateAccountList = new List<Account>();
        List<Account> accountToChangeStatus = new List<Account>();
		Map<String, Object> mapEntitlement = new Map<String, Object>();
		List<Entitlement> entitlement2Insert = new List<Entitlement>();
		List<Id> accountIdList = new List<Id>();
		for(Account acc : accountList) accountIdList.add(acc.Id);
        for(Contact con : [Select id, AccountId from Contact where AccountId In: accountIdList and CX_POC_user__c = True]){
			accuntIdPOC_USERList.add(con.AccountId);
		}
        for(Account acc:accountList){
			System.debug('Rafa - Account ID: ' + acc.Id);
			serviceAvailability = serviceAvailability_Default;
            try{
				if (acc.of_Open_Opportunities__c > 0 && acc.Service_Availability__c == null) acc.Default_Entitlements_New_Process__c = true;
				maxContract = getMaxContractAndUpdateServiceAvailability(acc.contracts);
				System.debug('Rafa - MaxContract: ' + maxContract);

				if(acc.Override_Service_Availability__c!=null && acc.Override_Service_Availability__c != '') serviceAvailability = acc.Override_Service_Availability__c;
		

				if(ServiceAvailabilityMap.get(serviceAvailability).Order__c == 3){
					CheckmarxSLAStandardTierList = getStandardAvailabilityEntitlements(acc);
				}

				System.debug('Rafa - CheckmarxSLAStandardTierList: ' + CheckmarxSLAStandardTierList);
                                
				accountNumberOfUser = getAccountNumberOfUser();
                           
                list<Checkmarx_SLA__mdt> cmslaListExpected= new list<Checkmarx_SLA__mdt>();
                if(CheckmarxSLAMap.get(serviceAvailability)!=null && CheckmarxSLAStandardTierList.isEmpty()){
                    cmslaListExpected=CheckmarxSLAMap.get(serviceAvailability).clone();
				}else{
					if(!CheckmarxSLAStandardTierList.isEmpty()) {cmslaListExpected = CheckmarxSLAStandardTierList.clone(); CheckmarxSLAStandardTierList.clear();}
				}

				mapEntitlement = createUpdateEntitlementRecords(acc, cmslaListExpected);
				entitlement4Update.addAll((List<Entitlement>) mapEntitlement.get('entitlementList4Update'));
				System.debug('Rafa - mapEntitlement.get(cmSlaList): ' + mapEntitlement.get('cmSlaList'));
				List<Checkmarx_SLA__mdt> cmSlaList = (List<Checkmarx_SLA__mdt>) mapEntitlement.get('cmSlaList');
                entitlement2Insert.addAll(createInsertEntitlement(acc, cmSlaList));
                
                //for test of EntitlementProcessErrorHandling
                if(Test.isRunningTest()){
                    acc.name='';
                }

                acc.Maximum_Portal_Users__c = accountNumberOfUser;
                acc.Service_availability__c = serviceAvailability;
				System.debug('Rafa - runNum: ' + runNum);
				if(runNum == 1) acc.Support_Entitlements_Sub_Process__c = 'Contract';
				if(runNum == 3) acc.Support_Entitlements_Sub_Process__c = 'Consolidated Account';
				updateAccountList.add(acc);
				System.debug('updateAccountList: ' + JSON.serializePretty(updateAccountList));
            }catch(Exception ex){
				System.debug('Error');
				System.debug('Rafa Account error: ' + acc.Id);
            }
        }
		resMap.put('updateEntitlementList',  entitlement4Update);
		resMap.put('insertEntitlementList', entitlement2Insert);
		resMap.put('updateAccountList', updateAccountList);
		return resMap; 
	}

	// This function is the prosses for run 2
	public static Map<String, Object> getUpdateInsertEntitlemrntRun2(List<Account> accountList, Integer runNum, Map<Id, Contract> partnerAccountIdVSContract_Map ){
		Map<String, Object> resMap = new Map<String, Object>();
		List<Id> partnerAccountIdList = new List<Id>();
		List<Account> updateAccountList = new List<Account>();
		decimal accountNumberOfUser;
		Map<String, Object> mapEntitlement = new Map<String, Object>();
		List<Entitlement> entitlement2Insert = new List<Entitlement>();

		/*for(Account acc : accountList) partnerAccountIdList.add(acc.Id);
		for(Contract cont : [Select Partner_Account__r.name, ContractNumber, Account.name, AccountId, Partner_Account__r.Service_Availability__c, Active__c, EndDate, Service_Availability__c, CreatedDate from Contract where Active__c = true and Partner_Account__r.Id in : partnerAccountIdList order by Service_Availability__c, EndDate desc]){
			if(partnerAccountIdVSContract_Map.containsKey(cont.Partner_Account__r.Id)){
				partnerAccountIdVSContract_Map.get(cont.Partner_Account__r.Id).add(cont);
			}else{
				List<Contract> contractList = new List<Contract>();
				contractList.add(cont);
				partnerAccountIdVSContract_Map.put(cont.Partner_Account__r.Id, contractList);
			}
		}*/
		Map<Id, contract> accountIdConMap = new Map<Id, Contract>();
		Map<Id, Account> partnerAccIdAccMap = new Map<Id, Account>();
		for(Contract con : partnerAccountIdVSContract_Map.values()) accountIdConMap.put(con.accountId, con);
		for(Account acc : [Select Name, Id, Service_Availability__c,Override_Service_Availability__c,Maximum_Portal_Users__c,Override_maximum_Portal_Users__c,of_Open_Opportunities__c,CX_GS_Segmentation__c,Strategic_Account__c from Account where id in : accountIdConMap.keySet()]){
			partnerAccIdAccMap.put(accountIdConMap.get(acc.Id).Partner_Account__r.Id, acc);
		}
		
		for(Account acc : accountList){
			serviceAvailability = serviceAvailability_Default;
			try{
				if (acc.of_Open_Opportunities__c > 0 && acc.Service_Availability__c == null) acc.Default_Entitlements_New_Process__c = true; //put in the try
				Contract con = partnerAccountIdVSContract_Map.get(acc.Id);
				List<Contract> contrList = new List<Contract>();
				contrList.add(con);
				maxContract = getMaxContractAndUpdateServiceAvailability(contrList);
				if(acc.Override_Service_Availability__c!=null && acc.Override_Service_Availability__c != '') serviceAvailability = acc.Override_Service_Availability__c;

				if(ServiceAvailabilityMap.get(serviceAvailability).Order__c == 3){
					CheckmarxSLAStandardTierList = getStandardAvailabilityEntitlements(partnerAccIdAccMap.get(acc.Id));
				}
                                
				accountNumberOfUser = getAccountNumberOfUser();
                           
				list<Checkmarx_SLA__mdt> cmslaListExpected= new list<Checkmarx_SLA__mdt>();
				if(CheckmarxSLAMap.get(serviceAvailability)!=null && CheckmarxSLAStandardTierList.isEmpty()){
					cmslaListExpected=CheckmarxSLAMap.get(serviceAvailability).clone();
				}else{
					System.debug('Rafa - CheckmarxSLAMap.get(serviceAvailability) is Null');
					if(!CheckmarxSLAStandardTierList.isEmpty()) {cmslaListExpected = CheckmarxSLAStandardTierList.clone(); CheckmarxSLAStandardTierList.clear();}
				}

				System.debug('Rafa - serviceAvailability: ' + serviceAvailability);
				System.debug('Rafa - cmslaListExpected: ' + JSON.serializePretty(cmslaListExpected));

				mapEntitlement = createUpdateEntitlementRecords(acc, cmslaListExpected);
				List<Checkmarx_SLA__mdt> cmSlaList = (List<Checkmarx_SLA__mdt>) mapEntitlement.get('cmSlaList');
				entitlement2Insert = createInsertEntitlement(acc, cmSlaList);
                
				//for test of EntitlementProcessErrorHandling
				if(Test.isRunningTest()){
					acc.name='';
				}

				acc.Maximum_Portal_Users__c = accountNumberOfUser;
				acc.Service_availability__c = serviceAvailability;
				if(runNum == 2) acc.Support_Entitlements_Sub_Process__c = 'Partner Account';
				updateAccountList.add(acc);
			}catch(Exception ex){
				System.debug('Error');
			}
		}

		resMap.put('updateEntitlementList', (List<Entitlement>) mapEntitlement.get('entitlementList4Update'));
		resMap.put('insertEntitlementList', entitlement2Insert);
		resMap.put('updateAccountList', updateAccountList);

		return resMap;
	}

	// This function is the prosses for run 4
	public static Map<String, Object> getUpdateInsertEntitlemrntRun4(List<Account> accountList, Integer runNum){
		Map<String, Object> resMap = new Map<String, Object>();
		Map<String, Object> mapEntitlement = new Map<String, Object>();
		List<Entitlement> entitlement2Insert = new List<Entitlement>();
		decimal accountNumberOfUser;
		List<Account> updateAccountList = new List<Account>();
		
		for(Account acc : accountList){
			serviceAvailability = serviceAvailability_Default;
			if(acc.Override_Service_Availability__c!=null && acc.Override_Service_Availability__c != '') serviceAvailability = acc.Override_Service_Availability__c;
			try{
				Map<String, String> DefinitionMap = getDefinitionMap();
				String tier = DefinitionMap.get('Account Under POC');
				List<Checkmarx_SLA__mdt> Checkmarx_SLAStandardTierList = new List<Checkmarx_SLA__mdt>();
				for(Checkmarx_SLA__mdt che : CheckmarxSLAMap.get(serviceAvailability)){
					if(che.Service_Availability_Tier__c == tier) Checkmarx_SLAStandardTierList.add(che);
				}

				list<Checkmarx_SLA__mdt> cmslaListExpected= new list<Checkmarx_SLA__mdt>();
				if(!Checkmarx_SLAStandardTierList.isEmpty()) cmslaListExpected = Checkmarx_SLAStandardTierList.clone();

				System.debug('//////////////////////////');
				maxContract = getMaxContractAndUpdateServiceAvailability(acc.contracts);
				System.debug('Rafa - MaxContract: ' + MaxContract);

				mapEntitlement = createUpdateEntitlementRecords(acc, cmslaListExpected);
				List<Checkmarx_SLA__mdt> cmSlaList = (List<Checkmarx_SLA__mdt>) mapEntitlement.get('cmSlaList');
				entitlement2Insert = createInsertEntitlement(acc, cmSlaList);

				accountNumberOfUser = getAccountNumberOfUser();

				acc.Maximum_Portal_Users__c = accountNumberOfUser;
				acc.Service_availability__c = serviceAvailability;
				if(runNum == 4) acc.Support_Entitlements_Sub_Process__c = 'Accounts Under POC';
				updateAccountList.add(acc);
			}catch(Exception ex){
				System.debug('Error');
			}
		}

		resMap.put('updateEntitlementList', (List<Entitlement>) mapEntitlement.get('entitlementList4Update'));
		resMap.put('insertEntitlementList', entitlement2Insert);
		resMap.put('updateAccountList', updateAccountList);

		return resMap;
	}

	// This function is the prosses for run number 5 and 6 
	public static Map<String, Object> getUpdateInsertEntitlemrntRun5And6(List<Account> accountList, Integer runNum){
		Map<String, Object> resMap = new Map<String, Object>();
		Map<String, Object> mapEntitlement = new Map<String, Object>();
		List<Entitlement> entitlement2Insert = new List<Entitlement>();
		List<Account> updateAccountList = new List<Account>();
		decimal accountNumberOfUser;
		for(Account acc : accountList){
			serviceAvailability = 'Default';
			if(acc.Override_Service_Availability__c!=null && acc.Override_Service_Availability__c != '') serviceAvailability = acc.Override_Service_Availability__c;
			try{
				if(serviceAvailability != 'Default'){
					if(ServiceAvailabilityMap.get(serviceAvailability).Order__c == 3){
						CheckmarxSLAStandardTierList = getStandardAvailabilityEntitlements(acc);
					}
				}
			
				List<Checkmarx_SLA__mdt> Checkmarx_SLAStandardTierList = new List<Checkmarx_SLA__mdt>();
				for(Checkmarx_SLA__mdt che : CheckmarxSLAMap.get(serviceAvailability)){
					if(!CheckmarxSLAStandardTierList.isEmpty()) {Checkmarx_SLAStandardTierList = CheckmarxSLAStandardTierList.clone(); CheckmarxSLAStandardTierList.clear();}
					if(serviceAvailability == 'Default') Checkmarx_SLAStandardTierList.add(che);
				}

				list<Checkmarx_SLA__mdt> cmslaListExpected= new list<Checkmarx_SLA__mdt>();
				if(!Checkmarx_SLAStandardTierList.isEmpty()) cmslaListExpected = Checkmarx_SLAStandardTierList.clone();

				System.debug('//////////////////////////');
				maxContract = getMaxContractAndUpdateServiceAvailability(acc.contracts);
				System.debug('Rafa - MaxContract: ' + MaxContract);

				mapEntitlement = createUpdateEntitlementRecords(acc, cmslaListExpected);
				List<Checkmarx_SLA__mdt> cmSlaList = (List<Checkmarx_SLA__mdt>) mapEntitlement.get('cmSlaList');
				entitlement2Insert = createInsertEntitlement(acc, cmSlaList);

				accountNumberOfUser = getAccountNumberOfUser();

				acc.Maximum_Portal_Users__c = accountNumberOfUser;
				acc.Service_availability__c = serviceAvailability;
				if(runNum == 5) acc.Support_Entitlements_Sub_Process__c = 'Open Opportunity';
				updateAccountList.add(acc);
			}catch(Exception ex){
				System.debug('Error');
			}
		}

		resMap.put('updateEntitlementList', (List<Entitlement>) mapEntitlement.get('entitlementList4Update'));
		resMap.put('insertEntitlementList', entitlement2Insert);
		resMap.put('updateAccountList', updateAccountList);

		return resMap;
	}

	// Return map of ServiceAvailability key = Label, value = serviceAvalability row
	public static Map<String, Service_Availability__mdt> getServiceAvailabilityMap (){
		Map<String, Service_Availability__mdt> ServiceAvailability_Map = new Map<String, Service_Availability__mdt>(); 
		for(Service_Availability__mdt sam:[select Label,Order__c from Service_Availability__mdt]){
            if (!(ServiceAvailability_Map.containsKey(sam.Label))) {
                ServiceAvailability_Map.put(sam.Label, sam);
            }
        }
		return ServiceAvailability_Map;
	}

	// Return map of SlaProcess key = name, value = Id
	public static Map<String, Id> getSlaProcessMap (){
		List<SlaProcess> SlaProcessList=[SELECT Name, IsActive, VersionMaster, VersionNumber,
                                         Id, IsVersionDefault, VersionNotes 
                                         FROM SlaProcess where IsVersionDefault=true];
        Map<String,Id> SlaProcess_Map = new Map<String,Id>();
        for(SlaProcess sla:SlaProcessList){
            SlaProcess_Map.put(sla.Name,sla.Id);
        }

		return SlaProcess_Map;
	}

	//Return the Contract with the highest serviceAvailability and update the serviceAvailability var
	public static Contract getMaxContractAndUpdateServiceAvailability(List<Contract> conList){
		Contract max_Contract = conList[0];
		for(Contract con : conList){
            string contractServiceAvailability = con.Service_Availability__c; 
			System.debug('ServiceAvailabilityMap.get(serviceAvailability)).Order__c: ' + ServiceAvailabilityMap.get(serviceAvailability).Order__c);
			System.debug('ServiceAvailabilityMap.get(contractServiceAvailability)).Order__c: ' + ServiceAvailabilityMap.get(contractServiceAvailability).Order__c);
            if(ServiceAvailabilityMap.get(serviceAvailability).Order__c > ServiceAvailabilityMap.get(contractServiceAvailability).Order__c){
                serviceAvailability=contractServiceAvailability; 
                max_Contract=con;
            }        
        }
		return max_Contract;
	}

	// Return map of Checkmarx_SLA__mdt key = Service_Availability__c, value = Checkmarx_SLA__mdt row
	public static Map<String, List<Checkmarx_SLA__mdt>> getCheckmarxSLAMap(){
		Map<String, List<Checkmarx_SLA__mdt>> Checkmarx_SLAMap = new Map<String, List<Checkmarx_SLA__mdt>>();
		List<Checkmarx_SLA__mdt> checkmarxSLAList=[SELECT Id, Label, QualifiedApiName, Case_Record_Type__c, Priority__c, Service_Availability__c,Type__c, Service_Availability_Tier__c,
                                                   Number_Of_Users__c,Entitlement_Process_Name__c FROM Checkmarx_SLA__mdt where Type__c!='' and Type__c!=null];
        
		for(Checkmarx_SLA__mdt cmsla : checkmarxSLAList){
			if(Checkmarx_SLAMap.containsKey(cmsla.Service_Availability__c)){
					Checkmarx_SLAMap.get(cmsla.Service_Availability__c).add(cmsla);
			}else{
				list<Checkmarx_SLA__mdt> cmslaList=new list<Checkmarx_SLA__mdt>();
				cmslaList.add(cmsla);
				Checkmarx_SLAMap.put(cmsla.Service_Availability__c,cmslaList);
			}
		}
		return Checkmarx_SLAMap;
	}

	// Reurn number of users
	public static Decimal getAccountNumberOfUser() {
        //system.debug('Rafa - serviceAvailability is ' + serviceAvailability);
		Decimal numberOFUser = null;
        list<Checkmarx_SLA__mdt> cmslaListExpectedFromContract=new list<Checkmarx_SLA__mdt>();
        if(CheckmarxSLAMap.get(serviceAvailability)!= null && CheckmarxSLAStandardTierList.isEmpty()) cmslaListExpectedFromContract=CheckmarxSLAMap.get(serviceAvailability);
		if(!CheckmarxSLAStandardTierList.isEmpty()) cmslaListExpectedFromContract = cmslaListExpectedFromContract.clone();
        for(Checkmarx_SLA__mdt sla:cmslaListExpectedFromContract){
            if(sla.Type__c=='User Managment'){
                numberOFUser = sla.Number_Of_Users__c;
                system.debug('Rafa accountNumberOfUser updated');
                break;
            }
		}
		return numberOFUser;         
	}

	// Return the list of Checkmarx_SLA__mdt According to the tier
	public static List<Checkmarx_SLA__mdt> getStandardAvailabilityEntitlements(Account acc){
		List<Checkmarx_SLA__mdt> Checkmarx_SLAStandardTierList = new List<Checkmarx_SLA__mdt>();
		Map<String, String> GS_Map = getGsSegmentationMap();
		Map<String, String> DefinitionMap = getDefinitionMap();
		String tier = '';
		String CX_GS_Segmentation = ''; 
		if(acc.CX_GS_Segmentation__c != null) CX_GS_Segmentation = acc.CX_GS_Segmentation__c;
		System.debug('Rafa - CX_GS_Segmentation: ' + CX_GS_Segmentation);
		String accountDefinition = '';
		System.debug('Rafa - acc.Strategic_Account__c: ' + acc.Strategic_Account__c);
		if(acc.Strategic_Account__c) accountDefinition = 'Enterprise Account';
		System.debug('Rafa - accuntIdPOC_USERList.contains(acc.Id): ' + accuntIdPOC_USERList.contains(acc.Id));
		if(accuntIdPOC_USERList.contains(acc.Id)) accountDefinition = 'Account Under POC';
		System.debug('Rafa - GS_Map.containsKey(CX_GS_Segmentation): ' + GS_Map.containsKey(CX_GS_Segmentation));
		if(GS_Map.containsKey(CX_GS_Segmentation)) tier = GS_Map.get(CX_GS_Segmentation);
		System.debug('Rafa - accountDefinition: ' + accountDefinition);
		System.debug('Rafa - tier befor: ' + tier);
		if(accountDefinition != '' && tier == '') tier = DefinitionMap.get(accountDefinition);
		System.debug('Rafa - tier: ' + tier);
		if(tier != ''){
			for(Checkmarx_SLA__mdt che : CheckmarxSLAMap.get(serviceAvailability)){
				if(che.Service_Availability_Tier__c == tier) Checkmarx_SLAStandardTierList.add(che);
			}
		}else{
			for(Checkmarx_SLA__mdt che : CheckmarxSLAMap.get('Default')){Checkmarx_SLAStandardTierList.add(che);}
		}
		return Checkmarx_SLAStandardTierList;
	}

	// Return Service_availability_Account_Segment__mdt map key GS_Segmentation__c, value Service_Availability_Tier__c
	public static Map<String, String> getGsSegmentationMap(){
		Map<String, String> gs_SegmentationMap = new Map<String, String>();
		for(Service_availability_Account_Segment__mdt SAAS : [SELECT Id, GS_Segmentation__c, Service_Availability_Tier__c from  Service_availability_Account_Segment__mdt]){
			gs_SegmentationMap.put(SAAS.GS_Segmentation__c, SAAS.Service_Availability_Tier__c);
		}
		return gs_SegmentationMap;
	}

	public static Map<String, String> getDefinitionMap(){
		Map<String, String> DefinitionMap = new Map<String, String>();
		for(Service_availability_Account_Definition__mdt accountDefinition : [select id, Account_Definition__c, Service_Availability_Tier__c from Service_availability_Account_Definition__mdt]){
			DefinitionMap.put(accountDefinition.Account_Definition__c, accountDefinition.Service_Availability_Tier__c);
		}
		return DefinitionMap;
	}

	// Return Map with Entitlement for update and Checkmarx_SLA__mdt (if left) list for create new Entitlement
	public static Map<String, Object> createUpdateEntitlementRecords(Account acc, List<Checkmarx_SLA__mdt> cmslaListExpected){
		System.debug('Rafa - account ID in createUpdateEntitlementRecords fun: ' + acc.Id);
		Map<String, Object> entitlementMap = new Map<String, Object>();
		List<Entitlement> entitlementList4Update = new List<Entitlement>();
		Date maxContractendDate=maxContract.EndDate;
        if(Grace_Period_days.size()>0) maxContractendDate = maxContract.EndDate.addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c)));
		for(Entitlement e:acc.Entitlements){
            Boolean isExist = false;
            integer i=0;
            while(i<cmslaListExpected.size()){
                Checkmarx_SLA__mdt cl=cmslaListExpected[i];
                if(e.Type==cl.Type__c && e.Case_Priority__c==cl.Priority__c && e.Service_Availability__c==cl.Service_Availability__c){
                    e.StartDate=date.newinstance(maxContract.CreatedDate.year(), maxContract.CreatedDate.month(), maxContract.CreatedDate.day());
                    e.EndDate=maxContractendDate;
                    e.Case_Priority__c=cl.Priority__c;
                    e.Case_Record_Type__c=cl.Case_Record_Type__c;
                    e.Service_Availability__c=cl.Service_Availability__c;
                            
                    if(e.Type != 'User Managment'){
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
                }else{
                    i++;
				}
            }
            if(!isExist){
                //inactive old entitlement
                //when startdate in later than yesterday (The end date must be equal to or later than the start date)
                if(e.StartDate>system.today().addDays(-1))
                    e.StartDate=system.today().addDays(-1); 
                    e.EndDate=system.today().addDays(-1);
            }
            entitlementList4Update.add(e);
        }
		System.debug('Rafa - entitlementList4Update in createUpdateEntitlementRecords: ' + entitlementList4Update);
		entitlementMap.put('entitlementList4Update', entitlementList4Update);
		entitlementMap.put('cmSlaList', cmslaListExpected);
		return entitlementMap;
	}

	// 
	public static List<Entitlement> createInsertEntitlement(Account acc, List<Checkmarx_SLA__mdt> cmslaListExpected){
		List<Entitlement> List4insertEntitlement = new List<Entitlement>();
		Date maxContractendDate=maxContract.EndDate;
        if(Grace_Period_days.size()>0) maxContractendDate = maxContract.EndDate.addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c)));
		for(Checkmarx_SLA__mdt cl:cmslaListExpected){
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
            List4insertEntitlement.add(e);			
        }
		return List4insertEntitlement;
	}
}