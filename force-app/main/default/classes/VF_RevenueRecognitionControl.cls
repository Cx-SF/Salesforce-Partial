/************************************************************************************** 
Name              : VF_RevenueRecognitionControl
Description       : Conroller for the reveneue recognition control page
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mohammad Garrah           04/12/2014          Kfir                   [SW-11335]
****************************************************************************************/
public class VF_RevenueRecognitionControl {
    
    public Revenue_Recognition_Control__c RRC{get;set;}
    private map<ID,list<Revenue_Recognition__c>> map_unlockedRR{get;set;}
    private map<ID,list<Revenue_Recognition__c>> map_lockedRR{get;set;}
    private map<ID,Decimal> map_lockedRRAmount{get;set;}
    private map<ID,Decimal> map_unlockedRRTotalDays{get;set;}
    private map<ID,Product_Control__c> map_PRcopyOfAmountAndDate;
    public Boolean disableButtons{get;set;}
    
    
    public VF_RevenueRecognitionControl(ApexPages.StandardController controller){
        
        Id oppId = ((Opportunity)controller.getRecord()).id;
        
        Opportunity opp = [select id, Name, CurrencyIsoCode, Amount,
                                 (select id from Revenue_Recognition_Contro__r order by CreatedDate DESC limit 1),
                                 (select id, Amount__c, Date__c, Locked__c, OpportunityLineItemId__c, Days_In_Quarter__c from Revenue_Recognition__r order by Date__c ASC)
                           from Opportunity where id =: oppId];
        
        disableButtons = false;
        
        if(opp.Revenue_Recognition_Contro__r != null && opp.Revenue_Recognition_Contro__r.size() > 0){
            Id revenueRecognitionId = opp.Revenue_Recognition_Contro__r[0].id;
        
            map_unlockedRR = new map<ID,list<Revenue_Recognition__c>>();
            map_lockedRR = new map<ID,list<Revenue_Recognition__c>>();
            map_lockedRRAmount = new map<ID,Decimal>();
            map_unlockedRRTotalDays = new map<ID,Decimal>();
            
            if(opp.Revenue_Recognition__r != null && opp.Revenue_Recognition__r.size() > 0){
                for(Revenue_Recognition__c rr : opp.Revenue_Recognition__r){
                    if(rr.Locked__c){
                        if(!map_lockedRR.containsKey(rr.OpportunityLineItemId__c)){
                            map_lockedRR.put(rr.OpportunityLineItemId__c,new list<Revenue_Recognition__c>());
                            map_lockedRRAmount.put(rr.OpportunityLineItemId__c,0);
                        }
                        map_lockedRR.get(rr.OpportunityLineItemId__c).add(rr);
                        Decimal temp = map_lockedRRAmount.get(rr.OpportunityLineItemId__c) + (rr.Amount__c == null ? 0 : rr.Amount__c);
                        map_lockedRRAmount.put(rr.OpportunityLineItemId__c,temp);
                    }
                    else{
                        if(!map_unlockedRR.containsKey(rr.OpportunityLineItemId__c)){
                            map_unlockedRR.put(rr.OpportunityLineItemId__c,new list<Revenue_Recognition__c>());
                            map_unlockedRRTotalDays.put(rr.OpportunityLineItemId__c,0);
                        }
                        map_unlockedRR.get(rr.OpportunityLineItemId__c).add(rr);
                        Decimal temp = map_unlockedRRTotalDays.get(rr.OpportunityLineItemId__c) + (rr.Days_In_Quarter__c == null ? 0 : rr.Days_In_Quarter__c);
                        map_unlockedRRTotalDays.put(rr.OpportunityLineItemId__c,temp);
                    }
                }
            }
            
            RRC = [select id, Name, Opportunity_Name__c, Generated__c, Opportunity_Name__r.Name, Opportunity_Name__r.CurrencyIsoCode, Opportunity_Name__r.Amount,
                         (select id, Original_Total_Price__c, Product_Name__c, Product_Name__r.Product_Type__c, Total_Price_for_Revenue_Recognition__c, Start_Date__c, Quantity__c, Locked_Revenue_Recognition__c, OpportunityLineItemId__c from Product_Control__r)
                          from Revenue_Recognition_Control__c where id =: revenueRecognitionId];
            
            map_PRcopyOfAmountAndDate = new map<ID,Product_Control__c>();
            
            for(Product_Control__c pc : RRC.Product_Control__r){
                pc.Total_Price_for_Revenue_Recognition__c += pc.Locked_Revenue_Recognition__c;
                pc.Locked_Revenue_Recognition__c = map_lockedRRAmount.containsKey(pc.OpportunityLineItemId__c) ? map_lockedRRAmount.get(pc.OpportunityLineItemId__c) : 0;
                pc.Total_Price_for_Revenue_Recognition__c -= pc.Locked_Revenue_Recognition__c;
                map_PRcopyOfAmountAndDate.put(pc.OpportunityLineItemId__c,new Product_Control__c(Total_Price_for_Revenue_Recognition__c=pc.Total_Price_for_Revenue_Recognition__c,Start_Date__c=pc.Start_Date__c));
            }
            
            if(map_lockedRR != null && map_lockedRR.size() == RRC.Product_Control__r.size())
                disableButtons = true;
        }
    }
    
