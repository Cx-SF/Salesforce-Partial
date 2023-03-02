/************************************************************************************** 
Name              : SendAnEmail_Controller
Description       : Controller for VF SendAnEmail
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Irit                 14/07/2013              Itay Sinvani          [SW-5525]
****************************************************************************************/
@isTest
private class SendAnEmail_Controller_Test
{	
	static testmethod void SendAnEmail_Controller_Test()
	{

		ClsObjectCreator cls = new ClsObjectCreator();

		Lead lead = cls.returnLead('Test10@test.com');
		insert lead;                
		
		Apexpages.standardController sc = new Apexpages.standardController(lead);
		SendAnEmail_Controller controller = new SendAnEmail_Controller(sc);		
		Apexpages.currentPage().getParameters().put('Id', lead.Id);
		controller = new SendAnEmail_Controller(sc);	
		controller.getTemplates();
		controller.getDirectories();
		controller.selectedFolder = UserInfo.getOrganizationId();
		controller.selectedTemplate = 'ethan';
		controller.CreateAnEmail();	
		controller.selectedFolder = UserInfo.getUserId();
		controller.selectedTemplate = ' - Select - ';
		controller.CreateAnEmail();	
		controller.selectedFolder = UserInfo.getOrganizationId();
		controller.selectedTemplate = 'Not in list';
		controller.CreateAnEmail();
		MyException e = new MyException('This is Exception Handling');
		controller.ErrorFound(e);			
	}
}