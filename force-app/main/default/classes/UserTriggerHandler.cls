public with sharing class UserTriggerHandler {

    public static void UserHandler(Map<id,User> newMap, Map<id,User> oldMap, System.TriggerOperation triggerEvent){
        switch on triggerEvent{
            when AFTER_UPDATE{
               UserTriggerHelper.rolesInTheUserWereUpdated(oldMap,newMap);
            }
        }
    }
}