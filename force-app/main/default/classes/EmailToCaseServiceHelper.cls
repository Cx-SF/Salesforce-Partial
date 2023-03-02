public class EmailToCaseServiceHelper {
    //Test class: EmailToCaseServiceTest
    public Messaging.InboundEmail email;
    static final string notAllowEmail='NotAllowEmail';
    static final string receiveError='ReceiveError';
    static final string PROBLEM='PROBLEM';
    static final string RECOVERY='RECOVERY'; 
    static final string StatusClosed='Closed'; 
    //string monitisType,nagiosType,upType; // Add 30/Nov, Liron
    string typeTemplate; // Add 27/Dec, MS
    Integer lengthOfTextBody,lengthOfHtmlBody,lengthOfCaseDescription;
    public enum fileType {txt, html}
    
    public Allow_Email_to_Case__mdt allowEmailtoCase{set;get;}
    public List<Email_To_Case_Setting__mdt> emailToCaseSetting{set;get;}
    public Map<String,String> emailToCaseSettingMap=new Map <String,String>();
    
    public EmailToCaseServiceHelper(Messaging.InboundEmail email){
        this.email=email;
        this.emailToCaseSetting=[SELECT QualifiedApiName, Value__c FROM Email_To_Case_Setting__mdt];
        for(Email_To_Case_Setting__mdt emailToCaseSet:emailToCaseSetting){
            emailToCaseSettingMap.put(emailToCaseSet.QualifiedApiName,emailToCaseSet.Value__c);
        }
        
        Schema.DescribeFieldResult  TextBodyDescribe= EmailMessage.TextBody.getDescribe();
        Schema.DescribeFieldResult HtmlBodyDescribe = EmailMessage.HtmlBody.getDescribe();
        Schema.DescribeFieldResult DescriptionDescribe = Case.Description.getDescribe();
        
        lengthOfTextBody = TextBodyDescribe.getLength();
        lengthOfHtmlBody = HtmlBodyDescribe.getLength();
        lengthOfCaseDescription=DescriptionDescribe.getLength();
    }
    
    public void SendEmail(String[] sendtoEmail,string emailType,Blob mess,string CaseId) {       
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = sendtoEmail;  
        
        if(emailType==notAllowEmail){
            if(emailToCaseSettingMap.get('EmailTemplateNotAllow')!=null){
                string EmailTemplateNotAllow=emailToCaseSettingMap.get('EmailTemplateNotAllow') ;
                EmailTemplate templateId=[Select id from EmailTemplate where name =: EmailTemplateNotAllow limit 1];
                Id user_id;
                user_id =UserInfo.getUserId();
                message.setTemplateId(templateId.Id);
                message.setTargetObjectId(user_id);
            }
        }
        
        if(emailType=='CaseClosed'){ //REM 31/05/2020 - Notify the sender the Case is closed
            if(emailToCaseSettingMap.get('Email_Template_Case_Closed')!=null){
                string EmailTemplateCaseClosed = emailToCaseSettingMap.get('Email_Template_Case_Closed') ;
                EmailTemplate templateId=[Select id from EmailTemplate where name =: EmailTemplateCaseClosed limit 1];
                Case CaseDetails=[Select ContactId from Case where Id =: CaseId limit 1];
                //Id user_id;
                //user_id = UserInfo.getUserId();
                message.setTreatTargetObjectAsRecipient(false);
                message.setTemplateId(templateId.Id);
                message.setTargetObjectId(CaseDetails.ContactId);
                message.setWhatId(CaseId);
            }
        }
        
        if(emailType==receiveError){
            message.setSubject('Error From Email To Case Service');
            message.setHtmlBody('<p dir="ltr">'+mess.toString()+'</p>');
        }
        
        List<OrgWideEmailAddress> owa;
        string OrgWideCheckmarxSupport;
        if(emailToCaseSettingMap.get('OrgWideCheckmarxSupport')!=null){
            OrgWideCheckmarxSupport=emailToCaseSettingMap.get('OrgWideCheckmarxSupport') ;
            owa = [select id, DisplayName, Address from OrgWideEmailAddress where Address=:OrgWideCheckmarxSupport limit 1];      
        }
        if(owa.size()>0){
            message.setOrgWideEmailAddressId(owa[0].Id);
        }
        
        message.setSaveAsActivity(false); 
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) 
            System.debug('The email was sent successfully.');
        else 
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        
        
    }
    
    public Case createCase(){
        List<Case> ListCase=new List<Case>();
        Case newCase=new Case();
        if(allowEmailtoCase.Record_Type__c!='' && allowEmailtoCase.Record_Type__c!=null){
            List<RecordType> rt=[SELECT id,SobjectType FROM RecordType WHERE DeveloperName=:allowEmailtoCase.Record_Type__c and SobjectType='Case'];
            if(rt.size()>0)
                newCase.RecordTypeId=rt[0].Id;
            else{
                BuildError('The record type:'+allowEmailtoCase.Record_Type__c+ ' doesnt exists in the system');
            }
        }
        newCase.Origin=allowEmailtoCase.Case_Origin__c;
        
        if(email.subject!=null && email.subject!='')
            newCase.Subject=email.subject;
        else newCase.Subject='No Subject Provided';
        
        if(email.plainTextBody!=null && email.plainTextBody!='')
            newcase.Description=email.plainTextBody.left(lengthOfCaseDescription);
        else newCase.Description='No Description Provided';
        if(allowEmailtoCase.AssociatedAccountId__c!=null){
            List<Account> acc=[select id from account where id=:allowEmailtoCase.AssociatedAccountId__c ];
            if(acc.size()>0)
            {
                newCase.AccountId=acc[0].Id;
            }
        }
        
        insert newCase;
        system.debug('newCase'+newCase);
        List<EmailMessage> emailMessage=createEmailMessage(newCase,true);
        
        return newCase;
    }
    
    public void createCaseForTemplate(string externalId,string status){
        //create Case with external Id - of emile- case ,Usually indicates the id of the problem for which the case was opened
        Case newCase=new Case();
        if(allowEmailtoCase.Record_Type__c!='' && allowEmailtoCase.Record_Type__c!=null){
            List<RecordType> rt=[SELECT id,SobjectType FROM RecordType WHERE DeveloperName=:allowEmailtoCase.Record_Type__c and SobjectType='Case'];
            if(rt.size()>0)
                newCase.RecordTypeId=rt[0].Id;
            else{
                BuildError('The record type:'+allowEmailtoCase.Record_Type__c+ ' doesnt exists in the system');
            }
        }
        newCase.Origin=allowEmailtoCase.Case_Origin__c;
        newCase.Priority='Urgent';
        if(allowEmailtoCase.AssociatedAccountId__c!=null){//Associated Account to case by MDT
            List<Account> acc=[select id from account where id=:allowEmailtoCase.AssociatedAccountId__c limit 1];
            if(acc.size()>0)
            {
                newCase.AccountId=acc[0].Id;
            }
        }        
        if(email.subject!=null && email.subject!='')
            newCase.Subject=email.subject;
        else newCase.Subject='No Subject Provided';
        
        if(email.plainTextBody!=null && email.plainTextBody!='')
            newcase.Description=email.plainTextBody.left(lengthOfCaseDescription);
        else if(email.htmlBody != null){
            newcase.Description=email.htmlBody.left(lengthOfCaseDescription);
        }else newCase.Description='No Description Provided';

        newCase.ExternalID__c = externalId;
        newCase.Status=status;
        
        insert newCase;
        
        system.debug('*****externalId :'+externalId);
        system.debug('*****newCase :'+newCase);
        List<EmailMessage> emailMessage=createEmailMessage(newCase,true);
    }
    
    public List<EmailMessage> createEmailMessage(Case relatedCases,Boolean updateStatus){
        
        //update related case status to 'In Progress'
        string cText;
        integer i;
        
        if(updateStatus && relatedCases.status!='New' && relatedCases.status!='Closed' && relatedCases.status!='' && relatedCases.status!= null) //REM 05/06 Included the if
        {
            relatedCases.status='In_Progress'; //REM 02/06 Adjusted the API Name
            update relatedCases;            
        }    
        
        system.debug('caseId:'+relatedCases.Id);
        system.debug('email.ccAddresses'+email.ccAddresses);
        case relatedCases1=[select id,Email_Thread_Id__c from case where id=:relatedCases.Id];
        string textBodyEmail;
        if(email.plainTextBody.length()>lengthOfTextBody)
            textBodyEmail=email.plainTextBody.left(lengthOfTextBody-100)+''+relatedCases1.Email_Thread_Id__c;
        else
            textBodyEmail=email.plainTextBody;
        EmailMessage[] newEmail = new EmailMessage[0];
        newEmail.add(new EmailMessage(FromAddress = email.fromaddress,
                                      FromName = email.fromname,
                                      ToAddress = email.toaddresses[0],
                                      Subject = email.subject,
                                      TextBody = textBodyEmail,
                                      HtmlBody = email.htmlbody.left(lengthOfHtmlBody),
                                      Incoming = true,
                                      MessageDate = System.now(),     
                                      ParentId = relatedCases.Id));
        if (email.ccAddresses!=null && email.ccAddresses.size() > 0){
            cText = '';
            for (i = 0 ; i < email.ccAddresses.size() ; i++) {
                cText = cText + email.ccAddresses[i]+';';
            }
            newEmail[0].CcAddress = cText;
        }
        if ( email.headers!=null && email.headers.size() > 0){
            cText = '';
            for (i = 0 ; i < email.headers.size() ; i++) {
                cText = cText + email.headers[i].name+' = '+email.headers[i].value;
            }
            newEmail[0].headers = cText;
        }
        insert newEmail;
        
        System.debug( 'Adding attachments' );
        Map<String, Attachment> attachmentsMap = EmailUtils.buildAttachments( email, newEmail[0].id );
        if ( attachmentsMap.size() > 0 ) {
           insert attachmentsMap.values();
        }
        
        /*
        List<ContentVersion> vers = new List<ContentVersion>();
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Attachment att : attachmentsMap.values())
        {
            vers.add(new ContentVersion(Title = att.name, PathOnClient = att.name, IsMajorVersion = true, VersionData = att.Body));            
        }
        if (vers.size() > 0) insert vers;
        Set<Id> verIds = new Set<Id>();
        for (ContentVersion v : vers)
        {
            verIds.add(v.Id);
        }
        List<ContentDocument> docs = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where LatestPublishedVersionId in :verIds];
        for (ContentDocument d : docs)
        {
            links.add(new ContentDocumentLink(LinkedEntityId = newEmail[0].id, ContentDocumentId = d.Id, ShareType = 'V'));
        }
        if (links.size()>0) insert links;
            */
        
        system.debug('email.plainTextBody.length():'+email.plainTextBody.length());
        system.debug('email.plainTextBody:'+email.plainTextBody);
        if(email.plainTextBody.length()>lengthOfTextBody || Test.isRunningTest()){
            system.debug('newEmail[0].ParentId:'+newEmail[0].ParentId);
            CreateTextFileForLongEmailBody(newEmail[0].ParentId,fileType.txt);
        }
        if(email.htmlBody.length()>lengthOfHtmlBody){
            CreateTextFileForLongEmailBody(newEmail[0].ParentId,fileType.html);
        }
        
        return newEmail;
    }
    
   
    public boolean emailsWithFixTemplate(){
        boolean isTemplate=setAllowEmailToCaseAndType(email);
        string exId = null;
        if(this.typeTemplate != null){
            isTemplate=true;
            if(typeTemplate==PROBLEM){
                system.debug('MS****IN PROBLEM');
                if(email.plainTextBody!=null){
                    exId=ExtractstringUsingRegExp(email.plainTextBody,allowEmailtoCase.ProblemPlainTextRegExp__c,3);
                    system.debug('MS****IN ProblemPlainTextRegExp__c exId '+exId);
                }else if(email.htmlBody!=null && exId==null){
                    exId=ExtractstringUsingRegExp(email.htmlBody,allowEmailtoCase.ProblemHTMLRegExp__c,3);
                    system.debug('MS****IN ProblemHTMLRegExp__c exId '+exId);
                }
                createCaseForTemplate(exId,'New');
            }else if(typeTemplate == RECOVERY) {
                if(email.plainTextBody!=null){
                    exId=ExtractstringUsingRegExp(email.plainTextBody,allowEmailtoCase.RecoveryPlainTextRegExp__c,3);//Add to Monitis and RecoveryPlainTextRegExp__c same ProblemPlainTextRegExp__c
                    system.debug('MS****IN RecoveryPlainTextRegExp__c exId '+exId);
                }
                FindRelevantCase(exId);//close case problem
                createCaseForTemplate(exId,StatusClosed);//create caes closed for recovery 
            }
            
        }
        system.debug('MS****email.plainTextBody:'+email.plainTextBody);
        system.debug('MS****allowEmailtoCase:'+allowEmailtoCase);
        system.debug('MS****typeTemplate:'+typeTemplate);
        system.debug('MS****exId:'+exId);
        system.debug('MS****isTemplate:'+isTemplate);
       
        return isTemplate;
        
    }

    
    public Boolean setAllowEmailToCaseAndType(Messaging.InboundEmail email){
        List<Allow_Email_to_Case__mdt> AllowEmailtoCase = [select Email_to_include__c,Case_Origin__c,TemplateInSubjectRegexp__c,Record_Type__c,AssociatedAccountId__c,ProblemHTMLRegExp__c,ProblemPlainTextRegExp__c,RecoveryPlainTextRegExp__c,TemplateProblemInSubject__c, TemplateRecoveryInSubject__c from Allow_Email_to_Case__mdt];
        Map<String,Allow_Email_to_Case__mdt> allowEmailMap=new Map<String,Allow_Email_to_Case__mdt>();
        //Metadata contains information for match btween email to case details to create or update case records/
        for(Allow_Email_to_Case__mdt allowRecord: AllowEmailtoCase)
        {
            system.debug('-----------------------------------');
            system.debug('-**allowRecord.Email_to_include__c: '+allowRecord.Email_to_include__c );
            system.debug('-**email.fromAddress: '+email.fromAddress );
            if(email.fromAddress == allowRecord.Email_to_include__c){//check if email adress is allow to create/update case in sf
                this.allowEmailtoCase=allowRecord;
                system.debug('-**allowEmailtoCase: '+allowEmailtoCase );
                if(isMatch(email.subject,allowRecord.TemplateInSubjectRegexp__c)&& allowRecord.Record_Type__c == 'Special_Alerts'){//this is template : problem or recovery
                    this.typeTemplate = getType(email.subject);
                    system.debug('--**typeTemplate: '+typeTemplate );
                    return true;
                }else if(allowRecord.Record_Type__c != 'Special_Alerts'){//this is not template
                }
            }       
        }
        return false;
    }

    private Boolean isMatch(String str,String regExp){
        Boolean isMatch = false;
        if(str==null || regExp==null){
            return isMatch;
        }
   
        Matcher pm = Pattern.compile(regexp).matcher(str);
		isMatch = pm.matches();
        system.debug('----**str: '+str );
        system.debug('--**regExp: '+regExp );
        system.debug('--**isMatch: '+isMatch );
    	return isMatch;
    }


    public string getType(String subject){// Get word from subject of email for how type the email, if problem - create new case , if recovary close exist case with same exId
        if(subject==null){
            return null;
        }
        if(this.allowEmailtoCase.TemplateProblemInSubject__c != null && subject.contains(this.allowEmailtoCase.TemplateProblemInSubject__c)){
            return 'PROBLEM';
        }else if(this.allowEmailtoCase.TemplateRecoveryInSubject__c != null && subject.contains(this.allowEmailtoCase.TemplateRecoveryInSubject__c)){
            return 'RECOVERY';
        }
        return null;
    }
    
    
    public void FindRelevantCase(string externalId){
        List<Case> relevantCase=new List<Case>();
        if(externalId!=null){
            relevantCase=[select id,Origin,ExternalID__c from case where ExternalID__c=:externalId ];
        }
        
        //system.debug('****Michal  ' externalId:'+externalId + ' relevantCase:'+relevantCase);
        
        if(relevantCase.size()>0)
        {
            for(Case caseItem : relevantCase){//Close case relevant
                caseItem.Status=StatusClosed;   
            }
            List<EmailMessage> emailMessageToCreate = new List<EmailMessage>();
            List<EmailMessage> emailMsgList = createEmailMessage(relevantCase[0],false);
            if(relevantCase.size()>1 && emailMsgList.size()>0){
                for(integer i=1;i<relevantCase.size();i++){
                    EmailMessage clonedMsg = emailMsgList[0].clone(false,true);
                    clonedMsg.ParentId = relevantCase[i].Id;
                    emailMessageToCreate.add(clonedMsg);
                }
                insert emailMessageToCreate;
            }
            update relevantCase;
            system.debug('****Michal relevantCase:'+relevantCase+ ' emailMessageToCreate:'+emailMessageToCreate + ' -------------------:');
        }
        else
        {
            if(externalId!=null)
                createCaseForTemplate(externalId,StatusClosed); 
            else
                createCaseForTemplate(externalId,'New');   
        }
        
    }
    public string ExtractstringUsingRegExp(String str,String regExp,Integer location){
        system.debug('###str before replace:'+ str);
        str=str.trim();
        str=str.replace('\n', '');
        str=str.replace('\r', '');
        str=str.replace('\\', '');
        system.debug('###str after replace:' + str);
        system.debug ('###regExp ' + regExp);
        system.debug ('###location ' + location);
        if(regExp!=null && regExp!='' && str!=null && str!=''){
            Matcher pm = Pattern.compile(regExp).matcher(str);
            system.debug ('###pm: ' + pm);
            if( pm.matches() ){
                system.debug('***pm.group(3):'+pm.group(location));
                return pm.group(location); 
            }
        }
        system.debug('***null');
        return null;
    }
    /*
    public void createFiles(Messaging.InboundEmail email, Sobject obj) {
        
        //Create a list of attachments
        //Attachments
        system.debug('email.binaryAttachments:'+email.binaryAttachments);
        if(email.binaryAttachments!=null){
            Map< String, ContentVersion> mapContentVersion = new Map< String, ContentVersion>();
            
            List<ContentVersion>cvList = new List<ContentVersion>();
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            boolean isHeaderImage;
            for(Messaging.InboundEmail.BinaryAttachment bA : email.binaryAttachments) {
                isHeaderImage=false;
                System.debug('*** bA:'+bA);
                if(bA.headers!=null){
                    for(integer j = 0; j < bA.headers.size(); j++) {
                        
                        //Header Value
                        String headerValue = bA.headers[j].value;
                        if(headerValue.startsWith('ii') || headerValue.startsWith('<image')) {
                            headerValue = headerValue.replaceAll('<', '').replaceAll('>', '');
                            mapContentVersion.put(headerValue, new ContentVersion(
                                //Title = bA.fileName==null ? 'No Title Provided' : bA.fileName
                              Title = getFileTitle(bA.fileName) ,
                                                                                  VersionData = bA.body.size()==0 ? Blob.valueof('Empty File') : bA.body, 
                                                                                  PathOnClient='/' + bA.fileName==null ? 'No Title Provided' : bA.fileName ));
                            isHeaderImage=true;
                        }
                    }
                }
                if(!isHeaderImage)
                {
                    ContentVersion testContentInsert = new ContentVersion();
                    //testContentInsert.Title = bA.fileName==null ? 'No Title Provided' : bA.fileName;
                    testContentInsert.Title = getFileTitle(bA.fileName);
                    testContentInsert.VersionData = bA.body.size()==0 ? Blob.valueof('Empty File') : bA.body;
                    testContentInsert.PathOnClient = '/' + bA.fileName==null ? 'No Title Provided' : bA.fileName;
                    cvList.add(testContentInsert);
                }
            }
            
            //save text attachment
            if(email.textAttachments!=null){
                for(Messaging.InboundEmail.TextAttachment tAttachment : email.textAttachments){
                    System.debug('*** tAttachment:'+tAttachment);
                    ContentVersion testContentInsert = new ContentVersion();
                    //testContentInsert.Title = tAttachment.fileName==null ? 'No Title Provided' : tAttachment.fileName;
                    testContentInsert.Title = getFileTitle(tAttachment.fileName);
                    testContentInsert.VersionData = tAttachment.body==null || tAttachment.body==''? Blob.valueof('Empty File') : Blob.valueof(tAttachment.body);
                    testContentInsert.PathOnClient = '/' + tAttachment.fileName==null ? 'No Title Provided' : tAttachment.fileName;
                    cvList.add(testContentInsert);
                }
            }
            
            //Insert
            system.debug('cvList:'+cvList);
            cvList.addall(mapContentVersion.values());
            if (!cvList.isEmpty()){
                insert cvList;
            }
            cvList = [select id, ContentDocumentId from ContentVersion WHERE Id in :cvList];
            for (ContentVersion cv : cvList) {
                ContentDocumentLink cl = new ContentDocumentLink();
                cl.ContentDocumentId = cv.ContentDocumentId;
                cl.LinkedEntityId = obj.Id; //Shared with record ID
                cl.ShareType = 'V';
                cl.Visibility = 'AllUsers';
                cdlList.add(cl);
                if(obj.getSObjectType()==EmailMessage.sObjectType)
                {
                    //Add link for case
                    EmailMessage e= (EmailMessage)obj;    
                    ContentDocumentLink clCase = new ContentDocumentLink();
                    clCase.ContentDocumentId = cv.ContentDocumentId;
                    clCase.LinkedEntityId = e.ParentId; //Shared with record ID
                    clCase.ShareType = 'V';
                    clCase.Visibility = 'AllUsers';
                    cdlList.add(clCase);
                }
                
            }
            insert cdlList;
            
            system.debug('***mapContentVersion.values():'+mapContentVersion.values());
            
            boolean isUpdate=false;
            //Process inline images and update the HTML Body
            for(String headerValue : mapContentVersion.keySet()) {               
                //Reference Link
                //String refLink = '/servlet/servlet.FileDownload?file=' + mapContentVersion.get(headerValue).Id;
                string docVersionId=mapContentVersion.get(headerValue).Id;
                string orgId=UserInfo.getOrganizationId();
                String refLink=Url.getSalesforceBaseUrl().getProtocol() + '://'+System.Url.getSalesforceBaseUrl().getHost().remove('-api')+'/sfc/servlet.shepherd/version/download/'+docVersionId+'?asPdf=false&operationContext=CHATTER';
                //String refLink=Url.getSalesforceBaseUrl().getProtocol() + '://'+System.Url.getSalesforceBaseUrl().getHost().remove('-api')+'/servlet/servlet.ImageServer?id='+docVersionId.left(15)+'&oid='+orgId.left(15);
                if(obj.getSObjectType()==EmailMessage.sObjectType)
                {
                    EmailMessage e= (EmailMessage)obj;    
                    e.HtmlBody = e.HtmlBody.replaceAll('cid:' + headerValue, refLink).left(lengthOfHtmlBody);
                    isUpdate=true;
                }
            }
            if(isUpdate)
                update obj;
        }
    }
    */ 
    
    public void BuildError(String error){
            List<Email_for_receive_errors__mdt> emailForReceiveError=[select email__c from Email_for_receive_errors__mdt];
        String[] toAddresses = new list<string>();
        for(Email_for_receive_errors__mdt em:emailForReceiveError) {
            toAddresses.add(em.email__c);
        }
        Blob body=Blob.valueof('<b>Error from EmailToCaseService:</b> '+error+'<br/>');
        body=Blob.valueof(body.toString()+'<b><u>Email details:</u></b><br/>');
        body=Blob.valueof(body.toString()+'<b>From Address:</b> '+email.fromAddress+'<br/>');
        body=Blob.valueof(body.toString()+'<b>Subject:</b> '+email.subject+'<br/>');
        body=Blob.valueof(body.toString()+'<b>Plain Text Body:</b> '+ email.plainTextBody+'<br/>');
        body=Blob.valueof(body.toString()+'<b>HTML Body:</b> '+ email.htmlBody+'<br/>');
        
        SendEmail(toAddresses,receiveError,body,'');       
    }
    
    
    public void CreateTextFileForLongEmailBody(ID ObjId,FileType type){
        system.debug('CreateTextFileForLongEmailBody: ObjId'+ObjId);
        List<ContentVersion>cvList = new List<ContentVersion>();
        string fileName ='Email '+system.now()+' '+email.subject+'.'+type;
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        if(type==FileType.txt)
            cv.VersionData = Blob.valueOf(email.plainTextBody);
        else
            cv.VersionData = Blob.valueOf(email.htmlBody);
        cv.PathOnClient = '/' + fileName ;
        cvList.add(cv);
        insert cvList;
        
        cvList = [select id, ContentDocumentId from ContentVersion WHERE Id in :cvList];
        
        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = cvList[0].ContentDocumentId;
        cl.LinkedEntityId =ObjId; //Shared with record ID
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;
        
        
        
    }
    /*
    public string getFileTitle(String title){
        if(title==null){
            return 'No Title Provided';
        }
        if (title.indexOf('.') > 0)
    			title = title.substring(0, title.lastIndexOf('.'));
        return title;
    }*/
}

     /*
    public void createAttachments(Messaging.InboundEmail email, Sobject obj) {

    //Create a list of attachments
    Map< String, Attachment > mapAttachments = new Map< String, Attachment >();
    //Attachments
    system.debug('email.binaryAttachments:'+email.binaryAttachments);
    boolean isHeaderImage;
    if(email.binaryAttachments!=null){
    List<Attachment> attachments = new List<Attachment>();
    for(Messaging.InboundEmail.BinaryAttachment bA : email.binaryAttachments) {
    isHeaderImage=false;
    System.debug(bA);
    if(bA.headers!=null){
    for(integer j = 0; j < bA.headers.size(); j++) {

    //Header Value
    String headerValue = bA.headers[j].value;
    if(headerValue.startsWith('ii') || headerValue.startsWith('<image')) {
    headerValue = headerValue.replaceAll('<', '').replaceAll('>', '');
    mapAttachments.put(headerValue, new Attachment(Name = bA.fileName, body = bA.body, 
    ParentId = obj.Id, ContentType = bA.mimeTypeSubType));
    isHeaderImage=true; 
    }
    }
    }
    if(!isHeaderImage)
    {
    Attachment attachment = new Attachment();                   
    attachment.Name = bA.fileName;
    attachment.Body = bA.body;
    attachment.ParentId = obj.Id;
    attachments.add(attachment); 
    }
    }

    //Insert
    attachments.addall(mapAttachments.values());
    //insert mapAttachments.values();
    if (!attachments.isEmpty()){
    insert attachments;
    }
    system.debug('***mapAttachments.values():'+mapAttachments.values());

    boolean isUpdate=false;
    //Process inline images and update the HTML Body
    for(String headerValue : mapAttachments.keySet()) {               
    //Reference Link
    String refLink = '/servlet/servlet.FileDownload?file=' + mapAttachments.get(headerValue).Id;
    if(obj.getSObjectType()==EmailMessage.sObjectType)
    {
    EmailMessage e= (EmailMessage)obj;    
    e.HtmlBody = e.HtmlBody.replaceAll('cid:' + headerValue, refLink);
    isUpdate=true;
    }
    }
    if(isUpdate)
    update obj;
    }
    }
    */