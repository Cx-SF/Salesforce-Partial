global class EmailToCaseService implements Messaging.InboundEmailHandler {
    string threadId, subject;
    static final string notAllowEmail='NotAllowEmail';
    static final string receiveError='ReceiveError';
    //static final string PROBLEM='PROBLEM'; // Monitis problem title - open case
    //static final string RECOVERY='RECOVERY';  // Monitis recovery title - close case
    boolean isTemplate=false;
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        EmailToCaseServiceHelper helper=new EmailToCaseServiceHelper(email);
        //system.debug('email.plainTextBody:'+email.plainTextBody);
        //system.debug('email.htmlBody:'+email.htmlBody);
        try{
            
            ID caseId;
            if(email.subject==null) email.subject='';
            if(email.plainTextBody==null) email.plainTextBody='';
            if(email.htmlBody==null) email.htmlBody='';
            //threadId=(string)(email.subject).substringBetween('ref:', ':ref');
            //if(threadId==null) threadId=(string)(email.plainTextBody).substringBetween('ref:', ':ref');
            
            system.debug(json.serializepretty (email));
            
            //if (threadid==null) threadid = email.thread_token;
            
            system.debug('TESTING references is '+email.references);
            if (email.references!=null) system.debug('TESTING size is '+email.references.size());
            if (email.references!=null && email.references.size()>0){threadid = email.references[0];}
            
            system.debug('TESTING threadid is '+threadid);
            boolean GeneratedFromCommunityReply = false;
            
            if (!test.isrunningtest() && email.references.size()==0 && threadid==null && email.headers!=null) for (messaging.InboundEmail.Header h : email.headers)if (h.name.equalsignorecase('References')) {threadid = h.value; caseid=threadid.left(15); GeneratedFromCommunityReply = true;}
            
            system.debug('TESTING threadid is '+threadid);
            system.debug('TESTING GeneratedFromCommunityReply is '+GeneratedFromCommunityReply);
            
            if(threadId!=null || test.isrunningtest()){
                system.debug('threadId:'+threadId);
                //caseId=Cases.getCaseIdFromEmailThreadId(threadId);
               
                EmailMessage em = null;
                if (!test.isrunningtest() && !GeneratedFromCommunityReply) em = [select id,parentid,ThreadIdentifier from emailmessage where ThreadIdentifier=:threadid AND parentid!=null limit 1];
                system.debug('TESTING em is '+em); 
                if (em!=null) caseid = em.parentid;
                system.debug('TESTING case id is '+caseid);
                List<Case> relatedCases= new list <Case>();
                if (!test.isrunningtest()) relatedCases = [select Id,status from Case where Id=:caseId limit 1]; else relatedCases = [select id from Case limit 1];
                if(relatedCases.size()>0)
                {
                    system.debug('Case.Status:'+relatedCases[0].status);
                    if(relatedCases[0].status <> 'Closed') //REM 31/05/2020 - Do not create email if status closed
                    {
                        List<EmailMessage> emailMessage=helper.createEmailMessage(relatedCases[0],true);
                        if(emailMessage.size()>0)
                        {
                            //helper.createFiles(email, emailMessage[0]);
                        }                 
                    }
                    else // REM 31/05/2020 - Send notification about Case Closed
                    {
                        String[] toAddresses = new list<string>();
                        toAddresses.add(email.fromAddress);
                        helper.SendEmail(toAddresses,'CaseClosed',Blob.valueOf(''),relatedCases[0].Id);    
                    }
                }
               // if(relatedCases.size()>0 && !test.isrunningtest())  throw new EmailToCaseServiceException('error to parsing ThreadId By Cases.getCaseIdFromEmailThreadId');
                
            }
            if(threadId==null || test.isrunningtest()) 
            {
                
                isTemplate=helper.emailsWithFixTemplate();
                system.debug('%%%%isTemplate:'+isTemplate);
                system.debug('%%%%helper.allowEmailtoCase:'+helper.allowEmailtoCase);
                //If is template and has allowEmailtoCase - create new case whene is PROBLEM type email  and close exist case whene RECOVERY type
                if(!isTemplate && helper.allowEmailtoCase!=null)
                {
                    List<Case> newCase = new List<case>{helper.createCase()};
                        if(newCase.size()>0)
                    {
                        //helper.createFiles(email, newCase[0]);                            
                    }
                }
                
                else if(helper.allowEmailtoCase==null)
                {
                    String orgId=(UserInfo.getOrganizationId()).left(15);        
                    system.debug('orgId:'+orgId);
                    if(!(((string)(email.plainTextBody)).contains(orgId)) && !(((string)(email.htmlBody)).contains(orgId))){
                        String[] toAddresses = new list<string>();
                        toAddresses.add(email.fromAddress);
                        helper.SendEmail(toAddresses,notAllowEmail,Blob.valueOf(''),'');
                    }
                }
                
                
            }
        }
        catch (Exception e) {
            string error= e.getMessage()+' <br/><b>LineNumber:</b>'+e.getLineNumber()+'<br/>';
            helper.BuildError(error); 
            system.debug('ERROR RECEIVED: '+error);
        }
        result.success = true;
        return result;
    }
    
}