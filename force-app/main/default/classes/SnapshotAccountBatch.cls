/*
@Author: Yuval Aviram
@Date: December 17 2018
@Description: In order to better check trends and perform Analitics we want to take snapshots of Account information.
A new object was created - Snapshot_Account__c.
To Allow easy control and maintainance of the reqiired fields for the snapshot we keep the fields managed in a dedicated fieldset - snapshot account . 
Need to make sure the API name is the same between the Account object and the new snapshot object.

*/
global with sharing class SnapshotAccountBatch implements Database.Batchable<sobject> , Schedulable{
    
    global SnapshotAccountBatch(){
      
    } 
    
    
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	
    	String query = 'SELECT Id,CurrencyIsoCode,of_Opportunities__c';	
    								
    	
    	for ( Schema.FieldSetMember fsm : SObjectType.Account.FieldSets.Snapshot_Account.getFields()) { 
 
 			query += ',' + fsm.getFieldPath();
 
 		}
    	
    	query += ' from Account where of_Opportunities__c > 0';
    	
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
  	
  	list<Account> AccountList = (list<Account>) scope; 
  	list<Snapshot_Account__c> snapshotAccountList = new list<Snapshot_Account__c>();
  	
  	try
  	{
  		
	  	for (Account acc : AccountList) { 
	  		
	  		Snapshot_Account__c snap = new Snapshot_Account__c();
	  		
	  		for ( Schema.FieldSetMember fsm : SObjectType.Account.FieldSets.Snapshot_Account.getFields()) {
 
 				
 				string apiName = fsm.getFieldPath().contains('__c') ? fsm.getFieldPath() : fsm.getFieldPath() + '__c';
 				
 				snap.put(apiName,acc.get(fsm.getFieldPath()));
 				snap.Account__c = acc.Id;
 				snap.CurrencyIsoCode = acc.CurrencyIsoCode;
 				
 			}
 			
 			snapshotAccountList.add(snap);
	  		
	  	}
	  	
	  	insert snapshotAccountList;
  	}
 	catch(Exception ex)
	{
			
			system.debug('SnapshotAccountBatch @@@@ Exception ' + ex);		
			throw(ex);
	}  	 
  }
   
  //Finish Method for batch
  global void finish(Database.BatchableContext BC)
  {
  }	
  
  //Execute method for Schedule
  global void execute(SchedulableContext scon) {
      
      Database.executeBatch(new SnapshotAccountBatch(),200);
   }
}