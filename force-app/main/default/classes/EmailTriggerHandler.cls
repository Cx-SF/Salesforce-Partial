public class EmailTriggerHandler {
    
    
    public void UpdateCC(List<EmailMessage> emailMessageList) {
        
        Map<Id, Id> CaseEmail = new  Map<Id, Id>();
        Map<Id, string> caseCC = new  Map<Id, string>();
        for ( EmailMessage em : emailMessageList) {
            
            if( (em.ParentId).getSObjectType() == Schema.Case.getSObjectType() && ! em.Incoming )
                CaseEmail.put(em.Id, em.ParentId); 
        }
        
        List<Case> toUpdateCases = [SELECT Id, cc__c, Contact.email FROM Case where Id in: CaseEmail.values()]; 
        for ( Case ca: toUpdateCases ){
            string toAddress='';
            if(ca.Contact.email!=null && ca.Contact.email!='')
               toAddress=string.valueOf(ca.Contact.email);
            if(ca.cc__c!=null && ca.cc__c!='')
                toAddress+=';'+ca.cc__c;
            caseCC.put(ca.Id,toAddress);
        }
        
        for ( EmailMessage em :emailMessageList) {
            if (! em.Incoming)
            {
                if(CaseEmail.containsKey(em.Id)  ){
                    IF(em.CcAddress == null)
                        em.CcAddress = caseCC.get(CaseEmail.get(em.Id));
                    else
                        em.CcAddress += caseCC.get(CaseEmail.get(em.Id));
                }                
            }                        
        }   
    }
    
    public void clearImage(List<EmailMessage> emailMessageList)
    {
        for( EmailMessage em : emailMessageList){
            //clear image to replay emailmassege
            if(em.ReplyToEmailMessageId!=null && em.incoming==false)
            {    
                em.htmlbody = em.htmlbody.replaceAll('<img[^>]*>','[Image]');
                system.debug('em.htmlbody:'+em.htmlbody);
            }
        }
    }
}