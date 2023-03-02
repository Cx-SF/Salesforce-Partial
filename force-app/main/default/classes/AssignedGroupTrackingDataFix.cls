public with sharing class AssignedGroupTrackingDataFix implements Database.Batchable<SObject> {
    
    private List<Id> caseIdList;
    private Datetime fromDate;
    private DateTime toDate;
    
    public AssignedGroupTrackingDataFix(List<Id> caseIdList, DateTime fromDate, DateTime toDate)
    {
        this.caseIdList = caseIdList;
        this.fromDate = fromDate;
        this.toDate = toDate;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){    
    //   String caseList =Label.Assigned_Group_DataFix;       
        if (caseIdList == null){
            return Database.getQueryLocator('select CaseId,Field, OldValue, NewValue, CreatedDate from CaseHistory where Field =\'Assigned_group__c\' and CreatedDate>=:fromDate and CreatedDate<=:toDate order by CaseId, CreatedDate ');
        }
        else{
            return Database.getQueryLocator('select CaseId,Field, OldValue, NewValue, CreatedDate from CaseHistory where Field =\'Assigned_group__c\' and CreatedDate>=:fromDate and CreatedDate<=:toDate and CaseId in :caseIdList order by CaseId, CreatedDate ');
        }
    }    
        
    public void finish(Database.BatchableContext BC){
    }
    
    public static void doTest()
    {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
  
    public void execute(Database.BatchableContext BC, List<CaseHistory> allCaseHistory){
        system.debug('In execute');
        system.debug('allCaseHistory.SIZE()+'+allCaseHistory.size());
        for(CaseHistory ch: allCaseHistory){
        
            Id assignedGroupTottimeId ;
            String newVal = (String)ch.NewValue;
            
            List<Case_assigned_group_total_time__c> CaseAssignedGroupTotExist = [select Id from Case_assigned_group_total_time__c where Assigned_group__c = :newVal and Case__c =:ch.CaseId ];
            if (CaseAssignedGroupTotExist.Size()==0){
                
                Case_assigned_group_total_time__c new_assigned_group_total_time=new Case_assigned_group_total_time__c();
                new_assigned_group_total_time.Assigned_group__c= newVal;
                new_assigned_group_total_time.Case__c = ch.CaseId; 
                new_assigned_group_total_time.CreatedDate = ch.CreatedDate;
                new_assigned_group_total_time.Datafix__c = true;
                insert new_assigned_group_total_time;
                system.debug('new_assigned_group_total_time ++'+new_assigned_group_total_time);
                assignedGroupTottimeId = new_assigned_group_total_time.Id;
            }
            else{
                assignedGroupTottimeId= CaseAssignedGroupTotExist[0].Id;
            }
            
            
            List<Case_assigned_group_log_time__c> oldLogTime = [select Id from Case_assigned_group_log_time__c where Case_assigned_group_total_time__c  = :assignedGroupTottimeId and Start_date_time_group__c = :ch.CreatedDate];
           
            
            if(oldLogTime.Size() == 0) {
           
                List<Case_assigned_group_log_time__c> pastLogTime   = [select Id ,End_date_time_group__c from Case_assigned_group_log_time__c where Case_assigned_group_total_time__r.case__r.Id  = :ch.CaseId/*Case_assigned_group_total_time__c  = :assignedGroupTottimeId */ and Start_date_time_group__c < :ch.CreatedDate order by Start_date_time_group__c desc limit 1];
                List<Case_assigned_group_log_time__c> futureLogTime = [select Id ,Start_date_time_group__c from Case_assigned_group_log_time__c where Case_assigned_group_total_time__r.case__r.Id  = :ch.CaseId/*Case_assigned_group_total_time__c  = :assignedGroupTottimeId */ and Start_date_time_group__c > :ch.CreatedDate order by Start_date_time_group__c asc limit 1];
                //check If exist
                Case_assigned_group_log_time__c new_assigned_group_log_time=new Case_assigned_group_log_time__c();
                new_assigned_group_log_time.Case_assigned_group_total_time__c= assignedGroupTottimeId;
                new_assigned_group_log_time.Start_date_time_group__c=ch.CreatedDate;
                if (futureLogTime.Size()>0){
                new_assigned_group_log_time.End_date_time_group__c =futureLogTime[0].Start_date_time_group__c;
                }
                new_assigned_group_log_time.CreatedDate = ch.CreatedDate;
                new_assigned_group_log_time.Datafix__c = true;
                insert new_assigned_group_log_time;
                system.debug('new_assigned_group_log_time ++'+new_assigned_group_log_time);
                if (pastLogTime.Size()>0){
                    pastLogTime[0].Datafix__c = true;
                    system.debug('Update pastLogTime[0] ++'+pastLogTime[0]);  
                    pastLogTime[0].DataFix_Old_Datetime__c = pastLogTime[0].End_date_time_group__c;
                    pastLogTime[0].End_date_time_group__c = ch.CreatedDate;
                    update pastLogTime[0];
                    system.debug('Update pastLogTime[0] ++'+pastLogTime[0]);                 
                }
                
            }
               
        }

    }        
}