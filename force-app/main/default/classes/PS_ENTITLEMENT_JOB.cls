global class PS_ENTITLEMENT_JOB implements Schedulable {
    
    global void execute (schedulableContext SC) {
        
        date EndD  = null;
        List<Id> opportunityIdList = new List<Id>();
        list <PS_Entitlement__c> Entitlement = new list <PS_Entitlement__c>();
        list <OpportunityLineItem> OpportunityLI_L = [SELECT Id, Quantity,TotalPrice,OpportunityId, Product2Id , Product2.name ,WDCX_Generate_PS_Entitlement__c,SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c,
                                                     Opportunity.accountid ,Product2.WDCX_PSEntitlementMonths__c , Product2.WDCX_PSHours__c FROM OpportunityLineItem where WDCX_Generate_PS_Entitlement__c= true and CX_PS_Entitlement_Job_Executed__c = false and (Opportunity_Stage__c  = 'Approved' or Opportunity_Stage__c  = 'Closed Won')];
		System.debug('OppIdList: ' + OpportunityLI_L.size());
        for(OpportunityLineItem item: OpportunityLI_L)
        {
            opportunityIdList.add(item.OpportunityId); /// add to the list all Opportunity Id which need to be update later (this list can old duplicates id)
            if(item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c == null)
            {
                EndD = null;
            }
            else if(ITEM.Product2.WDCX_PSEntitlementMonths__c == null)
            {
                EndD =  item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c;
            }
            else
            {
                EndD = (item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c).addMonths((Integer)(ITEM.Product2.WDCX_PSEntitlementMonths__c));
            }
            Entitlement.add(new PS_Entitlement__c(name = 'PS_' + item.Product2.name  ,WDCX_Opportunity_Line_Id__c = item.id, WDCX_Quantity__c = item.Quantity ,WDCX_Opportunity__c = item.OpportunityId , WDCX_Original_Start_Date__c = item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c, 
                                                  WDCX_PS_Product__c  = item.Product2Id , WDCX_Account__c = item.Opportunity.accountid , WDCX_Start_Date__c = item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c ,EntitlementAccount__c  = item.Opportunity.accountid 
                                                 ,WDCX_Hours_per_unit__c = ITEM.Product2.WDCX_PSHours__c ,WDCX_Time_to_expiration_Months__c  = ITEM.Product2.WDCX_PSEntitlementMonths__c ,WDCX_End_Date__c = EndD, Opportunity_Product_Amount__c = item.TotalPrice )); 
            item.WDCX_Generate_PS_Entitlement__c = false; 
            
        } 

        insert Entitlement;
        update OpportunityLI_L;
		System.debug('opp size: ' + opportunityIdList.size());
		System.debug('opp to update: ' + opportunityIdList);
		if(!opportunityIdList.isEmpty()) updateOppList(opportunityIdList);
    }

	@future
	public static void updateOppList(List<Id> oppList){
		System.debug('oppList size: ' + oppList.size());
		System.debug('oppList to update: ' + oppList);
		Map<Id, Opportunity> opportunity4Update = new Map<Id, Opportunity>();
		 for(Id oppId : oppList){
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            opp.CX_PS_Entitlement_Job_Executed__c = true; /// The change
            opportunity4Update.put(opp.Id, opp); // filling the map with the opportunities after the change, The map makes sure that there are no duplicates
		 }

		 System.debug('opportunity4Update size: ' + opportunity4Update.size());
		 if(!opportunity4Update.isEmpty()) update opportunity4Update.values(); // Update all opportunities if opportunity4Update is not null or empty;
	}
}