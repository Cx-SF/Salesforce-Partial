@isTest
public class ClosecaseControllerTest {
    
    static testMethod void testGetStatus() 
    {
        Case testCase = new Case(Status = 'New');
        insert testCase;
        Test.StartTest(); 
        String status = CloseCaseController.getStatus(testCase.Id);
        CloseCaseController.updateStatus(testCase);
        Test.StopTest();
    }
}