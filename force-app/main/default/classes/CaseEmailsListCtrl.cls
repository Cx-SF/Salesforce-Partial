public with sharing class CaseEmailsListCtrl {
	
    @AuraEnabled
    public static void deleteAtt(List<Id> docIdList){
        delete [SELECT Id FROM contentdocument WHERE id IN :docIdList];
    }
    @AuraEnabled
    public static InitDataResponse getCaseEmailMessages(Id caseId) {
        InitDataResponse response = new InitDataResponse();
        List<EmailMessage> emailList = new List<EmailMessage>();
        emailList =  [
                SELECT Id,Parent.Id,Parent.CaseNumber,CreatedDate,FromName,FromAddress,Subject,TextBody,HtmlBody,HasAttachment
                FROM EmailMessage
                WHERE ParentId = :caseId
                ORDER BY CreatedDate DESC
        ];
		response.emailMessageList = emailList;
        response.refId = [SELECT Email_Thread_Id__c FROM CASE WHERE id=: caseId].Email_Thread_Id__c;
        return response;
    }

    @AuraEnabled
    public static String getCase2EmailAddress(String localPart) {
        String res = '';
        EmailServicesAddress email = null;
        List <EmailServicesAddress> lemail = [SELECT EmailDomainName, IsActive, LocalPart FROM EmailServicesAddress WHERE LocalPart = :localPart LIMIT 1];
        if (lemail != null && !lemail.isEmpty()) email = lemail[0];
        if (email != null) res = email.LocalPart+'@'+email.EmailDomainName;
        return res;
    }
    
    @AuraEnabled
    public static void createFeedItemOnAttachmentsUpload(String caseId, List<Map<String, String>> attachData) {
        System.debug(attachData);
        
        if (attachData != null && attachData.size() > 0) {
            try {
                FeedItem post = new FeedItem();
                post.ParentId = caseId;
                post.IsRichText = true; 
                String postBody = '<p>SF Attachment Notification: The file/s below have been uploaded to the case:</p><p>&nbsp;</p>';
                for (Map<String, String> file : attachData) {
                    String fileUrl = URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/document/download/' + file.get('documentId');
                    postBody += '<p><a href="' + fileUrl + '">' + file.get('name') + '</a></p>'; 
                }
                post.Body = postBody;
                insert post;
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }        
    }
	
    @AuraEnabled
    public static string sendMailMethod(String mMail, String cc, String mSubject ,String mbody, String caseId, List<String> attachList, Map<String, Map<String, String>> attachData) {
        try {
        
            String messageId = Cases.generateThreadingMessageId(Id.valueOf(caseId));
            system.debug('TESTING messageId is '+messageId);
            List<Messaging.SingleEmailMessage> mails =  new List<Messaging.SingleEmailMessage>();
    		system.debug('TESTING Creating Email');
            // Step 1: Create a new Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setReferences(CaseId+'@sfdc.net');
            system.debug('TESTING references set to '+mail.references);
    
            // Step 2: Set list of people who should get the email
            List<String> sendTo = new List<String>();
            sendTo.add(mMail);
            List<String> ccEmails = null;
            if (cc != null && cc != '') {
                ccEmails = cc.split(';');
            }
            mail.setToAddresses(sendTo);
            if (ccEmails != null && !ccEmails.isEmpty()) {
                mail.setCcAddresses(ccEmails);
            }
    
            // Step 3: Set who the email is sent from
            //mail.setReplyTo('noreply@gmail.com'); // change it with your mail address.
            mail.setReplyTo(UserInfo.getUserEmail()); // REM 25/09
            mail.setSenderDisplayName(UserInfo.getName());
            //mail.setwhatid(caseid);
    
            // Step 4. Set email contents - you can use variables!
            mail.setSubject(mSubject);
            mail.setHtmlBody(mbody);
    
    
            /*// Add attach
            List<Id> ContentDocumentids = new List<Id>();
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
    
            for (String att : attachList) {
                att = att.toLowerCase();
            }
            System.debug(attachList);
    
            List <ContentDocumentLink> cdLinkList = [SELECT LinkedEntityId, ContentDocumentId,ContentDocument.Title,ContentDocument.FileType,ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId=:caseId];
    
            // we only need files that the user has attached now
            Integer num = 0;
            while (num < cdLinkList.size()) {
                ContentDocumentLink listRow = cdLinkList.get(num);
                System.debug(listRow);
                String fileName = listRow.ContentDocument.Title+'.'+listRow.ContentDocument.FileExtension;
                System.debug(fileName);
                if (attachList.contains(fileName.toLowerCase())){
                    num++;
                } else {
                    cdLinkList.remove(num);
                }
            }
    
            for(ContentDocumentLink CDLink : cdLinkList)
            {
                ContentDocumentids.add(CDLink.ContentDocumentId);
            }
            List<ContentVersion> cVersionList = [
                    SELECT Title,PathOnClient,FileType,VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :ContentDocumentids
            ];
    
            for ( ContentVersion cVersion : cVersionList)
            {
                String fileName = cVersion.Title + '.' + cVersion.FileType.toLowerCase();
    
                    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                    Blob body = cVersion.VersionData;
                    attach.setFileName(fileName);
                    attach.setBody(body);
                    fileAttachments.add(attach);
            }
            mail.setFileAttachments(fileAttachments);*/
    
            /*
            if (attachData != null && attachData.size() > 0) {
                List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
                for (Map<String, String> file : attachData.values()) {
                    for (String fileName : file.keySet()) {
                        String fileData = file.get(fileName);
                        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                        attach.setFileName(fileName);
                        attach.setBody(EncodingUtil.base64Decode(fileData));
                        fileAttachments.add(attach);
                    }  
                }
                mail.setFileAttachments(fileAttachments);
            }
			*/
    
            // Step 5. Add your email to the master list
            mails.add(mail);
            System.debug(mails);
    
            // Step 6: Send all emails in the master list
            Messaging.sendEmail(mails);
    
            // flush only our sended attachments
            //delete cdLinkList;
        
        } catch (Exception e) {
            ErrorMailSender.sendMailOnError(caseId, e.getMessage());
            return e.getMessage();
        }
        return '';
    }
	
  	@AuraEnabled
    public static void sendMailOnError(String caseId,String message){
        ErrorMailSender.sendMailOnError(caseId, message);
    }
    
    
    /*@AuraEnabled
    public static List<ContentDocument> getEmailAttachments(id emailMessageId){
        List<ContentDocument> resultList = new List<ContentDocument>();
        List<ContentDocumentLink> cdLidt = [SELECT Id, ContentDocumentId, IsDeleted, LinkedEntityId, ShareType, SystemModstamp, Visibility FROM ContentDocumentLink WHERE LinkedEntityId=:emailMessageId];
    	Set<Id> docIdSet = new Set<Id>();
        for(ContentDocumentLink cdl : cdLidt){
            docIdSet.add(ContentDocumentId);
        }
        List<ContentVersion> docs = [Select ContentSize, ContentDocumentId, ContentModifiedById, ContentModifiedDate, CreatedById, CreatedBy.Name, Id, Title From ContentVersion WHERE ContentDocumentId IN : docIdSet];
        // Building result list
        for (ContentDocumentLink cdl : cdlChildMap.values()) {
            for (ContentVersion cv : docs) {
                if ( cv.ContentDocumentId == cdl.ContentDocumentId ) {
                    result.add(new AttachmentsWrapper(cdl, cv));
                }
            }
        }
        
    }*/
    
    public class InitDataResponse {
        @auraEnabled
        public List<EmailMessage> emailMessageList ;
        @auraEnabled
        public String refId; 
    }
    
}