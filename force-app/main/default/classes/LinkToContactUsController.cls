public with sharing class LinkToContactUsController {
    
    @AuraEnabled
    public static String getOrgId() {
        return UserInfo.getOrganizationId();
    }
    
    @AuraEnabled
    public static String getOrgDomain() {
        
        return URL.getSalesforceBaseUrl().toExternalForm();
        
    }
    @AuraEnabled
    public static String getDomain() {
        String myUrl= [Select URL_Value__c From Environment_URLs__mdt Where URL_Type__c = 'Web To Case URL'].URL_Value__c;
        return myUrl;
    }
    
    
    @AuraEnabled
    public static String getRecorTypeId(string recordTypeName) {
        /*
        List<recordtype> recordTypeList= [select id from recordtype where name=:recordTypeName and SobjectType='Case' and IsActive=true];
        if(recordTypeList.size()>0){
            string recordTypeId=recordTypeList[0].Id;
            return recordTypeId.left(15);
        }
        else
            return null;
        */
        return Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
    }
    
    @AuraEnabled
    public static String getAccountId(string recordTypeName) {
        List<Case_Record_Type_Detail__mdt> AcocuntList = [select AccountId__c from Case_Record_Type_Detail__mdt where DeveloperName=:recordTypeName];
        if(AcocuntList.size()>0){
            string AccountId=AcocuntList[0].AccountId__c;
            return AccountId.left(15);
        }
        else
            return null;
    }
    
    @AuraEnabled
    public static String sendEmail(String body) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        List<Email_Adresses_contact_us__mdt> emailForReceive=[select Email__c from Email_Adresses_contact_us__mdt];
        String[] toAddresses = new list<string>();
        for(Email_Adresses_contact_us__mdt em: emailForReceive) {
            toAddresses.add(em.Email__c);
        }
        message.toAddresses = toAddresses;  
        message.setSubject('Partner Community - Contact Us');
        message.setPlainTextBody(body);
        
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
            return 'the email was sent successfully';
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
            return results[0].errors[0].message;
        }   
    }
    
}