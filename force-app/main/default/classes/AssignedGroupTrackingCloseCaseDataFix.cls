public with sharing class AssignedGroupTrackingCloseCaseDataFix implements Database.Batchable<SObject> {
   private DateTime startDate;
   private DateTime endDate;


 public AssignedGroupTrackingCloseCaseDataFix(DateTime startDate , DateTime endDate)
    {
        this.startDate = startDate != null ? startDate : DateTime.newInstance(2021, 01, 01);
		this.endDate = endDate != null ? endDate : DateTime.newInstance(2021, 06, 01);
    }   
    public AssignedGroupTrackingCloseCaseDataFix() {} 
    
    public Database.QueryLocator start(Database.BatchableContext BC){  
        system.debug('start AssignedGroupTrackingCloseCaseDataFix');
        String Query = 'Select ID,(select  CreatedDate ,End_date_time_group__c ,Case_assigned_group_total_time__r.case__r.Id ,Case_assigned_group_total_time__r.case__r.ClosedDate '+
									'from Case_assigned_groups_log_time__r '+
									'where case_assigned_group_total_time__r.case__r.IsClosed = true ' +
 									' order by CreatedDate )'+
						'From case_assigned_group_total_time__c '+
						'where id in (select Case_assigned_group_total_time__c FRom Case_assigned_group_log_time__c '+
            							'where  case_assigned_group_total_time__r.case__r.IsClosed = true and End_date_time_group__c  = null) '+
            			' and case__r.IsClosed =true';
        if(!Test.isRunningTest()){
            Query += ' and case__r.ClosedDate  <= : endDate and case__r.ClosedDate  >: startDate	';//change to date
        }
        system.debug('**Query  '+Query);
        return Database.getQueryLocator(Query);
    }
    
    public void execute(Database.BatchableContext BC, List<case_assigned_group_total_time__c> assignedGroupTotal){
        system.debug('execute AssignedGroupTrackingCloseCaseDataFix');
        List<Case_assigned_group_log_time__c> logsToUpdate = new List<Case_assigned_group_log_time__c>();
        for(case_assigned_group_total_time__c total:assignedGroupTotal){
            Case_assigned_group_log_time__c log;
            for(Case_assigned_group_log_time__c assignedGroupLog:total.Case_assigned_groups_log_time__r){
                if(assignedGroupLog.End_date_time_group__c  == null){
                    log = assignedGroupLog;
                }else if(assignedGroupLog.End_date_time_group__c.date() == assignedGroupLog.Case_assigned_group_total_time__r.case__r.ClosedDate.date()){
                    log = null;
                    break;
                }
            }
            if(log != null){
                log.End_date_time_group__c = log.Case_assigned_group_total_time__r.case__r.ClosedDate;
            	logsToUpdate.add(log);
            }
        }
        system.debug('logsToUpdate size '+logsToUpdate.size());
        system.debug('logsToUpdate '+logsToUpdate);
        update logsToUpdate;
        
    }
    
    
    public void finish(Database.BatchableContext BC){
    }
    

}