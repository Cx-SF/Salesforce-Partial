/*
	Date: 01/04/2023
	Developer Name : Refael Dabush
	Version : 1.0
	Class functionality - upddate and insert Entitlements and Accounts
*/

public class ActiveEntitlementsProcess_Batch implements Database.Batchable<sObject>,Database.Stateful {
	Integer run; // Holds the run number
	String accId; // Holds the account id
	Map<Id, Contract> partnerAccountIdVSContractMap = new Map<Id, Contract>();
	Map<Id, contract> accoutIdAndContractMap = new Map<Id, Contract>();
	set<Id> accoutIdList = new Set<Id>();
	
	// A constructor that receives and transmits run number and AccountId
	public ActiveEntitlementsProcess_Batch (Integer runNumber, String accountId){
		run = (runNumber == null ? 1 : runNumber);
		accId = accountId;
	}

    public Database.QueryLocator start(Database.BatchableContext BC){
		// Get the Data based run number
		String query;
		Map<string, Object> objMAp = ActiveEntitlementsProcess_Handler.getData(run, accId);
		if(run == 1){
			query = String.valueOf(objMap.get('q'));
			System.debug('Rafa - accId: ' + accId);
			List<String> accountsId = (List<String>) objMap.get('accountsId');
		}else if(run == 2){
			System.debug('Rafa - accId: ' + accId);
			query = String.valueOf(objMap.get('q'));
			System.debug('Rafa - query run2: ' + query);
			partnerAccountIdVSContractMap = (Map<Id, Contract>) objMAp.get('partnerAccountIdVSContractMap');
			List<Id> partnerAccIdList = new List<Id>();
			for(Id accId : partnerAccountIdVSContractMap.keySet()) partnerAccIdList.add(accId);
		}else if(run == 3){
			query = String.valueOf(objMap.get('q'));
		}else if(run == 4){
			query = String.valueOf(objMap.get('q'));
			accoutIdList = (Set<Id>) objMAp.get('accoutIdList');
		}else if(run == 5){
			query = String.valueOf(objMap.get('q'));
		}else if(run == 6){
		}

        return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> scope){
		System.debug('scope size: ' +scope.size());
		Map<String, Object> resMap = new Map<String, Object>();
		List<Account> updateAccountList = new List<Account>();
		List<Entitlement> insertEntitlementList = new List<Entitlement>();
		List<Entitlement> updateEntitlementList = new List<Entitlement>();
		List<EntitlementProcessErrorHandling.SaveResultClass> upsertAccountListError = new List<EntitlementProcessErrorHandling.SaveResultClass>();
		List<EntitlementProcessErrorHandling.SaveResultClass> upsertEntitlementListError = new List<EntitlementProcessErrorHandling.SaveResultClass>();
		if(run == 1 || run == 3){
			resMap = ActiveEntitlementsProcess_Handler.getUpdateInsertEntitlemrntRun1(scope, run);
		}else if(run == 2){
			resMap = ActiveEntitlementsProcess_Handler.getUpdateInsertEntitlemrntRun2(scope, run, partnerAccountIdVSContractMap);
		}else if(run == 4){
			resMap = ActiveEntitlementsProcess_Handler.getUpdateInsertEntitlemrntRun4(scope, run);
		}else if(run == 5){
			resMap = ActiveEntitlementsProcess_Handler.getUpdateInsertEntitlemrntRun5And6(scope, run);
		}

		updateEntitlementList= (List<Entitlement>) resMap.get('updateEntitlementList');
		insertEntitlementList = (List<Entitlement>) resMap.get('insertEntitlementList');
		updateAccountList = (List<Account>) resMap.get('updateAccountList');


		System.debug('Rafa - updateAccountList.size(): ' + updateAccountList.size());
		if(updateAccountList.size() > 0){
			system.debug('Rafa - update accounts : ' + JSON.serializePretty(updateAccountList));
			Database.SaveResult[] updateAccountResult = Database.update(scope, false);
			system.debug('Rafa - updateAccountResult: '+updateAccountResult);
			//upsertAccountListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateAccountResult,updateAccountList));
		}

		System.debug('Rafa - updateEntitlementList.size(): ' + updateEntitlementList.size());
		if(updateEntitlementList.size()>0){
			system.debug('Rafa - upsertEntitlementList: '+updateEntitlementList);
			List<Database.SaveResult> updateEntitlementResult= Database.update(updateEntitlementList, false);
			system.debug('Rafa - updateEntitlementResult: '+updateEntitlementResult);
			upsertEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateEntitlementResult,updateEntitlementList));
            
		}
		System.debug('Rafa - insertEntitlementList.size(): ' + insertEntitlementList.size());
		if(insertEntitlementList.size()>0){
			system.debug('Rafa - upsertEntitlementList: '+insertEntitlementList);
			List<Database.SaveResult> insertEntitlementResult= Database.insert(insertEntitlementList, false);
			system.debug('Rafa - insertEntitlementResult: '+insertEntitlementResult);
			upsertEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(insertEntitlementResult,insertEntitlementList));      
		}
	}
	
	public void finish(Database.BatchableContext BC){
		if (run < 1){
			ActiveEntitlementsProcess_Batch nextRun = new ActiveEntitlementsProcess_Batch((run+1), accId);
			Database.executeBatch(nextRun);
		}
	}      
	 
}