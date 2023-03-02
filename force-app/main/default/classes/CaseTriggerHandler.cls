public class CaseTriggerHandler implements ITriggerHandler
{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    
    public Boolean IsDisabled()
    {
        return TriggerDisabled;
    }
    
    public void BeforeInsert(List<Case> triggerNew) {
       
        Id contactUsRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
        List<Case> contactUsCases = new List<Case>();
        for (Case c : triggerNew) {
            if (c.Origin == 'Contact_Us' && c.RecordTypeId == contactUsRecordTypeId) {
                contactUsCases.add(c);
            }
        }
        if (!contactUsCases.isEmpty()) {
            List<Case_Record_Type_Detail__mdt> md = [
                SELECT AccountId__c 
                  FROM Case_Record_Type_Detail__mdt 
                 WHERE MasterLabel = 'Contact Us'];
            String accountId = null;
            if (md.size() > 0) {
                accountId = md[0].AccountId__c;
            }
            if (accountId != null) {
                for (Case c : contactUsCases) {
                    c.AccountId = accountId;
                }
            }
        }
    }
    
    
    
    //public void BeforeDelete(List<SObject> triggerOld, Map<Id, SObject> triggerOldMap) {}
    
    public void AfterInsert(List<SObject> triggerNew, Map<Id, SObject> triggerNewMap) {
        AssignedGroupTracking.AssignedGroupForNewCase(triggerNew);
    }
    
    public void AfterUpdate(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        PlatformEventService.publishCaseUpdateNotificationEvents_fromCase(triggerNew);
		CompleteMilestoneHandler.DefineListforComplete(triggerNew, triggerOldMap);
        AssignedGroupTracking.AssignedGroupIsChange(triggerNew, triggerOldMap);
        AssignedGroupTracking.CaseClosed(triggerNew, triggerOldMap);
    }
    
    public void AfterDelete(List<SObject> triggerOld, Map<Id, SObject> triggerOldMap) {
        PlatformEventService.publishCaseUpdateNotificationEvents_fromCase(triggerOld);
    }


    public void BeforeUpdate(List<SObject> triggerNew,  Map<Id, SObject> triggerOldMap) {
        Map<Id,Case> caseOldMap = (Map<Id,Case>)triggerOldMap;
        for(Case c : (List<Case>)triggerNew){
            if(c.Status != caseOldMap.get(c.Id).Status){
                c.Status_Change_Date__c = Date.today();
            }
             system.debug('****c.Status_Change_Date__c: '+c.Status_Change_Date__c);
        }
        system.debug('****triggerNew: '+triggerNew);
    }
    
    //public void AfterUndelete(List<SObject> triggerNew, Map<Id, SObject> triggerNewMap) {}
}