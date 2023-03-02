global with sharing class OpportunityLatestExpectedRenewalBatch implements Database.Batchable<sobject> , Schedulable {
    
    /*
	@Author: Yuval Aviram
	@Date: February 14 2019
	@Description: There was a request from the buissness to be able to know the expected renewal ACV.
	Historiclly, prior to salesfroce CPQ and contracts implementation, calcualtions have been done outside of salesforce and updated manually to field - "Expected Renewal ACV" in the opportunity.
	After CPQ and Contract implementation, Expected Renewal ACV is calculated from the subscription object - "Subscription_ACV__c" , upwards to the contract - "Contract_Excepted_Renewal_ACV__c"  and at last to the opportunity - "	
	Expected Renewal ACV formula".
	  
	Idealy we would have created a rollup summary but the relation is a standard lookup and therfore we cant.
	So we had to develop rollup summary functionality.
	Now we have 2 fields showing ACV calculation: older field updated manually - "Expected Renewal ACV" and the new one "Expected Renewal ACV Formula".
	The values are very sensitive finanncialy and we need to minimize errors. so we decided not to update the opportunity directly to avoid exisitng and future validation rules.
	As well as minimize potential impact on CPQ flow.
	Several batches have been implemented to support this, due to ongoing changes:
	1. ContractExceptedRenewalBatch - sums all the subscriptions up to the contract. 
	2. OpportunityExpectedRenewalBatch - sums all the contracts and provides a total per opportunity
	3. current Batch - will check which value is higher. the historic field
	
	
	In future it might be better to rethink the solution and refactor to one Batch.
	
	*/
	
	global OpportunityLatestExpectedRenewalBatch(){  
      
    }
    
    
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	
    	if (test.isRunningTest()) 
    	return Database.getQueryLocator([Select Id,Expected_Renewal_ACV_formula__c,Expected_Renewal_ACV__c
    									From Opportunity
    									limit 200
    									]); 
    									
    	else return Database.getQueryLocator([Select Id,Expected_Renewal_ACV_formula__c,Expected_Renewal_ACV__c
  											  From Opportunity 
  											  where Calculate_in_Expected_Renewal_ACV_Batch__c = true
  											 ]);  
    									
    }
    
  //Execute method for Batch
  global void execute (Database.BatchableContext BC, List<sobject> scope) 
  {
		List<Opportunity> oppList = (List<Opportunity>)scope;  
		for (Opportunity opp_i : oppList) { 
			
			opp_i.Expected_Renewal_ACV__c = opp_i.Expected_Renewal_ACV_formula__c; 
			 
		}	
  		database.update(oppList,false);
  }
   
  //Finish Method for batch
  global void finish(Database.BatchableContext BC)
  {
  }	
  
  //Execute method for Schedule
  global void execute(SchedulableContext scon) {
      
      Database.executeBatch(new OpportunityLatestExpectedRenewalBatch(),200);
   }
}