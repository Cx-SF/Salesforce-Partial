public with sharing class AttachmentsRelatedListCtrl {
    @AuraEnabled
    public static List<AttachmentsWrapper> getAttachmentsForEmail(String parentId ){
        Id accountId = [Select AccountId FROM User WHERE Id=:UserInfo.getUserId()].AccountId;
        List<AttachmentsWrapper> result = new List<AttachmentsWrapper>();
        Set<Id> documentIds = new Set<Id>();
        Set<Id> relatedIds = new Set<Id>();
        Map<Id, ContentDocumentLink> cdlChildMap = new Map<Id, ContentDocumentLink>(); 
        
        for(ContentDocumentLink cdl: [SELECT Id, ContentDocumentId, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility FROM ContentDocumentLink WHERE LinkedEntityId =:parentId ]){
            cdlChildMap.put(cdl.ContentDocumentId, cdl);
        }
        
        documentIds = cdlChildMap.keySet(); // Documents that will be visible in Community
        List<ContentVersion> docs = [Select ContentSize, ContentDocumentId, ContentModifiedById, CreatedDate, CreatedById, CreatedBy.Name,CreatedBy.AccountId, Id, Title,ContentDocument.FileType  From ContentVersion WHERE 
                                     ContentDocumentId IN : documentIds];
        // Building result list
        for (ContentDocumentLink cdl : cdlChildMap.values()) {
            for (ContentVersion cv : docs) {
                if ( cv.ContentDocumentId == cdl.ContentDocumentId ) {
                    
                    result.add(new AttachmentsWrapper(cdl, cv,accountId));
                }
            }
        }
        List<Attachment> attList = [ Select id,LastModifiedDate,CreatedDate,createdBy.Name,createdById,
                                    name,parentId,BodyLength
                                    FROM Attachment WHERE ParentId  =: parentID];
        Set<Id> ownerIdSet = new Set<Id>();
        for(Attachment att: attList){
            ownerIdSet.add(att.createdById);
        }
        Map<Id,User> attOwnerMap = new Map<Id,User>([SELECT AccountId FROM USER WHERE ID IN:ownerIdSet ]);
        
        for(Attachment att: attList){
            User usr = attOwnerMap.get(att.CreatedById);
            String accId = usr != null ?  usr.AccountId : null;
            result.add(new AttachmentsWrapper(att,accId,accountId));
        }
        return result;
    }
    
    @AuraEnabled
    public static List<AttachmentsWrapper> getAttachments(String parentId ){
        Id AccountId = [Select AccountId FROM User WHERE Id=:UserInfo.getUserId()].AccountId;
        List<AttachmentsWrapper> result = new List<AttachmentsWrapper>();
        Set<Id> documentIds = new Set<Id>();
        Set<Id> relatedIds = new Set<Id>();
        // Maps for filtering Attachments shown in Community
        Map<Id, ContentDocumentLink> cdlChildMap = new Map<Id, ContentDocumentLink>(); // Attachments to cases
        Map<Id, ContentDocumentLink> cdlMailMap = new Map<Id, ContentDocumentLink>(); // Attachments to mails (inbound + outbound)
        Map<Id, ContentVersion> cvPostMap = new  Map<Id, ContentVersion>(); // Attachments to posts
        // Populating sets and Maps
        for(FeedItem fi: FeedItemGetter.getFeedItems(parentId)){
            relatedIds.add(fi.RelatedRecordId);
        }
        for(ContentDocumentLink cdl: [SELECT Id, ContentDocumentId, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (Select Id from EmailMessage where ParentId =: parentID) ]){
            cdlMailMap.put(cdl.ContentDocumentId, cdl);
        }
        for(ContentDocumentLink cdl: [Select Id, ContentDocumentId, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility From ContentDocumentLink WHERE LinkedEntityId =: parentID ]){
            cdlChildMap.put(cdl.ContentDocumentId, cdl);
        }
        for(ContentVersion cv: [select ContentSize,CreatedBy.AccountId, ContentDocumentId, ContentModifiedById, createdDate,ContentDocument.FileType,
                                CreatedById, CreatedBy.Name, Id, Title from ContentVersion where Id in :relatedIds]){
                                    cvPostMap.put(cv.ContentDocumentId, cv);
                                }
        // Building list without duplicates     
        for(ContentDocumentLink cdl: cdlMailMap.values()){
            if (!cdlChildMap.containsKey(cdl.ContentDocumentId)){
                cdlChildMap.put(cdl.ContentDocumentId, cdl);
            }
        }
        // Eliminating attahchments to Posts (which must be invisible in Community)
        if(accountId!=null){
            for(Id cvId : cvPostMap.keyset()){
                if (cdlChildMap.containsKey(cvId)){
                    cdlChildMap.remove(cvId);
                }
            } 
        }
        
        documentIds = cdlChildMap.keySet(); // Documents that will be visible in Community
        List<ContentVersion> docs = [Select ContentSize, ContentDocumentId, ContentModifiedById, 
                                     CreatedDate, CreatedById, CreatedBy.Name,CreatedBy.AccountId, Id, Title,ContentDocument.FileType  From ContentVersion WHERE ContentDocumentId IN : documentIds];
        // Building result list
        for (ContentDocumentLink cdl : cdlChildMap.values()) {
            for (ContentVersion cv : docs) {
                if ( cv.ContentDocumentId == cdl.ContentDocumentId ) {
                    
                    result.add(new AttachmentsWrapper(cdl, cv,accountId));
                }
            }
        }
        Set<Id> parentIdSetReadOnly =new Map<Id,EmailMessage>([Select Id from EmailMessage where ParentId =: parentID]).keySet();
        Set<Id> parentIdSet = new Set<Id>();
        parentIdSet.addAll(parentIdSetReadOnly);
        //if not community - add case attachments
        if(accountId==null){
           parentIdSet.add(parentID);  
        }
        List<Attachment> attList = [ Select id,CreatedDate,createdBy.Name,createdById,name,parentId,BodyLength
                                    FROM Attachment WHERE ParentId IN :parentIdSet];
        Set<Id> ownerIdSet = new Set<Id>();
        for(Attachment att: attList){
            ownerIdSet.add(att.createdById);
        }
        Map<Id,User> attOwnerMap = new Map<Id,User>([SELECT AccountId FROM USER WHERE ID IN:ownerIdSet ]);
        
        for(Attachment att: attList){
            User usr = attOwnerMap.get(att.CreatedById);
            String accId = usr != null ?  usr.AccountId : null;
            result.add(new AttachmentsWrapper(att,accId,accountId));
        }
        /* Old code
                    List<ContentDocumentLink> links =   [Select Id,
                    ContentDocumentId,
                    IsDeleted,
                    LinkedEntityId,
                    ShareType,
                    SystemModstamp,
                    Visibility
                    From ContentDocumentLink WHERE LinkedEntityId =: parentID ];
                    
                    for (ContentDocumentLink l : links) {
                    documentIds.add(l.ContentDocumentId);
                    }
                    
                    List<ContentVersion> docs = [Select ContentSize, ContentDocumentId, ContentModifiedById, ContentModifiedDate, CreatedById, CreatedBy.Name, Id, Title From ContentVersion WHERE ContentDocumentId IN : documentIds];
                    
                    for (ContentDocumentLink l : links) {
                    for (ContentVersion cv : docs) {
                    if ( cv.ContentDocumentId == l.ContentDocumentId ) {
                    result.add(new AttachmentsWrapper(l, cv));
                    }
                    }
                    }
        */
        return result;
    }
    
    public class AttachmentsWrapper {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public Integer size { get; set; }
        
        @AuraEnabled
        public String createdByName { get; set; } 
        @AuraEnabled
        public String createdById { get; set; } 
        @AuraEnabled
        public String parentId { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public DateTime createdDate { get; set; }
        @AuraEnabled
        public String downloadUrl { get; set; }
        
        public AttachmentsWrapper (ContentDocumentLink cdl, ContentVersion cv,Id accountId) {
            this.id  = cdl.ContentDocumentId;           
            this.size  = cv.ContentSize;            
            this.createdDate  = cv.CreatedDate;         
            this.createdByName  = cv.CreatedBy.AccountId!=null ?  cv.CreatedBy.Name : 'Checkmarx Support';          
            this.createdById  = cv.CreatedById;         
            this.parentId  = cdl.LinkedEntityId;            
            this.title  = cv.Title;
            this.type = cv.ContentDocument.FileType;
            if(accountId!=null){
                this.downloadUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/CheckmarxCustomerServiceCommunity/sfc/servlet.shepherd/document/download/'+cdl.ContentDocumentId;
            } else {
                this.downloadUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/sfc/servlet.shepherd/document/download/'+cdl.ContentDocumentId;
                
            }
        }
        public AttachmentsWrapper (Attachment att,String accId,Id accountId) {
            this.id  = att.Id;          
            this.size  = att.BodyLength;            
            this.createdDate  = att.CreatedDate;            
            this.createdByName  = accId!=null ? att.CreatedBy.Name : 'Checkmarx Support';           
            this.createdById  = att.CreatedById;            
            this.parentId  = att.parentId;          
            this.title  = att.Name;
            if(att.Name!=null && att.Name.Contains('.')){
                this.type= att.Name.substringAfter('.');
            }
            if(accountId!=null){
                this.downloadUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/CheckmarxCustomerServiceCommunity/servlet/servlet.FileDownload?file='+att.Id;            } 
            else {
                this.downloadUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.FileDownload?file='+att.Id;
            }
            

        }
    }
}