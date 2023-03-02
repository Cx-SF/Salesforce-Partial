/*
Date: 08/02/2023
Developer Name: Refael Dabush
Version : 1.0
Class functionality: Runs the AutoSolveProcessBatch with specific ID
*/

public class AutoSolvedProcess  {
	// Get the case id from the user and start the AutoSolvedProcessBatch
	@AuraEnabled
	public static Map<String, Object> startProcess(Id caseId){
		System.debug('caseId: ' + caseId);
		Map<String, Object> resOut = new Map<String, Object>();
		Set<Id> idList = new Set<Id>();
		idList.add(caseId);
		resOut.put('Succses', true);
		System.debug('caseId: ' + caseId);
		AutoSolvedProcessBatch autoAolvProcess = new AutoSolvedProcessBatch(idList);
		Id batchProcessId = Database.executeBatch(autoAolvProcess);

		System.debug('Id batchProcessId: ' + batchProcessId);
		resOut.put('batchId', batchProcessId);



		return resOut;
	}

	// Get the batchProcessId and send the status to the user 
	@AuraEnabled
	public static Map<String, Object> getBatchInfo(Id batchProcessId){
		System.debug('batchProcessId from get: ' + batchProcessId);
		Map<String, Object> resOut = new Map<String, Object>();
		resOut.put('Succses', true);
		AsyncApexJob autoSolvedBatch = [Select Id, TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, CreatedDate, CreatedById, CompletedDate, ApexClassId, ApexClass.Name from AsyncApexJob where id =: batchProcessId];
		System.debug('autoSolvedBatch: ' + autoSolvedBatch);
		resOut.put('Status', autoSolvedBatch.Status);
		resOut.put('NumberOfErrors', autoSolvedBatch.NumberOfErrors);
		return resOut;
	}

}