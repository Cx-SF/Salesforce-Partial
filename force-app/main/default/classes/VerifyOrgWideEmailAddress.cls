global class VerifyOrgWideEmailAddress implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,
    Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();


        //This is one time thing that you will have to perfrom everytime you setup the org wide email address.
        //Use this html body to fetch the verification link and open it in a browser to verify it. 
        System.debug('The email Body ==> '+ email.plainTextBody);
                System.debug('The email html Body ==> '+ email.htmlBody);


        result.success = true;
        return result;
    }
}