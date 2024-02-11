/******************************************************************************* 
Name              : CheckAccountNameInLead
Description       : Searchs if there is a Lead with Company for the Accounts Name,  and assigns the Account to the Lead
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan               20/09/2012                  Itay                    [SW-3609]
*******************************************************************************/
trigger CheckAccountNameInLead on Account (after insert) {
	if(!Utils.CodeOff){
		if(MonitorRecursionClass.getFullRegistrationFlowMonitor() == true || Test.isRunningTest()){
			Map<String, Id> accIdByName = new Map<String, Id>();
	    
			for( Account acc : trigger.new ){
				if(!accIdByName.containsKey(acc.Name)){
					accIdByName.put(acc.Name.toLowerCase(), acc.Id);
				}
			}
	    
			if(!accIdByName.isEmpty()){
				List<Lead> lead2Upd = new List<Lead>();
	        
				for(Lead l : [SELECT Id, Company FROM Lead WHERE Company IN :accIdByName.keySet() AND Company != Null AND Company != '' AND IsConverted = false]){
					l.Existing_Account__c = accIdByName.get(l.Company.toLowerCase());
					lead2Upd.add(l);
				}
	        
				if(!lead2Upd.isEmpty()){
					update lead2Upd;
				}       
			}
		}
	}
}