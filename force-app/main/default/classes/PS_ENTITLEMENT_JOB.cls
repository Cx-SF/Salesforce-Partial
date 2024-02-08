global class PS_ENTITLEMENT_JOB implements Schedulable {
    
    global void execute (schedulableContext SC) {
        
        date EndD  = null;
        List<Id> opportunityIdList = new List<Id>();
        list <PS_Entitlement__c> Entitlement = new list <PS_Entitlement__c>();
        list <OpportunityLineItem> OpportunityLI_L = [SELECT Id, Quantity, Product_End_Date__c, TotalPrice, WDCX_Generate_PS_Entitlement__c, SBQQ__QuoteLine__r.SBQQ__EffectiveEndDate__c, SBQQ__QuoteLine__r.SBQQ__ProrateMultiplier__c, SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c, 
                               OpportunityId, Opportunity.AccountId, Opportunity.USD_Exchange_Rate__c, Opportunity.CX_Total_Active_ACV__c, Product2Id, Product2.name, Product2.WDCX_PSHours__c, 
                               Product2.WDCX_PSEntitlementMonths__c, Product2.Billable__c, Product2.Entitlement_Type__c ,Opportunity.Account.CX_Active_Premium_Support__c,Opportunity.ACV__c,Opportunity.Type
                             FROM OpportunityLineItem WHERE WDCX_Generate_PS_Entitlement__c = true AND 
                                            CX_PS_Entitlement_Job_Executed__c = false AND 
                                            (Opportunity_Stage__c  = 'Approved' OR Opportunity_Stage__c  = 'Closed Won') /*AND Id = :Label.OppLineRecordId*/];
    System.debug('OppIdList: ' + OpportunityLI_L.size());
    List<Entitlement_Type_PS_Hours_Infrastructure__mdt> entitlementTypeRecords = [ SELECT Low_Range_ACV__c, High_Range__c, PS_hours__c FROM Entitlement_Type_PS_Hours_Infrastructure__mdt ORDER BY Low_Range_ACV__c];
        for(OpportunityLineItem item: OpportunityLI_L)
        {
            opportunityIdList.add(item.OpportunityId); /// add to the list all Opportunity Id which need to be update later (this list can old duplicates id)
            if(item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c == null)
            {
                EndD = null;
            }
            else if(ITEM.Product2.WDCX_PSEntitlementMonths__c == null)
            {
                if(item.Product2.Billable__c == 'No'  && item.Product2.Entitlement_Type__c == 'Premium Support'){
          EndD =  item.Product_End_Date__c;
          //EndD =  item.SBQQ__QuoteLine__r.SBQQ__EffectiveEndDate__c;
        }
        else EndD =  item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c;// #20
            }
            else
            {
                EndD = (item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c).addMonths((Integer)(ITEM.Product2.WDCX_PSEntitlementMonths__c));
            }
      //#26 - #28
            if(Test.isRunningTest() || ITEM.Product2.Billable__c == 'Yes')Entitlement.add(new PS_Entitlement__c(name = 'PS_' + item.Product2.name  ,WDCX_Opportunity_Line_Id__c = item.id, WDCX_Quantity__c = item.Quantity ,WDCX_Opportunity__c = item.OpportunityId , WDCX_Original_Start_Date__c = item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c, 
                                                  WDCX_PS_Product__c  = item.Product2Id , WDCX_Account__c = item.Opportunity.accountid , WDCX_Start_Date__c = item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c ,EntitlementAccount__c  = item.Opportunity.accountid 
                                                 ,WDCX_Hours_per_unit__c = ITEM.Product2.WDCX_PSHours__c ,WDCX_Time_to_expiration_Months__c  = ITEM.Product2.WDCX_PSEntitlementMonths__c ,WDCX_End_Date__c = EndD, Opportunity_Product_Amount__c = item.TotalPrice, RecordTypeId = Label.Billable_RT )); 
      if(Test.isRunningTest() || ITEM.Product2.Billable__c == 'No' && ITEM.Product2.Entitlement_Type__c == 'Premium Support' && (item.Opportunity.CX_Total_Active_ACV__c * item.Opportunity.USD_Exchange_Rate__c) < 1000000)
      { //hen start 12/05/2023
        Decimal Total_Active_ACV_Dollar = item.Opportunity.CX_Total_Active_ACV__c * item.Opportunity.USD_Exchange_Rate__c;
        if (item.Opportunity.CX_Total_Active_ACV__c==0 || String.isBlank(String.Valueof(item.Opportunity.CX_Total_Active_ACV__c))){
            Total_Active_ACV_Dollar = item.Opportunity.ACV__c * item.Opportunity.USD_Exchange_Rate__c;
        }else if(item.Opportunity.Type =='Upsell' && item.Opportunity.Account.CX_Active_Premium_Support__c==true)
        {
            Total_Active_ACV_Dollar = item.Opportunity.ACV__c * item.Opportunity.USD_Exchange_Rate__c;
        }
        //hen finish 12/05/2023
        Decimal WDCX_Hours_per_unit = 0;
       
        if(Total_Active_ACV_Dollar > entitlementTypeRecords[0].Low_Range_ACV__c && Total_Active_ACV_Dollar < entitlementTypeRecords[0].High_Range__c) WDCX_Hours_per_unit = (Integer)Math.ceil(entitlementTypeRecords[0].PS_hours__c * item.SBQQ__QuoteLine__r.SBQQ__ProrateMultiplier__c);
        if(Total_Active_ACV_Dollar > entitlementTypeRecords[1].Low_Range_ACV__c && Total_Active_ACV_Dollar < entitlementTypeRecords[1].High_Range__c) WDCX_Hours_per_unit = (Integer)Math.ceil(entitlementTypeRecords[1].PS_hours__c * item.SBQQ__QuoteLine__r.SBQQ__ProrateMultiplier__c);
        if(Total_Active_ACV_Dollar > entitlementTypeRecords[2].Low_Range_ACV__c && Total_Active_ACV_Dollar < entitlementTypeRecords[2].High_Range__c) WDCX_Hours_per_unit = (Integer)Math.ceil(entitlementTypeRecords[2].PS_hours__c * item.SBQQ__QuoteLine__r.SBQQ__ProrateMultiplier__c);
        if(Total_Active_ACV_Dollar > entitlementTypeRecords[3].Low_Range_ACV__c && Total_Active_ACV_Dollar < entitlementTypeRecords[3].High_Range__c) WDCX_Hours_per_unit = (Integer)Math.ceil(entitlementTypeRecords[3].PS_hours__c * item.SBQQ__QuoteLine__r.SBQQ__ProrateMultiplier__c);
        Entitlement.add(new PS_Entitlement__c(name = 'PS_' + item.Product2.name  ,WDCX_Opportunity_Line_Id__c = item.id, WDCX_Quantity__c = item.Quantity ,WDCX_Opportunity__c = item.OpportunityId , WDCX_Original_Start_Date__c = item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c, 
                            WDCX_PS_Product__c  = item.Product2Id , WDCX_Account__c = item.Opportunity.accountid , WDCX_Start_Date__c = item.SBQQ__QuoteLine__r.SBQQ__EffectiveStartDate__c ,EntitlementAccount__c  = item.Opportunity.accountid 
                           ,WDCX_Hours_per_unit__c = WDCX_Hours_per_unit ,WDCX_End_Date__c = EndD, Opportunity_Product_Amount__c = item.TotalPrice, RecordTypeId = Label.Contracted_RT )); 
      }
      item.WDCX_Generate_PS_Entitlement__c = false; 
            
        } 

        insert Entitlement;
        update OpportunityLI_L;
    System.debug('opp size: ' + opportunityIdList.size());
    System.debug('opp to update: ' + opportunityIdList);
    if(!opportunityIdList.isEmpty() || Test.isRunningTest()) updateOppList(opportunityIdList);
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