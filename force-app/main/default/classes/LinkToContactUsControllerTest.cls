@IsTest
public  with sharing  class LinkToContactUsControllerTest {
    @IsTest
    static void linkToContactUsControllerTest() { 
      
        LinkToContactUsController.getDomain();
        LinkToContactUsController.getOrgDomain();
        LinkToContactUsController.getOrgId();
        LinkToContactUsController.getRecorTypeId('General');
        LinkToContactUsController.getAccountId('Contact_Us');
		LinkToContactUsController.sendEmail('I you');        
    }
}