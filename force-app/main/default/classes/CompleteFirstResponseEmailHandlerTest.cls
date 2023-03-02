@isTest
private class CompleteFirstResponseEmailHandlerTest {
    
    @isTest
    static void testIncomingEmail(){  
        
        Case newCase = new Case() ; 
        insert newCase;
         
        EmailMessage[] newEmail = new EmailMessage[0];

	 	newEmail.add(new EmailMessage(FromAddress = 'test@abc.org', 
                                   Incoming = false, 
                                   ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', 
                                   Subject = 'Test email', 
                                   TextBody = '23456 ', 
                                   ParentId = newCase.Id));
        newEmail.add(new EmailMessage(FromAddress = 'test@abc.org', 
                                   Incoming = true, 
                                   ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', 
                                   Subject = 'Test email2', 
                                   TextBody = '23456 ', 
                                   ParentId = newCase.Id));
        
        insert newEmail;
         
       	CompleteFirstResponseEmailHandler x = new CompleteFirstResponseEmailHandler(newEmail);
    }
}