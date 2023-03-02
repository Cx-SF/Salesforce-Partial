@isTest
public class EmailToCaseServiceTest {
    static testMethod void notAllowEmail() {
                Messaging.InboundEmail email = new Messaging.InboundEmail() ;
                Messaging.InboundEnvelope env= new Messaging.InboundEnvelope();                 
                Messaging.InboundEmail email0 = new Messaging.InboundEmail() ;
                email0.fromAddress = 'michal8594@gmail.com';                
                EmailToCaseService obj0= new EmailToCaseService();
                obj0.handleInboundEmail(email0, env );
                
    }
    
    static testMethod void EmailToCaseServiceHelperTest() {
                Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
                email1.subject='**RECOVERY alert TEST 2';
                email1.plainTextBody='Monitor Type: Monitor Type \nService : test Service \nAlert ID : 290704083: alert test \nadditional Info: desciption';    
                email1.htmlBody='<b>Alert ID #</b>290704083 :';               
        string[] ccAdd=new string[]{'michal.chavshush@wedoit.co.il'};
            email1.ccAddresses=ccAdd;
        string[] toAdd=new string[]{'michal.chavshush@wedoit.co.il'};
            email1.toAddresses=toAdd;       
        EmailToCaseServiceHelper helper = new EmailToCaseServiceHelper(email1);
        		helper.allowEmailtoCase = [SELECT AssociatedAccountId__c,Record_Type__c,Case_Origin__c FROM Allow_Email_to_Case__mdt LIMIT 1];
                helper.createCase();
                
    }
    