    public PageReference SaveRRC(){
        return Save_Generate(false);
    }
    
    public PageReference GenerateRR(){
        return Save_Generate(true);
    }
    
    public PageReference Save_Generate(Boolean generate){
        list<Revenue_Recognition__c> lst_revenueRecognitionsToCreate = new list<Revenue_Recognition__c>();
        list<Revenue_Recognition__c> lst_revenueRecognitionsToUpdate = new list<Revenue_Recognition__c>();
        list<Revenue_Recognition__c> lst_revenueRecognitionsToDelete = new list<Revenue_Recognition__c>();
        Boolean PCchanged = false;
        Decimal totalPrices = 0;
        for(Product_Control__c pc : RRC.Product_Control__r){
            totalPrices += pc.Total_Price_for_Revenue_Recognition__c + pc.Locked_Revenue_Recognition__c;
            Product_Control__c originalPC = map_PRcopyOfAmountAndDate.get(pc.OpportunityLineItemId__c);
            if(pc.Total_Price_for_Revenue_Recognition__c != originalPC.Total_Price_for_Revenue_Recognition__c || pc.Start_Date__c != originalPC.Start_Date__c)
                PCchanged = true;
            
            if(generate){
                if(RRC.Generated__c && pc.Total_Price_for_Revenue_Recognition__c == originalPC.Total_Price_for_Revenue_Recognition__c && pc.Start_Date__c == originalPC.Start_Date__c)
                    continue;
                /*if(map_unlockedRR.isEmpty() && !map_lockedRR.isEmpty()){
                    // all records where locked
                    ApexPages.Message myMsgaaa = new ApexPages.Message(ApexPages.Severity.Error,'All the revenue recognition records are locked.');
                    ApexPages.addMessage(myMsgaaa);
                    return null;
                }*/
                
                if(!map_lockedRR.containsKey(pc.OpportunityLineItemId__c)){
                    // create new and delete existing RR
                    Decimal numOfRecords = 1;
                    if(pc.Product_Name__r.Product_Type__c != null || pc.Product_Name__r.Product_Type__c != ''){
                        Revenue_Recognition_Types__c RRT_customSettings = Revenue_Recognition_Types__c.getValues(pc.Product_Name__r.Product_Type__c);
                        if(RRT_customSettings != null)
                            numOfRecords = RRT_customSettings.Number_Of_Records__c;
                    }
                    if(numOfRecords == 1){
                        lst_revenueRecognitionsToCreate.add(createRevenueRecognition(pc.Product_Name__c, pc.Start_Date__c, pc.Total_Price_for_Revenue_Recognition__c, null, pc.OpportunityLineItemId__c));
                    }
                    else if(numOfRecords > 1){
                        //Integer recordsToGenerate = (Integer)(pc.Quantity__c * numOfRecords);
                        Integer recordsToGenerate = (Integer)numOfRecords;
                        Date rrDate = pc.Start_Date__c;
                        if(rrDate.day() == 1 && (rrDate.month() == 1 || rrDate.month() == 4 || rrDate.month() == 7 || rrDate.month() == 10)){
                            for(Integer i = 1; i <= recordsToGenerate; i++){
                                lst_revenueRecognitionsToCreate.add(createRevenueRecognition(pc.Product_Name__c, rrDate, pc.Total_Price_for_Revenue_Recognition__c/recordsToGenerate, 90, pc.OpportunityLineItemId__c));
                                rrDate = rrDate.addMonths(3);
                            }
                        }
                        else{
                            Date nextQuater = nextQuaterDate(rrDate);
                            Integer daysInFirstQuarter = rrDate.daysBetween(nextQuater);
                            if(daysInFirstQuarter >= 90)
                                daysInFirstQuarter = 90 - rrDate.day();
                            Integer totaldays = recordsToGenerate * 90;
                            //Decimal amount = pc.Total_Price_for_Revenue_Recognition__c/recordsToGenerate;
                            lst_revenueRecognitionsToCreate.add(createRevenueRecognition(pc.Product_Name__c, rrDate, pc.Total_Price_for_Revenue_Recognition__c*daysInFirstQuarter/totaldays, daysInFirstQuarter, pc.OpportunityLineItemId__c));
                            for(Integer i = 1; i <= recordsToGenerate - 1; i++){
                                rrDate = rrDate.addMonths(3);
                                lst_revenueRecognitionsToCreate.add(createRevenueRecognition(pc.Product_Name__c, rrDate, pc.Total_Price_for_Revenue_Recognition__c*90/totaldays, 90, pc.OpportunityLineItemId__c));
                                //nextQuater = nextQuater.addMonths(3);
                            }
                            lst_revenueRecognitionsToCreate.add(createRevenueRecognition(pc.Product_Name__c, rrDate.addMonths(3), pc.Total_Price_for_Revenue_Recognition__c*(90-daysInFirstQuarter)/totaldays, 90-daysInFirstQuarter, pc.OpportunityLineItemId__c));
                        }
                    }
                    if(map_unlockedRR.containsKey(pc.OpportunityLineItemId__c))
                        lst_revenueRecognitionsToDelete.addAll(map_unlockedRR.get(pc.OpportunityLineItemId__c));
                }
                else if(map_unlockedRR.containsKey(pc.OpportunityLineItemId__c) && map_lockedRR.containsKey(pc.OpportunityLineItemId__c)){
                    // need to edit the existing revenue recognition records
                    Decimal totalDays = map_unlockedRRTotalDays.get(pc.OpportunityLineItemId__c);
                    for(Revenue_Recognition__c rr : map_unlockedRR.get(pc.OpportunityLineItemId__c)){
                        if(rr.Days_In_Quarter__c == null)
                            rr.Amount__c = pc.Total_Price_for_Revenue_Recognition__c;
                        else
                            rr.Amount__c = pc.Total_Price_for_Revenue_Recognition__c*rr.Days_In_Quarter__c/totalDays;
                        lst_revenueRecognitionsToUpdate.add(rr);
                    }
                }
            }
        }
        if(totalPrices != RRC.Opportunity_Name__r.Amount){
            ApexPages.Message myMsgaaa = new ApexPages.Message(ApexPages.Severity.Error,'Sum of Total Prices not equals to the Opportunity’s Amount.');
            ApexPages.addMessage(myMsgaaa);
            return null;
        }
        
        if(!lst_revenueRecognitionsToCreate.isEmpty())
            insert lst_revenueRecognitionsToCreate;
        if(!lst_revenueRecognitionsToDelete.isEmpty())
            delete lst_revenueRecognitionsToDelete;
        if(!lst_revenueRecognitionsToUpdate.isEmpty())
            update lst_revenueRecognitionsToUpdate;
        
        if(RRC.Generated__c){
            if(PCchanged){
                Integer versionNum = Integer.valueOf(RRC.Name.replace('Version ',''));
                Revenue_Recognition_Control__c rrcClone = new Revenue_Recognition_Control__c(Name='Version ' + String.valueOf(versionNum+1),Opportunity_Name__c=RRC.Opportunity_Name__c, Generated__c=generate);
                insert rrcClone;
                // clone products controls
                list<Product_Control__c> lst_productsClone = cloneRevenueRecognitionControl(RRC.Product_Control__r, rrcClone.Id);
                insert lst_productsClone;
            }
        }
        else{
            if(generate){
                RRC.Generated__c = generate;
                update RRC;
            }
            if(PCchanged)   update RRC.Product_Control__r;
        }
        if(generate)
            return new pageReference('/' + RRC.Opportunity_Name__c);
        return new pageReference('/apex/VF_RevenueRecognitionControl?id=' + RRC.Opportunity_Name__c);
    }
    
    
    private Revenue_Recognition__c createRevenueRecognition(ID productId, Date startDate, Decimal totalPriceForRecognition, Decimal daysInQuarter, ID OpportunityLineItemId){
        Revenue_Recognition__c rr = new Revenue_Recognition__c();
        rr.Opportunity_Name__c = RRC.Opportunity_Name__c;
        rr.CurrencyIsoCode = RRC.Opportunity_Name__r.CurrencyIsoCode;
        rr.Product_Name__c = productId;
        rr.Date__c = startDate;
        rr.Amount__c = totalPriceForRecognition;
        rr.Days_In_Quarter__c = daysInQuarter;
        rr.OpportunityLineItemId__c = OpportunityLineItemId;
        return rr;
    }
    
