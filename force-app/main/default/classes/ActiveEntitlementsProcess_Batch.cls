/*
	Date: 01/04/2023
	Developer Name : Refael Dabush
	Version : 1.0
	Class functionality - upddate and insert Entitlements and Accounts
*/

public class ActiveEntitlementsProcess_Batch implements Database.Batchable<sObject>,Database.Stateful {
	Integer run; // Hold the run number
	Map<Id, Contract> partnerAccountIdVSContractMap = new Map<Id, Contract>();

	
	// A constructor that receives and transmits run number 
	public ActiveEntitlementsProcess_Batch (Integer runNumber){
		run = (runNumber == null ? 1 : runNumber);
	}

    public Database.QueryLocator start(Database.BatchableContext BC){
		// Get the Data based run number
		String query;
		Map<string, Object> objMAp = ActiveEntitlementsProcess_Handler.getData(run);
		if(run == 1){
			 query = String.valueOf(objMap.get('q'));
			List<String> accountsId = (List<String>) objMap.get('accountsId');
		}else if(run == 2){
			query = String.valueOf(objMap.get('q'));
			partnerAccountIdVSContractMap = (Map<Id, Contract>) objMAp.get('partnerAccountIdVSContractMap');
			List<Id> partnerAccIdList = new List<Id>();
			for(Id accId : partnerAccountIdVSContractMap.keySet()) partnerAccIdList.add(accId);
		}else if(run == 3){
			query = String.valueOf(objMap.get('q'));
		}else if(run == 4){
		}else if(run == 5){
		}else if(run == 6){
		}

        return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> scope){
		System.debug('scope: ' + JSON.serializePretty(scope));
		List<Account> updateAccountList = new List<Account>();
		List<Entitlement> insertEntitlementList = new List<Entitlement>();
		List<Entitlement> updateEntitlementList = new List<Entitlement>();
		List<EntitlementProcessErrorHandling.SaveResultClass> upsertAccountListError = new List<EntitlementProcessErrorHandling.SaveResultClass>();
		List<EntitlementProcessErrorHandling.SaveResultClass> upsertEntitlementListError = new List<EntitlementProcessErrorHandling.SaveResultClass>();
		if(run == 1){
			Map<String, Object> resMap = ActiveEntitlementsProcess_Handler.getUpdateInsertEntitlemrnt(scope);
			updateEntitlementList= (List<Entitlement>) resMap.get('updateEntitlementList');
			insertEntitlementList = (List<Entitlement>) resMap.get('insertEntitlementList');
			updateAccountList = (List<Account>) resMap.get('updateAccountList');
			upsertAccountListError = (List<EntitlementProcessErrorHandling.SaveResultClass>) resMap.get('upsertAccountListError');

		    if(updateAccountList.size() > 0){
				system.debug('Rafa - update accounts : '+updateAccountList);
				Database.SaveResult[] updateAccountResult = Database.update(scope, false);
				system.debug('Rafa - updateAccountResult: '+updateAccountResult);
				upsertAccountListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateAccountResult,updateAccountList));
			}

			if(updateEntitlementList.size()>0){
				system.debug('Rafa - upsertEntitlementList: '+updateEntitlementList);
				List<Database.SaveResult> updateEntitlementResult= Database.update(updateEntitlementList, false);
				system.debug('Rafa - updateEntitlementResult: '+updateEntitlementResult);
				upsertEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateEntitlementResult,updateEntitlementList));
            
			}

			if(insertEntitlementList.size()>0){
				system.debug('Rafa - upsertEntitlementList: '+insertEntitlementList);
				List<Database.SaveResult> insertEntitlementResult= Database.insert(insertEntitlementList, false);
				system.debug('Rafa - insertEntitlementResult: '+insertEntitlementResult);
				upsertEntitlementListError.addAll(EntitlementProcessErrorHandling.setErrorList(insertEntitlementResult,insertEntitlementList));      
			}
		}
	}
	
	public void finish(Database.BatchableContext BC){
		if (run < 1){
			ActiveEntitlementsProcess_Batch nextRun = new ActiveEntitlementsProcess_Batch((run+1));
			Database.executeBatch(nextRun);
		}
	}      
	 
}