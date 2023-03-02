trigger RecordOwnerManagementTrigger on Records_Owner_Management__c (before insert, before update, before delete, after insert, after update, after delete, after undelete)  {
	
	if (!Utils.CodeOff){
        Map <String, TriggerCtrl__c> csmap = TriggerCtrl__c.getall();
        if (!csmap.ContainsKey ('Setting') || csmap.get ('Setting').Record_Owner_Management__c){
            if (trigger.isBefore){
                if (trigger.IsInsert) RecordOwnerManagement_HANDLER.handleBefore (trigger.new, null, 'Insert');
                if (trigger.IsUpdate) RecordOwnerManagement_HANDLER.handleBefore (trigger.new, trigger.oldmap, 'Update');
                if (trigger.IsDelete) RecordOwnerManagement_HANDLER.handleBefore (trigger.old, null, 'Delete');
            }
            if (trigger.isAfter){
                if (trigger.isDelete) RecordOwnerManagement_HANDLER.handleAfter (trigger.old);  else RecordOwnerManagement_HANDLER.handleAfter (trigger.new);
            }       
        }
    }

}