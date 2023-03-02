trigger HourReportTrigger on Hour_Report__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
 
    
    HourReportHandler handler = new HourReportHandler();
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
        handler.calculateNewHoursUsedOnInsert(trigger.new);
    }
    
    else if (Trigger.isAfter && Trigger.isUpdate) // After Update
    {
        handler.calculateNewHoursUsedOnUpdate(trigger.new,trigger.oldMap);
    }
    
    else if (Trigger.isAfter && Trigger.isDelete) // After Delete
    
    { 
        handler.calculateNewHoursUsedOnDelete(trigger.old);
    }
    /*
    else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
    {   
    }
      */
}