/******************************************************************************* 
Name              : LeadsWS
Description       : Creates an Activity on the Lead
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan               21/02/2013                                      [SW-4654]
2. Hernan               18/03/2013                                      [SW-4843]
*******************************************************************************/
global class LeadsWS {
    
    webservice static String createCallActivity(Id leadId){
        String result = '';
        try{
            Lead l = [Select Id, Status, Sales_Rep__r.Name, Sales_Rep__c, OwnerId, Owner.Name, Lead_Origin__c From Lead WHERE Id =: leadId];
            
            Map<String,Schema.RecordTypeInfo> rts = Task.sObjectType.getDescribe().getRecordTypeInfosByName();          
            
            Task t = new Task();
            t.Status = 'Completed ';
            t.Subject = 'Call Made - ' + l.Status;
            t.Priority = 'Normal';
            t.OwnerId = UserInfo.getUserId();
            t.WhoId = l.Id;
            t.ActivityDate = System.today();
            t.Lead_Status__c = l.Status;
            t.Lead_Origin__c = l.Lead_Origin__c;
            t.Lead_Sales_Rep__c = l.Sales_Rep__r.Name;
            t.Lead_Owner__c = l.Owner.Name;
            t.Automated_Task_Type__c = 'Call';
            t.RecordTypeId = rts.get('Automated Task').getRecordTypeId();
            
            insert t;
            
            result = t.Id;
        }catch(Exception e){
            result = 'Error: ' + e.getMessage();
        }
        return result;      
    }
    
    webservice static String createCallActivities(List<Id> leadList){
        String response = 'Success';
        try{
            List<Task> task2Ins = new List<Task>();
            Map<String,Schema.RecordTypeInfo> rts = Task.sObjectType.getDescribe().getRecordTypeInfosByName();
            
            for( Lead l : [Select Id, Status, Sales_Rep__r.Name, Sales_Rep__c, OwnerId, Owner.Name, Lead_Origin__c From Lead WHERE Id IN :leadList] ){
                Task t = new Task();
                t.Status = 'Completed ';
                t.Subject = 'Call Made - ' + l.Status;
                t.Priority = 'Normal';
                t.OwnerId = UserInfo.getUserId();
                t.WhoId = l.Id;
                t.ActivityDate = System.today();
                t.Lead_Status__c = l.Status;
                t.Lead_Origin__c = l.Lead_Origin__c;
                t.Lead_Sales_Rep__c = l.Sales_Rep__r.Name;
                t.Lead_Owner__c = l.Owner.Name;
                t.Automated_Task_Type__c = 'Call';
                t.RecordTypeId = rts.get('Automated Task').getRecordTypeId();
                
                task2Ins.add(t);
            }
            
            if(!task2Ins.isEmpty()){
                insert task2Ins;
            }
        }catch(Exception e){
            response = 'Error: ' + e.getMessage();
        }
        return response;
    }
    
    webservice static String FollowUp( List<Id> leadList , String selecteDate){
        String response = 'Success';
        try{
            List<Lead> ld2Upd = new List<Lead>();
            
            for( Id ldId : leadList ){
                Lead ld = new Lead(Id = ldId, Follow_Up__c = Date.parse(selecteDate));
                ld2Upd.add(ld);
            }
            
            if(!ld2Upd.isEmpty()){
                update ld2Upd;
            }
        }catch(Exception e){
            response = 'Error: ' + e.getMessage();
        }
        return response;
    }
    
}