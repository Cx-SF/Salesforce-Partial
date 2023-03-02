/************************************************************************************** 
Name              : VF_OpportunityRevenueRecognition
Description       : Conroller for the opportunity reveneue recognition page
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mohammad Garrah           07/12/2014          Kfir                   [SW-11335]
****************************************************************************************/
public class VF_OpportunityRevenueRecognition {
    
    public list<String> lst_oliIDs{get;set;}
    public map<String,String> map_productNames{get;set;}
    public set<String> set_colHeader{get;set;}
    public list<String> list_colHeader{get;set;}
    public map<String,map<String,String>> map_colValues{get;set;}
    public map<String,String> map_footers{get;set;}
    
    public VF_OpportunityRevenueRecognition(ApexPages.StandardController controller){
        
        Id oppId = ((Opportunity)controller.getRecord()).id;
        
        list<Revenue_Recognition__c> lst_RR = new list<Revenue_Recognition__c>([select id, Date__c, Amount__c, Product_Name__r.Name, OpportunityLineItemId__c from Revenue_Recognition__c where Opportunity_Name__c =: oppId order by Date__c ASC]);
        
        lst_oliIDs = new list<String>();
        map_productNames= new map<String,String>();
        set_colHeader = new set<String>();
        list_colHeader = new list<String>();
        map_colValues = new map<String,map<String,String>>();
        map_footers = new map<String,String>();

        
        set<Date> set_dates = new set<Date>();
        list<Date> lst_dates = new list<Date>();
        map<String,map<Date,String>> map_partialColumns = new map<String,map<Date,String>>();
        
        for(Revenue_Recognition__c r : lst_RR){
            if(!set_dates.contains(r.Date__c)){
                set_dates.add(r.Date__c);
                lst_dates.add(r.Date__c);
                String q = getQuarter(r.Date__c);
                if(!set_colHeader.contains(q)){
                    list_colHeader.add(q);
                    set_colHeader.add(q);
                }
            }
            if(!map_partialColumns.containsKey(r.OpportunityLineItemId__c)){
                map_partialColumns.put(r.OpportunityLineItemId__c, new map<Date,String>());
                map_productNames.put(r.OpportunityLineItemId__c, r.Product_Name__r.Name);
                lst_oliIDs.add(r.OpportunityLineItemId__c);
            }
            map_partialColumns.get(r.OpportunityLineItemId__c).put(r.Date__c, String.valueOf(r.Amount__c.round()));
        }
        lst_dates.sort();
        
        for(String oliId : map_partialColumns.keySet()){
            map<Date,String> map_dateValues = map_partialColumns.get(oliId);
            //map_colValues.put(oliId, new map<String,String>());
            map<String,String> map_cols = new map<String,String>();
            for(Date d : lst_dates){
                String str_quarter = getQuarter(d);
                if(map_dateValues.containsKey(d))
                    map_cols.put(str_quarter,map_dateValues.remove(d));
                else{
                    if(!map_cols.containsKey(str_quarter))
                        map_cols.put(str_quarter,'0');
                }
                // footer
                if(!map_footers.containsKey(str_quarter))
                    map_footers.put(str_quarter,map_cols.get(str_quarter));
                else{
                    Decimal temp = Decimal.valueOf(map_footers.get(str_quarter));
                    map_footers.put(str_quarter,String.valueOf(temp + Decimal.valueOf(map_cols.get(str_quarter))));
                }
            }
            map_colValues.put(oliId,map_cols);
        }
        
        //map_colValues.put(oppId,new map<String,String>());
    }
    
    public String getQuarter(Date d){
        if(d.Month() < 4)
            return 'Q1-'+d.Year();
        if(d.Month() < 7)
            return 'Q2-'+d.Year();
        if(d.Month() < 10)
            return 'Q3-'+d.Year();
        return 'Q4-'+d.Year();
    }
}