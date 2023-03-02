trigger Email_message_Trigger on EmailMessage (before insert, after update, after insert) {

    EmailTriggerHandler handler = new EmailTriggerHandler();
    if (Trigger.isBefore && Trigger.isInsert) // Before Insert
    {
        handler.UpdateCC(Trigger.new); 
        handler.clearImage(Trigger.new);
        //handler.editHtmlBody(Trigger.new);
    } 
    if (Trigger.isBefore && Trigger.isUpdate) {
        handler.UpdateCC(Trigger.new); 
    }
    if (Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert)) {

        PlatformEventService.publishCaseUpdateNotificationEvents_fromEmail(Trigger.new);
    } 

}