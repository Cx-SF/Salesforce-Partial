/************************************************************************************** 
Name              : OpportunityTriggersHendler
Description       : Handler to deal with all the triggers on Opportunity object, from trigger component - OpportunityTriggers
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Dana Furman               07/05/2014          Kfir                   [SW-08799]
2. Dana Furman               26/05/2014          Kfir                   [SW-08799]
3. Mohammad Garrah           03/12/2014          Kfir                   [SW-11335]
4. Mendy                     09/12/2014          Kfir                   [SW-11378]
5. Mohammad Garrah           21/12/2014          Kfir                   [SW-11335]
****************************************************************************************/
public class OpportunitiesTriggersHendler{

    public void SetDeliveryAlert(List<Opportunity> OpportunityLst, Map<Id,Opportunity> oldOpportunitysMap)
    {
          for(Opportunity opp : OpportunityLst)
          { 
              
              system.debug((opp.Payment_collected_amount__c != null && oldOpportunitysMap == null) || (oldOpportunitysMap != null && opp.Payment_collected_amount__c != oldOpportunitysMap.get(opp.id).Payment_collected_amount__c));
              if ((opp.Payment_collected_amount__c != null && oldOpportunitysMap == null) || (oldOpportunitysMap != null && opp.Payment_collected_amount__c != oldOpportunitysMap.get(opp.id).Payment_collected_amount__c))
              {   
                system.debug((opp.Billing_Type__c == 'Pre-Payment'));
                system.debug(opp.Opportunity_Status__c);
                system.debug((opp.Opportunity_Status__c == 'Pending Payment'));
                system.debug(opp.Billing_Type__c == 'Pre-Payment' && opp.Opportunity_Status__c == 'Pending Payment');
                system.debug((opp.Opportunity_Status__c == 'Invoiced' && opp.Billing_Type__c == 'Standard'));
                if ((opp.Billing_Type__c == 'Pre-Payment' && opp.Opportunity_Status__c == 'Pending Payment') || (opp.Opportunity_Status__c == 'Invoiced' && opp.Billing_Type__c == 'Standard'))
                {
                      opp.Delivery_Alert__c = true;
                    system.debug(opp.Delivery_Alert__c + ' opp.Delivery_Alert__c');
                }
              }
          }
    }     
}