trigger CaseComment_Trigger on CaseComment (before insert, after update, after insert, after delete, after undelete ) {

    if (Trigger.isBefore) {

    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            PlatformEventService.publishCaseUpdateNotificationEvents_fromCaseComment(Trigger.new);

        }
    }

}