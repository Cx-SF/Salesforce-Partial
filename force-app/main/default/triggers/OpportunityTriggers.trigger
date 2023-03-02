/************************************************************************************** 
Name              : OpportunityTriggers 
Description       : One location to trigger all the triggers related to Opportunity object - OpportunityTriggers
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Dana Furman               07/05/2014          Kfir                   [SW-08799]
2. Mohammad Garrah           03/12/2014          Kfir                   [SW-11335]
3. Mendy                     09/12/2014          Kfir                   [SW-11378]
4. Mohammad Garrah           21/12/2014          Kfir                   [SW-11335]
****************************************************************************************/
trigger OpportunityTriggers on Opportunity (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    OpportunitiesTriggersHendler handler = new OpportunitiesTriggersHendler() ;
    // ------------------------------------------------------------------------
    //  ---------------------------- AFTER EVENTS -----------------------------
    // ------------------------------------------------------------------------
    if (Trigger.isBefore && Trigger.isInsert) // Before Insert
    {
        handler.SetDeliveryAlert(trigger.new,null);
    } 
    else if (Trigger.isBefore && Trigger.isUpdate) // Before Update
    {
        handler.SetDeliveryAlert(trigger.new,trigger.oldMap);        
    }
    /*
    else if (Trigger.isBefore && Trigger.isDelete) // Before Delete
    {
    }
    */
    // ------------------------------------------------------------------------
    //  ---------------------------- AFTER EVENTS -----------------------------
    // ------------------------------------------------------------------------
    /*
    else if (Trigger.isAfter && Trigger.isInsert) // After Insert
    {
    }
    else if (Trigger.isAfter && Trigger.isUpdate) // After Update
    {
    }   
    else if (Trigger.isAfter && Trigger.isDelete) // After Delete
    {
    }
    else if (Trigger.isAfter && Trigger.isUnDelete) // After UnDelete
    {  
    }
    */


}