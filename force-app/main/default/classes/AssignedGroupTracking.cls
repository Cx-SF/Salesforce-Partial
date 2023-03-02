public without sharing class AssignedGroupTracking {
    
    /*
hierarchy : Case->Case Assigned group total->case assigned group log time
Case Assigned group total is child of case
case assigned group log time is child of Case Assigned group total
*/
    
    static DateTime completionDate;
    public static void AssignedGroupIsChange(List<Case> updatedCases,Map<Id,SObject> oldMapCase){
        completionDate = System.now();
        for(Case c:updatedCases){
            Case oldCase= (Case)oldMapCase.get(c.Id);
            if(c.Assigned_group__c!=oldCase.Assigned_group__c){
                system.debug('oldCase.Id:'+oldCase.Id +' oldCase.Assigned_group__c:'+oldCase.Assigned_group__c);
                List<Case_assigned_group_total_time__c> old_assigned_group_total_time=[SELECT Assigned_group__c, Case__c, Id FROM Case_assigned_group_total_time__c 
                                                                                       where Case__c=:c.Id and Assigned_group__c=:oldCase.Assigned_group__c];
                List<Case_assigned_group_total_time__c> new_assigned_group_total_time=[SELECT Assigned_group__c, Case__c, Id FROM Case_assigned_group_total_time__c 
                                                                                       where Case__c=:c.Id and Assigned_group__c=:c.Assigned_group__c];
                if(old_assigned_group_total_time.size()>0)
                {
                    List<Case_assigned_group_log_time__c> old_assigned_group_log_time=[SELECT Id, Total_current_group_time__c, Case_assigned_group_total_time__c, 
                                                                                       End_date_time_group__c, Start_date_time_group__c 
                                                                                       FROM Case_assigned_group_log_time__c 
                                                                                       where Case_assigned_group_total_time__c=:old_assigned_group_total_time[0].Id
                                                                                       Order by Start_date_time_group__c desc];
                    if(old_assigned_group_log_time.size()>0)
                    {
                        old_assigned_group_log_time[0].End_date_time_group__c=completionDate;
                        update old_assigned_group_log_time[0];
                    }
                    
                }
                if(new_assigned_group_total_time.size()==0)
                {
                    Case_assigned_group_total_time__c new_assigned_group_total=new Case_assigned_group_total_time__c();
                    new_assigned_group_total.Assigned_group__c=c.Assigned_group__c;
                    new_assigned_group_total.Case__c=c.Id;
                    insert new_assigned_group_total;
                    new_assigned_group_total_time.add(new_assigned_group_total);
                }
                system.debug('new_assigned_group_total_time.size():'+new_assigned_group_total_time.size());
                if(new_assigned_group_total_time[0]!=null)
                {
                    Case_assigned_group_log_time__c new_assigned_group_log_time=new Case_assigned_group_log_time__c();
                    new_assigned_group_log_time.Case_assigned_group_total_time__c=new_assigned_group_total_time[0].Id;
                    new_assigned_group_log_time.Start_date_time_group__c=completionDate;
                    insert new_assigned_group_log_time;
                    
                }
                
            }
        }
        
    }
    
    public static void AssignedGroupForNewCase(List<Case> newCase){
        completionDate = System.now();
        for(case c:newCase){
            if(c.Assigned_group__c!=null){
                Case_assigned_group_total_time__c new_assigned_group_total_time=new Case_assigned_group_total_time__c();
                new_assigned_group_total_time.Assigned_group__c=c.Assigned_group__c;
                new_assigned_group_total_time.Case__c = c.Id;
                
                insert new_assigned_group_total_time;
                
                Case_assigned_group_log_time__c new_assigned_group_log_time=new Case_assigned_group_log_time__c();
                new_assigned_group_log_time.Case_assigned_group_total_time__c=new_assigned_group_total_time.Id;
                new_assigned_group_log_time.Start_date_time_group__c=completionDate;
                insert new_assigned_group_log_time;
            }
        }
    }

    
    public static void CaseClosed(List<Case> updatedCases, Map<Id,SObject> oldMapCase){
        completionDate = System.now();

        list<Case_assigned_group_log_time__c> assignedGroupLogToUpdateList = new list<Case_assigned_group_log_time__c>();
        for(Case updatedCase : updatedCases){
            Case oldCase= (Case)oldMapCase.get(updatedCase.Id);
            if(updatedCase.IsClosed && !oldCase.IsClosed){
                 List<Case_assigned_group_total_time__c> assigned_group_total_time = [SELECT Assigned_group__c, Case__c, Id FROM Case_assigned_group_total_time__c
                                                                                      WHERE Case__c=:updatedCase.Id AND Assigned_group__c=:updatedCase.Assigned_group__c];
               
                 if(assigned_group_total_time.size() > 0 ) {
                    List<Case_assigned_group_log_time__c> assigned_group_log_time = [SELECT Id, Total_current_group_time__c, Case_assigned_group_total_time__c,
                                                                                            End_date_time_group__c, Start_date_time_group__c
                                                                                     FROM Case_assigned_group_log_time__c
                                                                                     WHERE Case_assigned_group_total_time__c=:assigned_group_total_time[0].Id
                                                                                     Order by Start_date_time_group__c desc];
                    if(assigned_group_log_time.size() > 0)
                    {
                        assignedGroupLogToUpdateList.add(new Case_assigned_group_log_time__c(Id = assigned_group_log_time[0].Id, End_date_time_group__c = completionDate));
                        
                    }    
                }
            }
        }
       if (assignedGroupLogToUpdateList.size() > 0) update assignedGroupLogToUpdateList;
    }
}