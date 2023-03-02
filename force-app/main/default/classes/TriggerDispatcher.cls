public with sharing class TriggerDispatcher
{
    public static void Run(ITriggerHandler handler)
    {
        // Check to see if the trigger has been disabled. If it has, return
        if (handler.IsDisabled()){
            return;
        }

        // Detect the current trigger context and fire the relevant methods on the trigger handler:

        switch on Trigger.operationType {
            when BEFORE_INSERT {
                handler.BeforeInsert(Trigger.new);
            } when BEFORE_UPDATE {
                handler.BeforeUpdate(Trigger.new, Trigger.oldMap);
            } when BEFORE_DELETE {
           //       handler.BeforeDelete(Trigger.old, Trigger.oldMap);
            } when AFTER_INSERT {
                handler.AfterInsert(Trigger.new, Trigger.newMap);
            } when AFTER_UPDATE {
                handler.AfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
            } when AFTER_DELETE {
                handler.AfterDelete(Trigger.old, Trigger.oldMap);
            //} when AFTER_UNDELETE {
            //    handler.AfterUndelete(Trigger.new, Trigger.newMap);
            }
        }
    }
}