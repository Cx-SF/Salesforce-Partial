trigger UserTrigger on User (after update) {

    UserTriggerHandler.UserHandler(Trigger.newMap, Trigger.oldMap, Trigger.OperationType);

}