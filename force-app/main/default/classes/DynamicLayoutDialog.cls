@namespaceAccessible
public with sharing class DynamicLayoutDialog {
    
    /******************************************************************************
    Name: DynamicLayoutDialog.apxc
    Description: Apex controller for DynamicLayoutDialog lightning component
    
    Change History:
    
    Name			Date			Comments
    -------------------------------------------------------------------------------
    Alex Levchenko 	27-Mar-2019		Initial version
    
    *******************************************************************************/
    
    @AuraEnabled
    public static String getMetadata(String sObjectName, String recordTypeId, String mode, String recordId, String accountId) {
        return JSON.serialize(DynamicLayoutUtils.getMetadata(sObjectName, recordTypeId, mode, recordId, accountId));
    }
    
    @AuraEnabled
    public static boolean deleteAttachment(String documentId) {
        return DynamicLayoutUtils.deleteAttachment(documentId);
    }

	@AuraEnabled
    public static String getRecordTypeId(String sObjectName, String recordId) {
        return DynamicLayoutUtils.getRecordTypeId(sObjectName, recordId);
    }
    
    @AuraEnabled
    public static boolean deleteContentAttachment(String docId) {
        ContentDocument[] cds = [SELECT Id FROM ContentDocument Where Id = :docId];
        System.debug('Attachments size = ' + cds.size());
        if (cds.size() > 0) {
            delete cds;
            return true;
        }
        return false;
    }
    
    //////////////////////////////////////////
    
    @AuraEnabled
    public static List<Parent_Product_Area__mdt> getParentProductAreaCustomMetadata() {    
    return [SELECT DeveloperName FROM Parent_Product_Area__mdt];
    }
    
    @AuraEnabled
    public static List<API_For_Knowledge_Search__mdt> getApiForKnowledgeSearchCustomMetadata() {    
    return [SELECT DeveloperName,Product_Area_API__c,Product_Area_DC_API__c FROM API_For_Knowledge_Search__mdt];
    }
}