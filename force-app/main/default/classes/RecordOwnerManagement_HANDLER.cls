public class RecordOwnerManagement_HANDLER 
{
    public static map <id,Records_Owner_Management__c> OldMap = new map <id,Records_Owner_Management__c>();
    public static string event = null;
    
    
    
    public static void HandleBefore (list <Records_Owner_Management__c> ROMList , map <id,Records_Owner_Management__c> OldTriggerMap, string evnt)
    {
        if (evnt!=null) event = evnt;
        if(OldTriggerMap!=null) OldMap = OldTriggerMap;
    }
    
    public static void HandleAfter (list <Records_Owner_Management__c> ROMList)
    {
        
    }

}