    static testMethod void test() {
        list<User> usr = [Select id From User where (id='005D0000005VCkT' or name='Salesforce Admin') and IsActive=true limit 1];//take 1 user which will always exist 
        if (usr.size() > 0){
            system.runas(usr[0]){
                Case c0=new case(subject='test11');
                insert c0;
                case c=[select id,Email_Thread_Id__c from case where id=:c0.Id];
                system.debug('c.id='+c.Id +' Email_Thread_Id__c='+c.Email_Thread_Id__c);
                
                
                
                Map<String,Allow_Email_to_Case__mdt> AllowEmailtoCaseOriginMap=new Map <String,Allow_Email_to_Case__mdt>();
                List<Allow_Email_to_Case__mdt> AllowEmailtoCase = [select Email_to_include__c,Case_Origin__c,Record_Type__c,AssociatedAccountId__c from Allow_Email_to_Case__mdt];
                for(Allow_Email_to_Case__mdt al:AllowEmailtoCase){
                    if(!AllowEmailtoCaseOriginMap.containsKey(al.Case_Origin__c))
                        AllowEmailtoCaseOriginMap.put(al.Case_Origin__c,al);
                }
                //Monitis
                Messaging.InboundEmail email = new Messaging.InboundEmail() ;
                Messaging.InboundEnvelope env= new Messaging.InboundEnvelope();                 
                
                email.subject = '**PROBLEM alert TEST 2';
                //email.plainTextBody='Monitor Type: Monitor Type \nService : test Service \nAlert ID # 290704083: alert test \nadditional Info: desciption';
                email.plainTextBody='PROBLEMHTTPSURL: https://cxprivatecloud.checkmarx.net/cxwebclientName: cxprivatecloud.checkmarx.netTime: 15-7-2019 21:50:58 (GMT + 3)Group Name:  cxprivatecloud srvFailures From: US-MID1, Germany1, Israel Additional Information:   HTTP CRITICAL - Connection timed out. IP 52.3.182.148Alert ID: 299218028';
                email.htmlBody='<b>Alert ID :</b>290704083 :';
                email.fromAddress = AllowEmailtoCaseOriginMap.get('Monitis').Email_to_include__c;
                EmailToCaseService obj= new EmailToCaseService();
                obj.handleInboundEmail(email, env );
                
                //email with Thread Id
                email.subject = '**PROBLEM alert TEST 2 '+c.Email_Thread_Id__c;
                email.fromAddress = AllowEmailtoCaseOriginMap.get('Monitis').Email_to_include__c;
                string[] ccAdd=new string[]{'michal.chavshush@wedoit.co.il'};
                email.ccAddresses=ccAdd;
                string[] toAdd=new string[]{'michal.chavshush@wedoit.co.il'};
                    email.toAddresses=toAdd;
                Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header(); 
                email.headers=new Messaging.InboundEmail.Header[1]; 
                hditem.name='Date'; 
                hditem.value='Tue, 28 Apr 2009 14:08:37 -0700'; 
                email.headers[0]=hditem;
             
                // add an Binary attachment
                Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
                attachment.body = blob.valueOf('my attachment text');
                attachment.fileName = 'textfileone.txt';
                attachment.mimeTypeSubType = 'text/plain';
                email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
                
                // add an TextAttachment 
                Messaging.InboundEmail.TextAttachment attachmentText = new Messaging.InboundEmail.TextAttachment();
                attachmentText.body = 'my attachment text';
                attachmentText.fileName = 'textfileone.txt';
                attachmentText.mimeTypeSubType = 'text/plain';
                email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { attachmentText };      
                obj.handleInboundEmail(email, env );
                
                //monitis recovery
                Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
                email1.subject='**RECOVERY alert TEST 2';
                email1.plainTextBody='Monitor Type: Monitor Type \nService : test Service \nAlert ID : 290704083: alert test \nadditional Info: desciption';    
                email1.htmlBody='<b>Alert ID :</b>290704083 :';
                
                if(AllowEmailtoCaseOriginMap.get('Monitis')!=null){
                    email1.fromAddress = AllowEmailtoCaseOriginMap.get('Monitis').Email_to_include__c;
                    EmailToCaseService obj1= new EmailToCaseService();
                    obj1.handleInboundEmail(email1, env );
                }  
                Test.startTest();
                //Nagios - Problem
                Messaging.InboundEmail emailNAGIOS = new Messaging.InboundEmail() ;
                
                emailNAGIOS.subject='** PROBLEM Service Alert: Transurban-Eng/IISADMIN is UNKNOWN **';
                emailNAGIOS.plainTextBody='***** Nagios *****Notification Type: PROBLEMServiceProblemID: 126945LastServiceProblemID: 113646Service ';  
                EmailToCaseService obj2= new EmailToCaseService();
                
                if(AllowEmailtoCaseOriginMap.get('Nagios')!=null){
                    emailNAGIOS.fromAddress = AllowEmailtoCaseOriginMap.get('Nagios').Email_to_include__c;      
                    obj2.handleInboundEmail(emailNAGIOS, env );
                }
                
                //Nagios - Recovery
                emailNAGIOS.subject='** RECOVERY Service Alert TEST';
                emailNAGIOS.plainTextBody='***** Nagios *****Notification Type: RECOVERYServiceProblemID: 126871LastServiceProblemID: 126838Service: ';   
                obj2.handleInboundEmail(emailNAGIOS, env );
                                            
                //new case
                Messaging.InboundEmail email3 = new Messaging.InboundEmail() ;
                if(AllowEmailtoCaseOriginMap.get('Nagios')!=null){
                    email3.fromAddress = AllowEmailtoCaseOriginMap.get('Nagios').Email_to_include__c;
                    EmailToCaseService obj3= new EmailToCaseService();
                    obj3.handleInboundEmail(email3, env );
                }
                
                //Monitis with invalid template (for error of parsing) 
                email1.htmlBody='<b>Alert ID #1</b>290704083 :';
                obj.handleInboundEmail(email1, env );
                
                
                //email with Thread Id 
                String caseId=c.Id;
                String threadId=c.Email_Thread_Id__c;
                
                email.subject = '**PROBLEM alert TEST 2 [ '+ threadId + ' ] ';
                obj.handleInboundEmail(email, env );
                
                c.Status = 'Closed';
                update c;
                obj.handleInboundEmail(email, env );
                
                email.subject = '**PROBLEM alert TEST 2 [ ref:_123_:ref ] ';
                 obj.handleInboundEmail(email, env );
                    
                Test.stopTest();
                
              
            }
        }
        
        
        
    }
}