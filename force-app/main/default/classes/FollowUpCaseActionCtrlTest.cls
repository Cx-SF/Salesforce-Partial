@isTest
public class FollowUpCaseActionCtrlTest {

    static testMethod void testGetStatus() 
	{
		Case testCase = new Case(Status = 'New');
		insert testCase;
		Test.StartTest(); 
        String status = FollowUpCaseActionCtrl.getStatus(testCase.Id);
 		Test.StopTest();
	}
    
    static testMethod void testCloneCase() 
	{
		Case testCase = new Case(Status = 'New');
		insert testCase;
		Test.StartTest(); 
        Case newCase = FollowUpCaseActionCtrl.cloneCase(testCase.Id);
 		Test.StopTest();
	}
    
}