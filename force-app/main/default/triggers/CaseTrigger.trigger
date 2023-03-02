trigger CaseTrigger on Case (before insert, before update, after insert,after update, after delete) {
    
    TriggerDispatcher.Run(new CaseTriggerHandler());
}