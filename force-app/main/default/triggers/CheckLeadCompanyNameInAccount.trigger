/******************************************************************************* 
Name              : CheckLeadCompanyNameInAccount
Description       : Searchs if there is an Account with the Leads Company for Name and assigns it to the Lead
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan               20/09/2012                  Itay                    [SW-3609]
*******************************************************************************/
trigger CheckLeadCompanyNameInAccount on Lead (before insert, before update) {
    
    if(trigger.isInsert || trigger.isUpdate && SalesProcessWS.getSalesProcessWS_FullRegistrationFlow_Step1() == true){
    	
	    Map<String, List<Lead>> leadByCompany = new Map<String, List<Lead>>();
	    
	    for(Lead l : trigger.new){
	        if( l.Company != null && l.Company != '' ){
	            if(!leadByCompany.containsKey(l.Company.toLowerCase())){
	                leadByCompany.put(l.Company.toLowerCase(), new List<Lead>());
	            }
	            leadByCompany.get(l.Company.toLowerCase()).add(l);
	        }
	    }
	    
	    if(!leadByCompany.isEmpty()){
	        
	        for( Account acc : [SELECT Id, Name FROM Account WHERE Name IN :leadByCompany.keySet() AND Name != null] ){
	            if( leadByCompany.containsKey(acc.Name.toLowerCase()) ){
	                for( Lead l : leadByCompany.get(acc.Name.toLowerCase())){
	                    l.Existing_Account__c = acc.Id;
	                }
	            }
	        }
	    }
    }
}