global with sharing class OpportunityExpectedRenewalBatch implements Database.Batchable<sobject> , Schedulable{
    
    /*
	@Author: Yuval Aviram
	@Date: January 14 2019
	@Description: There was a request from the buissness to be able to know the expected renewal ACV.
	Expected Renewal ACV is calculated from the subscription object - "Subscription_ACV__c" , upwards to the contract - "Contract_Excepted_Renewal_ACV__c"  and at last to the opportunity - "	
	Expected Renewal ACV formula".
	Idealy we would have created a rollup summary but the relation is a standard lookup and therfore we cant.
	So we had to develop rollup summary functionality.
	The values are very sensitive finanncialy and we need to minimize errors. so we decided not to update the opportunity directly to avoid exisitng and future validation rules.
	Instead we update a field in the contract - Total_Expected_Renewal_ACV__c. This field will sum up all the renewable contracts under an opp.
	The opportunity already has a lookup field to the master contract. so all is left is to have a new formula to the contract new field. 
	We decided to develop an async process so we wont interfere with the sensitive CPQ flow.
	*/
    global OpportunityExpectedRenewalBatch(){ 
      
    }
    
    
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	
    	if (test.isRunningTest()) 
    	return Database.getQueryLocator([Select o.Id, SBQQ__RenewedContract__c,
    										(Select Id, CurrencyIsoCode, Status, Contract_Excepted_Renewal_ACV__c, Total_Expected_Renewal_ACV__c, CX_OLD_Total_Expected_Renewal_ACV__c 
    										From SBQQ__RenewedContracts__r where Contract_Excepted_Renewal_ACV__c != null) 
    									From Opportunity o where IsWon = true OR IsClosed = false limit 200]);
    									
    	else return Database.getQueryLocator([Select o.Id, 
    										(Select Id, CurrencyIsoCode, Status, Contract_Excepted_Renewal_ACV__c, Total_Expected_Renewal_ACV__c, CX_OLD_Total_Expected_Renewal_ACV__c 
    										From SBQQ__RenewedContracts__r where Contract_Excepted_Renewal_ACV__c != null) 
    									From Opportunity o where IsWon = true OR IsClosed = false]); 
    									
    }
    
  //Execute method for Batch
  global void execute (Database.BatchableContext BC, List<sobject> scope) 
  {
  	try
  	{
	  	map<string,decimal> renewalOppToTotalExpectedAcvMap = new map<string,decimal>(); 
	  	list<Contract> ContractListToUpdate = new list<Contract>();
		List<Opportunity> renewalOppList = (List<Opportunity>)scope;  
		
		//calculate total ACV: sum of Contract_Excepted_Renewal_ACV__c in all related contracts.
		for (Opportunity opp_i : renewalOppList) { 
			
			if (opp_i.SBQQ__RenewedContracts__r.size() > 0) {
				
				Decimal ACV = 0; 
				for (contract cont_i : opp_i.SBQQ__RenewedContracts__r) {
					
					ACV = cont_i.status != 'Terminated' ? ACV + cont_i.Contract_Excepted_Renewal_ACV__c : ACV;
				}
				
				renewalOppToTotalExpectedAcvMap.put(opp_i.Id,ACV); 
			} 
			 
		}
  		
  		//update contract toatl Acv in each contract under opp
  		for (Opportunity opp_i : renewalOppList) { 
			
			if (renewalOppToTotalExpectedAcvMap.containsKey(opp_i.Id)) {
				
				for (contract cont_i : opp_i.SBQQ__RenewedContracts__r) {
					
					if (cont_i.CX_OLD_Total_Expected_Renewal_ACV__c != renewalOppToTotalExpectedAcvMap.get(opp_i.Id)) {
						
						cont_i.CX_OLD_Total_Expected_Renewal_ACV__c = renewalOppToTotalExpectedAcvMap.get(opp_i.Id);
						ContractListToUpdate.add(cont_i);
					}
					
				}
				
			} 
			 
		}
  		
  		//update ContractListToUpdate;
  		database.update(ContractListToUpdate,false);
  	}
 	catch(Exception ex)
	{
			system.debug('OpportunityExpectedRenewalBatch @@@@ Exception ' + ex);		
			//throw(ex);
	}  	 
  }
   
  //Finish Method for batch
  global void finish(Database.BatchableContext BC)
  {
  }	
  
  //Execute method for Schedule
  global void execute(SchedulableContext scon) {
      
      Database.executeBatch(new OpportunityExpectedRenewalBatch(),200);
   }
}