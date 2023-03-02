@IsTest
public with sharing class AttachmentsRelatedListCtrlTest {
    @IsTest
    public static void testgetAttachments() {
        Test.startTest();
        Case testCase = new Case();
        insert testCase;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Penguins',
            PathOnClient = 'Penguins.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = testCase.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
        Attachment attach=new Attachment();   	
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=testCase.id;
        insert attach;
        
        AttachmentsRelatedListCtrl.getAttachments(testCase.Id);
        AttachmentsRelatedListCtrl.getAttachmentsForEmail(testCase.Id);
        Test.stopTest();
        
    }
}