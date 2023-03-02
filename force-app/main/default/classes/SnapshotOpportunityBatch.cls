/*
@Author: Yuval Aviram
@Date: December 17 2018
@Description: In order to better check trends and perform Analitics we want to take snapshots of Opportunity information.
A new object was created - snapshot_opportunity__c.
To Allow easy control and maintainance of the reqiired fields for the snapshot we keep the fields managed in a dedicated fieldset - snapshot opportunity . 
Need to make sure the API name is the same between the Opportunity object and the new snapshot object.

*/

global with sharing class SnapshotOpportunityBatch  implements Database.Batchable<sobject> , Schedulable{
    
    global SnapshotOpportunityBatch(){
      
    }
    
    
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	
    	
    	String query = 'SELECT Id,name,Account.Name,AccountID,CurrencyIsoCode,Owner.Name';	
    								
    	
    	for ( Schema.FieldSetMember fsm : SObjectType.Opportunity.FieldSets.snapshot_opportunity.getFields()) {
 
 			query += ',' + fsm.getFieldPath();
 
 		}
    	
    	query += ' from Opportunity where not(IsWon = false and CloseDate < 2018-01-01)';
    	
    	if (test.isRunningTest()) {
    		
    		query += ' limit 20';
    		return Database.getQueryLocator(query);
    	}
    	
    	//query += ' limit 200'; //only for sandbox usage
    	return Database.getQueryLocator(query);
    									
    }
    
  //Execute method for Batch
  global void execute (Database.BatchableContext BC, List<sobject> scope) 
  {
  	
  	list<Opportunity> OpportunityList = (list<Opportunity>) scope;
  	list<snapshot_opportunity__c> snapshotOpportunityList = new list<snapshot_opportunity__c>();
  	
  	try
  	{
  		
	  	for (Opportunity opp : OpportunityList) { 
	  		
	  		snapshot_opportunity__c snap = new snapshot_opportunity__c();
	  		
	  		for ( Schema.FieldSetMember fsm : SObjectType.Opportunity.FieldSets.snapshot_opportunity.getFields()) {
 
 				//query += ',' + fsm.getFieldPath();
 				
 				string apiName = fsm.getFieldPath().contains('__c') ? fsm.getFieldPath() : fsm.getFieldPath() + '__c';
 				
 				snap.put(apiName,opp.get(fsm.getFieldPath()));
 				snap.Opportunity__c = opp.Id;
 				snap.Account_Id__c = opp.AccountID;
 				snap.Account_Name__c = opp.Account.Name;
 				snap.CurrencyIsoCode = opp.CurrencyIsoCode;
 				snap.Owner_Name__c = opp.Owner.Name;
 				
 			}
 			
 			snapshotOpportunityList.add(snap);
	  		
	  	}
	  	insert snapshotOpportunityList;
  	}
 	catch(Exception ex)
	{
			
			system.debug('SnapshotOpportunityBatch @@@@ Exception ' + ex);		
			throw(ex);
	}  	 
  }
   
  //Finish Method for batch
  global void finish(Database.BatchableContext BC)
  {
  }	
  
  //Execute method for Schedule
  global void execute(SchedulableContext scon) {
      
      Database.executeBatch(new SnapshotOpportunityBatch(),200);
   }
}