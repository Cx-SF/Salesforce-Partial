public without sharing class ErrorMailSender {
    public static void sendMailOnError(String caseId,String message){
        List<Email_for_receive_errors__mdt> emailForReceiveError=[select email__c from Email_for_receive_errors__mdt];
        String[] toAddresses = new list<string>();
        for(Email_for_receive_errors__mdt em:emailForReceiveError) {
            toAddresses.add(em.email__c);
        }
        if(toAddresses.isEmpty()){
            return;
        }
        Case realtedCase = [SELECT Id, CaseNumber, Status,cc__c,Owner.Name, Account.Name  FROM Case WHERE Id=:caseId LIMIT 1]; 
        String errorMessage = 'Additional info:<br>';
        errorMessage += 'Case number: '+realtedCase.CaseNumber+'<br>';
        errorMessage += 'Case status: '+realtedCase.Status+'<br>';
        errorMessage += 'Case owner: '+realtedCase.Owner.Name+'<br>';
        errorMessage += 'Case account: '+realtedCase.Account.Name+'<br>';
        errorMessage += 'Community user: '+UserInfo.getName()+'<br>';
        errorMessage += 'Error message: '+message+'<br>';
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('Failed to send email from community');
        mail.setSenderDisplayName('Cx SF Admin');
        mail.setHtmlBody(errorMessage);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public static void sendEmail(String subject, String body, list<String> toAddresses){
        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setHtmlBody(body+'<br/><br/>Timestamp: '+Datetime.now());
        
        try{
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }catch(Exception e){}
    }
}