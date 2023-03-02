/************************************************************************************** 
Name              : ContactTrigger
Description       : 
Revision History  : 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mendy               09/09/2014                Kfir Cohen             [SW-10307]
****************************************************************************************/
trigger ContactTrigger on Contact (after delete, after insert, after undelete, 
after update, before delete, before insert, before update)
{
    //ContactTriggerHandler handler = new ContactTriggerHandler();  
    // ------------------------------------------------------------------------
    //  ---------------------------- AFTER EVENTS -----------------------------
    // ------------------------------------------------------------------------
    
   /* if (Trigger.isBefore && Trigger.isInsert) // Before Insert
    {
        //handler.CheckDuplicateContact(trigger.new, null);
    }
    else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
    {
        //handler.CheckDuplicateContact(trigger.new, Trigger.oldMap); 
    }*/
    /*
    else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
    {
    }
    */
    // ------------------------------------------------------------------------
    //  ---------------------------- AFTER EVENTS -----------------------------
    // ------------------------------------------------------------------------
    
    //else 
    /*if (Trigger.isAfter && Trigger.isInsert) // After Insert
    {

    }
    elseif (Trigger.isAfter && Trigger.isUpdate) // After Update
    {

    }
    /*else if (Trigger.isAfter && Trigger.isDelete) // After Delete
    {
        
    }
    else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
    {
        
    }
    */
}