/************************************************************************************** 
Name              : OpportunityCls
Description       : 
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mendy                     09/12/2014          Kfir                   [SW-11378]
****************************************************************************************/
public with sharing class OpportunityCls 
{
    public string oppId {get; set;}
    public Opportunity opp {get; set;}
    //public String billingType {get;set;}
    //public List<SelectOption> billingTypeSO {get;set;}
    public String deliveryStatus {get;set;}
    public List<SelectOption> deliveryStatusSO {get;set;}
    public boolean isBillingType {get;set;}
    
    //public boolean displayPopup {get; set;}  
    public boolean displayPopup2 {get; set;}     
    
    /*public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {        
        displayPopup = true;    
    }*/
    public void closePopup2() {        
        displayPopup2 = false;    
    }     
    public void showPopup2() {        
        displayPopup2 = true;    
    }
    public OpportunityCls(ApexPages.StandardController controller)
    {
        oppId = Apexpages.currentPage().getParameters().get('id');
        //billingTypeSO = new List<SelectOption>();
        //billingTypeSO.add(new selectOption('Pre-Payment','Pre-Payment'));
        //billingTypeSO.add(new selectOption('Standard','Standard'));
        deliveryStatusSO = new List<SelectOption>();
        deliveryStatusSO.add(new selectOption('Yes','Yes'));
        deliveryStatusSO.add(new selectOption('No','No'));
        opp = [select id, name, Billing_Type__c, Delivery_Alert__c, StageName, Opportunity_Status__c, Support_Status__c, Payments_Terms__c from Opportunity where id = :oppId limit 1];
        //isBillingType = opp.Billing_Type__c == null && opp.Payments_Terms__c == 'Other' ? true : false;
        //if (isBillingType)
        //    showPopup();
        system.debug('opp.Delivery_Alert__c = ' +opp.Delivery_Alert__c);
        if (opp.Delivery_Alert__c && opp.Billing_Type__c == 'Pre-Payment')
            showPopup2();
    }
    
    /*public void SaveBilling()
    {
        opp.Billing_Type__c = billingType;
        system.debug('billingType = ' + opp.Billing_Type__c);
        system.debug('billingTypeSO = ' + billingTypeSO);
        if (billingType == 'Standard')
        {
            opp.Opportunity_Status__c = 'Pending Invoice/ Credit';
            opp.Support_Status__c = 'Pending Temp Delivery';
        }
        else if (billingType == 'Pre-Payment')
        {
            opp.Opportunity_Status__c = 'Pending Payment';
            opp.Support_Status__c = 'Do NOT Deliver';
        }
        closePopup();
        update opp;
    }*/
    
    public void SaveDelivery()
    {
        closePopup2();
        if (deliveryStatus == 'Yes')
        {
            opp.Opportunity_Status__c = 'OK to be Delivered';
            if (opp.Billing_Type__c == 'Pre-Payment')
                opp.Support_Status__c = 'Pending Permanent Delivery';
        }
        else
        {
            if (opp.Billing_Type__c == 'Pre-Payment')
            {
                opp.Support_Status__c = 'Do NOT Deliver';
                opp.Opportunity_Status__c = 'Pending Payment';
            }
        }
        opp.Delivery_Alert__c = false;
        update opp;
    }

}