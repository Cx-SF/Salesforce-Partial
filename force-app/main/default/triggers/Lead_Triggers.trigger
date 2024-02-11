trigger Lead_Triggers on Lead (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
    if (!Utils.CodeOff){
        Map <String, TriggerCtrl__c> csmap = TriggerCtrl__c.getall();
        if (!csmap.ContainsKey ('Setting') || csmap.get ('Setting').Lead__c){
            if (trigger.isBefore){
                if (trigger.IsInsert) LeadTriggerHandler.handleBefore (trigger.new, null, 'Insert');
                if (trigger.IsUpdate) LeadTriggerHandler.handleBefore (trigger.new, trigger.oldmap, 'Update');
                if (trigger.IsDelete) LeadTriggerHandler.handleBefore (trigger.old, null, 'Delete');
            }
            if (trigger.isAfter){
                if (trigger.isDelete) LeadTriggerHandler.handleAfter (trigger.old);  else LeadTriggerHandler.handleAfter (trigger.new);
            }       
        }
    }

    LeadTriggerHandler Handler = new LeadTriggerHandler();
    
    // ------------------------------------------------------------------------
    //  ---------------------------- BEFORE EVENTS ----------------------------
    // ------------------------------------------------------------------------
    if (Trigger.isBefore && Trigger.isInsert) // Before Insert
    { 
    }
    /*
    else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
    {
    }
    else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
    {
    }
    */
    // ------------------------------------------------------------------------
    //  ---------------------------- AFTER EVENTS -----------------------------
    // ------------------------------------------------------------------------
    else if (Trigger.isAfter && Trigger.isInsert) // After Insert
    {
    	//Handler.leadAutoCampaignAssigment_AfterInsertUpdate(trigger.new,trigger.newMap,null);
    	//Handler.leadCampaignTeamMemberCreation(trigger.new,trigger.newMap,null);
    }
    else if (Trigger.isAfter && Trigger.isUpdate) // After Update
    {
    	//Handler.leadAutoCampaignAssigment_AfterInsertUpdate(trigger.new,trigger.newMap,trigger.oldMap);
    	//Handler.leadCampaignTeamMemberCreation(trigger.new,trigger.newMap,trigger.oldMap);
    }
    /*
    else if (Trigger.isAfter && Trigger.isDelete) // After Delete
    { 
    }
    else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
    {   
    }
    */
}