/*
@Author: Yuval Aviram
@Date: October 22 2018
@Description: There was a request from the buissness to be able to know the expected renewal ACV.
Expected Renewal ACV is calculated from the subscription object - "Subscription_ACV__c" , upwards to the contract - "Contract_Excepted_Renewal_ACV__c"  and at last to the opportunity - "Expected_Renewal_ACV__c".
Idealy we would have created a rollup summary but the relation is a standard lookup and therfore we cant.
So we had to develop rollup summary functionality. We decided to develop an async process so we wont interfere with the sensitive CPQ flow.
*/

global with sharing class ContractExceptedRenewalBatch implements Database.Batchable<sobject> , Schedulable{
    
     
    global ContractExceptedRenewalBatch(){
      
    }
    
    
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	
    	if (test.isRunningTest()) 
    	return Database.getQueryLocator([Select SBQQ__Contract__r.SBQQ__RenewalOpportunity__c,SBQQ__Contract__c ,Subscription_ACV__c,
    									SBQQ__Contract__r.Contract_Excepted_Renewal_ACV__c, SBQQ__Contract__r.CX_OLD_Contract_Expected_Renewal_ACV__c
    									From SBQQ__Subscription__c 
    									where SBQQ__Contract__r.SBQQ__RenewalOpportunity__c != null
    									and NeedToBeCalculatedInBatch__c = true limit 50
    									]);
    									
    	else return Database.getQueryLocator([Select SBQQ__Contract__r.SBQQ__RenewalOpportunity__c,SBQQ__Contract__c ,Subscription_ACV__c,
    									SBQQ__Contract__r.Contract_Excepted_Renewal_ACV__c, SBQQ__Contract__r.CX_OLD_Contract_Expected_Renewal_ACV__c
    									From SBQQ__Subscription__c 
    									where SBQQ__Contract__r.SBQQ__RenewalOpportunity__c != null
    									and NeedToBeCalculatedInBatch__c = true
    									]);
    									
    }
    
  //Execute method for Batch
  global void execute (Database.BatchableContext BC, List<sobject> scope) 
  {
  	try
  	{
	  	//map<string,decimal> renewalOppToTotalExpectedAcvMap = new map<string,decimal>(); 
	  	list<SBQQ__Subscription__c> SubscriptionList = (list<SBQQ__Subscription__c>) scope;
	  	list<SBQQ__Subscription__c> SubscriptionListToUpdate = new list<SBQQ__Subscription__c>();
	  	list<Contract> ContractList = new list<Contract>();
	  	map<Id,Contract> ContractToUpdateMap = new map<Id,Contract>();
	    set<string> contractIds = new set<string>();
		
		
		for (SBQQ__Subscription__c sub_i : SubscriptionList) {  
			 
			contractIds.add(sub_i.SBQQ__Contract__c);
		}
  		
  		ContractList.addAll([Select Id, status, CX_OLD_Contract_Expected_Renewal_ACV__c, Contract_Excepted_Renewal_ACV__c, SBQQ__RenewalOpportunity__c,Total_Expected_Renewal_ACV__c,
  								(Select Id, Subscription_ACV__c From SBQQ__Subscriptions__r ) 
  							From contract where SBQQ__RenewalOpportunity__c != null and id in : contractIds ]);
  				   
  		
  		//calculating contract Expected ACV 
  		for (contract con : ContractList) {
  			
  			Decimal ACV = 0;
  			for (SBQQ__Subscription__c sub_i : con.SBQQ__Subscriptions__r) {
  				
  				ACV = Acv + sub_i.Subscription_ACV__c;
  				sub_i.NeedToBeCalculatedInBatch__c = false;
  				SubscriptionListToUpdate.add(sub_i);
  				
  			}
  			if (con.CX_OLD_Contract_Expected_Renewal_ACV__c != ACV ) {
  				
  				con.CX_OLD_Contract_Expected_Renewal_ACV__c = ACV; 
  				ContractToUpdateMap.put(con.Id,con);
  			}
  			
  			/*Decimal valueToSum = con.status == 'Terminated' ? 0 : ACV; 
  			if (renewalOppToTotalExpectedAcvMap.containskey(con.SBQQ__RenewalOpportunity__c)) {
  				
  				renewalOppToTotalExpectedAcvMap.put(con.SBQQ__RenewalOpportunity__c,renewalOppToTotalExpectedAcvMap.get(con.SBQQ__RenewalOpportunity__c) + valueToSum);  
  			}
  			else {
  				renewalOppToTotalExpectedAcvMap.put(con.SBQQ__RenewalOpportunity__c, valueToSum); 
  			}*/
  		}
  		
  		/*//total expected renewal ACV
		for (contract con : ContractList) {
			
			if (con.Total_Expected_Renewal_ACV__c != renewalOppToTotalExpectedAcvMap.get(con.SBQQ__RenewalOpportunity__c)) {
				
                if(ContractToUpdateMap.containsKey(con.Id)) {
                    ContractToUpdateMap.get(con.id).Total_Expected_Renewal_ACV__c = renewalOppToTotalExpectedAcvMap.get(con.SBQQ__RenewalOpportunity__c);
                }
                else {
                    
                    con.Total_Expected_Renewal_ACV__c = renewalOppToTotalExpectedAcvMap.get(con.SBQQ__RenewalOpportunity__c);
                    ContractToUpdateMap.put(con.Id,con); 
                }
                
			} 
			
		}*/
  		update ContractToUpdateMap.values();
  		update SubscriptionListToUpdate;
  	}
 	catch(Exception ex)
	{
			system.debug('ContractExceptedRenewalBatch @@@@ Exception ' + ex);		
			throw(ex);
	}  	 
  }
   
  //Finish Method for batch
  global void finish(Database.BatchableContext BC)
  {
  }	
  
  //Execute method for Schedule
  global void execute(SchedulableContext scon) {
      
      Database.executeBatch(new ContractExceptedRenewalBatch(),200);
   }
}