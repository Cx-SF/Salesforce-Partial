/*
@Author: Yuval Aviram
@Date: December 17 2018
@Description: In order to better check trends and perform Analitics we want to take snapshots of Contract information.
A new object was created - Snapshot_Contract__c.
To Allow easy control and maintainance of the reqiired fields for the snapshot we keep the fields managed in a dedicated fieldset - snapshot contract . 
Need to make sure the API name is the same between the Contract object and the new snapshot object.

*/
global with sharing class SnapshotContractBatch implements Database.Batchable<sobject> , Schedulable {
    
    global SnapshotContractBatch(){
      
    } 
    
    
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	
    	String query = 'SELECT Id,CurrencyIsoCode,SBQQ__Opportunity__c';	
    								
    	
    	for ( Schema.FieldSetMember fsm : SObjectType.Contract.FieldSets.Snapshot_Contract.getFields()) { 
 
 			query += ',' + fsm.getFieldPath();
 
 		}
    	
    	query += ' from Contract';
    	
    	if (test.isRunningTest()) {
    		
    		query += ' limit 20';
    		return Database.getQueryLocator(query);
    	}
    	
    	//query += ' limit 200'; // only for sandbox usage
    	return Database.getQueryLocator(query);
    									
    }
    
  //Execute method for Batch
  global void execute (Database.BatchableContext BC, List<sobject> scope) 
  {
  	
  	list<contract> contractList = (list<contract>) scope; 
  	list<Snapshot_contract__c> snapshotContractList = new list<Snapshot_contract__c>();
  	
  	try
  	{
  		
	  	for (contract contr : contractList) {  
	  		
	  		Snapshot_contract__c snap = new Snapshot_contract__c();
	  		
	  		for ( Schema.FieldSetMember fsm : SObjectType.contract.FieldSets.Snapshot_Contract.getFields()) {
 
 				
 				string apiName = fsm.getFieldPath().contains('__c') ? fsm.getFieldPath() : fsm.getFieldPath() + '__c';
 				
 				snap.put(apiName,contr.get(fsm.getFieldPath()));
 				snap.Contract__c = contr.Id;
 				snap.Opportunity_ID__c = contr.SBQQ__Opportunity__c;  
 				snap.CurrencyIsoCode = contr.CurrencyIsoCode;
 				
 			}
 			
 			snapshotContractList.add(snap);
	  		
	  	}
	  	
	  	insert snapshotContractList;
  	}
 	catch(Exception ex)
	{
			
			system.debug('SnapshotContractBatch @@@@ Exception ' + ex);		
			throw(ex);
	}  	 
  }
   
  //Finish Method for batch
  global void finish(Database.BatchableContext BC)
  {
  }	
  
  //Execute method for Schedule
  global void execute(SchedulableContext scon) {
      
      Database.executeBatch(new SnapshotContractBatch(),200);
   }
}