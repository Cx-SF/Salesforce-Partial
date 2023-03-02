public with sharing class HourReportHandler {
	
    /*
     * Author: Yuval Aviram
     * Date: septmeber 2018
     * Description: This method is needed to support the new "PS Entitlment" module.
      PS hours are now monitored using a new salesfroce object - "PS_Entitlment__c". 
      For every logged hour we need to rollup the hours to the parent entitlment.
	  We cant create the relation between the objects as a master detail and therfore we need develop the "rollup logic".
      The below functions support this rollup request, caculates : on insert, on update and on delete.
     * 
	*/
    Public void calculateNewHoursUsedOnInsert(list<Hour_Report__c> HourReportList) {
    	system.debug('iCloudius - calculateNewHoursUsedOnInsert: ' + HourReportList);
    	set<string> releventEntitlmentsIdsSet = new set<string>();
    	for (Hour_Report__c hour_i : HourReportList) {
    		
    		if ((hour_i.PS_Entitlement__c != null && hour_i.Is_billable__c == 'Billable') || (hour_i.PS_Entitlement_non_billable__c != null && hour_i.Is_billable__c == 'Non - Billable')) {
    			system.debug('iCloudius - Adding on Insert');
    			releventEntitlmentsIdsSet.add(((hour_i.Is_billable__c == 'Billable') ? hour_i.PS_Entitlement__c : hour_i.PS_Entitlement_non_billable__c));
    		}
    	}
    	if (releventEntitlmentsIdsSet.size() > 0) { 
    		
    		database.update(calculateNewHoursUsed(releventEntitlmentsIdsSet)); 														  
    	}
    }
    
    
    
    
    Public void calculateNewHoursUsedOnDelete(list<Hour_Report__c> HourReportList) {  
    	
    	set<string> releventEntitlmentsIdsSet = new set<string>();
    	for (Hour_Report__c hour_i : HourReportList) {
    		
    		if ((hour_i.PS_Entitlement__c != null && hour_i.Is_billable__c == 'Billable') || (hour_i.PS_Entitlement_non_billable__c != null && hour_i.Is_billable__c == 'Non - Billable')) {
    			
    			releventEntitlmentsIdsSet.add(((hour_i.Is_billable__c == 'Billable') ? hour_i.PS_Entitlement__c : hour_i.PS_Entitlement_non_billable__c));
    			
    		}
    	}
    	
    	if (releventEntitlmentsIdsSet.size() > 0) {
    		
    		database.update(calculateNewHoursUsed(releventEntitlmentsIdsSet));   		
    	}
    
    }
   	
   	//need to identify if there was any important change and then query all log hours per entitlment and calculate again
    Public void calculateNewHoursUsedOnUpdate(list<Hour_Report__c> HourReportList,map<Id,Hour_Report__c> beforeUpdateMap) {
    	system.debug('iCloudius - calculateNewHoursUsedOnUpdate new: ' + JSON.serializePretty(HourReportList));
    	system.debug('iCloudius - calculateNewHoursUsedOnUpdate old: ' + JSON.serializePretty(beforeUpdateMap));
    	set<string> releventEntitlmentsIdsSet = new set<string>();
    	for (Hour_Report__c hour_i : HourReportList) {
    		
    		if ((hour_i.Number_of_Hours__c != beforeUpdateMap.get(hour_i.id).Number_of_Hours__c) ||
    			(hour_i.Is_billable__c == 'Billable' && beforeUpdateMap.get(hour_i.id).Is_billable__c != 'Billable') || (hour_i.Is_billable__c == 'Non - Billable' && beforeUpdateMap.get(hour_i.id).Is_billable__c != 'Non - Billable') || 
    			(hour_i.PS_Entitlement__c != beforeUpdateMap.get(hour_i.id).PS_Entitlement__c) || (hour_i.PS_Entitlement_non_billable__c != beforeUpdateMap.get(hour_i.id).PS_Entitlement_non_billable__c))
    			system.debug('iCloudius - Adding on Update: ' + hour_i.PS_Entitlement__c);
    				releventEntitlmentsIdsSet.add(((hour_i.Is_billable__c == 'Billable') ? hour_i.PS_Entitlement__c : hour_i.PS_Entitlement_non_billable__c));
    				releventEntitlmentsIdsSet.add(((hour_i.Is_billable__c == 'Billable') ? beforeUpdateMap.get(hour_i.id).PS_Entitlement__c : beforeUpdateMap.get(hour_i.id).PS_Entitlement_non_billable__c));
    				
    	}
    	
    	if(releventEntitlmentsIdsSet.size() > 0) {
    		
    		
    		database.update(calculateNewHoursUsed(releventEntitlmentsIdsSet));
    		
    	}
    
    }
    
    private list<PS_Entitlement__c> calculateNewHoursUsed (set<string> EntitlmentsIdsSet) {
    	system.debug('iCloudius - calculateNewHoursUsed - EntitlmentsIdsSet: ' + EntitlmentsIdsSet);
    	
    	list<PS_Entitlement__c> EntitlmentsToUpdateList = new list<PS_Entitlement__c>([Select p.WDCX_Hours_Used__c, p.Id, Hours_Used_DataFix__c, 
    																	(Select Id, Number_of_Hours__c, Is_billable__c 
    																	From Log_Used_Hours__r),(Select Id, Number_of_Hours__c, Is_billable__c 
    																	From Log_Used_Hours1__r)  
    															  From PS_Entitlement__c p
    															  where id in: EntitlmentsIdsSet]); 
    	
    	system.debug('iCloudius - EntitlmentsToUpdateList: ' + ((EntitlmentsToUpdateList != null) ? JSON.serializePretty(EntitlmentsToUpdateList) : 'isEmpty'));
    		for (PS_Entitlement__c ent_i : EntitlmentsToUpdateList) {
    			
    			ent_i.WDCX_Hours_Used__c = (ent_i.Hours_Used_DataFix__c != null && ent_i.Hours_Used_DataFix__c > 0) ? ent_i.Hours_Used_DataFix__c : 0;
    			ent_i.Hours_Used_non_billable__c = 0;
    			for (Hour_Report__c hour_i : ent_i.Log_Used_Hours__r) { 
    				if (hour_i.Is_billable__c == 'Billable') {
    					
    					ent_i.WDCX_Hours_Used__c += hour_i.Number_of_Hours__c;
    				}
    			}
    			system.debug('iCloudius - ent_i.Log_Used_Hours1__r: ' + ent_i.Log_Used_Hours1__r);
    			for (Hour_Report__c hour_i : ent_i.Log_Used_Hours1__r) if (hour_i.Is_billable__c == 'Non - Billable') ent_i.Hours_Used_non_billable__c += hour_i.Number_of_Hours__c;
    		}
    		
    	return EntitlmentsToUpdateList;
    }
    
    /*End of rollup related functions*/
}