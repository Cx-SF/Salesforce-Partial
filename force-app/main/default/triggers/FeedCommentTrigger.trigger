trigger FeedCommentTrigger on FeedComment (before insert, before update, before delete, after insert, after update, after delete, after undelete)  {
	
	if (!Utils.CodeOff){
        Map <String, TriggerCtrl__c> csmap = TriggerCtrl__c.getall();
        if (!csmap.ContainsKey ('Setting') || csmap.get ('Setting').feed_comment__c){
            if (trigger.isBefore){
                if (trigger.IsInsert) FeedCommentHandler.handleBefore (trigger.new, null, 'Insert');
                if (trigger.IsUpdate) FeedCommentHandler.handleBefore (trigger.new, trigger.oldmap, 'Update');
                if (trigger.IsDelete) FeedCommentHandler.handleBefore (trigger.old, null, 'Delete');
            }
            if (trigger.isAfter){
                if (trigger.isDelete) FeedCommentHandler.handleAfter (trigger.old);  else FeedCommentHandler.handleAfter (trigger.new);
            }       
        }
    }

}