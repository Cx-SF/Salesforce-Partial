trigger QuoteLineItemTrigger on QuoteLineItem (before insert) {//, before update, after update) {
    //if (Trigger.isBefore) {
        //if (Trigger.isInsert)
            QuoteLineItemHandler.onInsert(Trigger.new);
        //else
            //QuoteLineItemHandler.onUpdate(Trigger.new, Trigger.oldMap);
    //} else {
        //QuoteLineItemHandler.onUpdate(Trigger.new, Trigger.oldMap);
        //QuoteLineItemHandler.afterUpdate(Trigger.new);
    //}
}