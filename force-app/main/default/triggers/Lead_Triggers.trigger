trigger Lead_Triggers on Lead (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
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
    	Handler.leadCampaignTeamMemberCreation(trigger.new,trigger.newMap,null);
    }
    else if (Trigger.isAfter && Trigger.isUpdate) // After Update
    {
    	//Handler.leadAutoCampaignAssigment_AfterInsertUpdate(trigger.new,trigger.newMap,trigger.oldMap);
    	Handler.leadCampaignTeamMemberCreation(trigger.new,trigger.newMap,trigger.oldMap);
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