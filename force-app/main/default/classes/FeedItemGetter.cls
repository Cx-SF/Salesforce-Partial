public without sharing class FeedItemGetter {
    public static List<FeedItem> getFeedItems(Id parentId){
        return [SELECT Id, RelatedRecordId FROM FeedItem where ParentId =: ParentId];
    }
}