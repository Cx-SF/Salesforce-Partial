@isTest(seeAllData=true)
public class VerifyOrgWideEmailAddressTest {
    static testMethod void test() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env= new Messaging.InboundEnvelope();  
        email.fromAddress = 'michal8594@gmail.com';
        VerifyOrgWideEmailAddress obj= new VerifyOrgWideEmailAddress();
        obj.handleInboundEmail(email, env );
    }
}