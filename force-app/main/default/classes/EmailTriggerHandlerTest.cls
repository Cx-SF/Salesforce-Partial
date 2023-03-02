@isTest
public class EmailTriggerHandlerTest {
    
    static testMethod void testUpdateCC() {
        Case testCase = new Case(
                Subject = 'Newest Case'
        );
        insert testCase;
        
        Test.startTest();
        EmailMessage m = new EmailMessage();
        m.Incoming = false;
        m.FromAddress = 'from@email.com';
        m.CcAddress = 'cc@email.com';
        m.Subject = 'Subject';
        m.HtmlBody = 'HTML body';
        m.ParentId = testCase.Id;
        insert m;
        Test.stopTest();
    }
    
}