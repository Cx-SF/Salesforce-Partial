trigger Healthcheck_Trigger on CSM__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if (trigger.isBefore){
        if (trigger.isInsert){
        }
        if (trigger.isUpdate){
        }
    }
    
    if (trigger.isAfter){
      if (trigger.isInsert){
        Healthcheck_LaunchCloneFlow.Healthcheck_LaunchCloneFlow(trigger.new,trigger.oldMap);
      }
      if (trigger.isUpdate){
        Healthcheck_LaunchCloneFlow.Healthcheck_LaunchCloneFlow(trigger.new,trigger.oldMap);
      }
    }
}