    private Date nextQuaterDate(Date d){
        Integer month;
        if(d.month() < 4)
            month = 4;
        else if(d.month() < 7)
            month = 7;
        else if(d.month() < 10)
            month = 10;
        else
            month = 1;
        
        return Date.newInstance(month != 1 ? d.year() : d.year()+1, month, 1);
    }
    
    private list<Product_Control__c> cloneRevenueRecognitionControl(list<Product_Control__c> lst_source, ID RRControlId){
        list<Product_Control__c> lst_clone = new list<Product_Control__c>();
        for(Product_Control__c p : lst_source){
            Product_Control__c clonePC = new Product_Control__c();
            clonePC.Product_Name__c = p.Product_Name__c;
            clonePC.Original_Total_Price__c = p.Original_Total_Price__c;
            clonePC.Total_Price_for_Revenue_Recognition__c = p.Total_Price_for_Revenue_Recognition__c;
            clonePC.Start_Date__c = p.Start_Date__c;
            clonePC.Quantity__c = p.Quantity__c;
            clonePC.Locked_Revenue_Recognition__c = p.Locked_Revenue_Recognition__c;
            clonePC.OpportunityLineItemId__c = p.OpportunityLineItemId__c;
            clonePC.Revenue_Recognition_Controll__c = RRControlId;
            lst_clone.add(clonePC);
        }
        return lst_clone;
    }
    
}