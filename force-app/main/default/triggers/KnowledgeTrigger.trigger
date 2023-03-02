trigger KnowledgeTrigger on Knowledge__kav (before insert,before update,before delete, after insert,after update,after delete) {
    system.debug('********');
    
    if (trigger.isupdate) for (Knowledge__kav k : trigger.new)
    {
        system.debug('NEW');
        system.debug(json.serializepretty(trigger.new));
        
        system.debug('OLD');
        system.debug(json.serializepretty(trigger.old));
    }

	
	if (!Utils.CodeOff){
        Map <String, TriggerCtrl__c> csmap = TriggerCtrl__c.getall();
        if (!csmap.ContainsKey ('Setting') || csmap.get ('Setting').Knowledge__c){
            if (trigger.isBefore){
                if (trigger.IsInsert) KnowledgeHandler.handleBefoe (trigger.new, null, 'Insert');
                if (trigger.IsUpdate) KnowledgeHandler.handleBefoe (trigger.new, trigger.oldmap, 'Update');
                if (trigger.IsDelete) KnowledgeHandler.handleBefoe (trigger.old, null, 'Delete');
            }
            if (trigger.isAfter){
                if (trigger.isDelete) KnowledgeHandler.handleAfter (trigger.old);
                else KnowledgeHandler.handleAfter (trigger.new);
            }       
        }
    }

}