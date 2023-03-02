@isTest
public class CaseCloneControllerTestV2 {

    static testMethod void testOpen() 
	{
		Case testCase = new Case(Status = 'New');
		insert testCase;
		Test.StartTest(); 
        ApexPages.StandardController stdc = new ApexPages.StandardController(testCase);
        CaseCloneControllerV2 c = new CaseCloneControllerV2(stdc);
 		Test.StopTest();
	}
    
    static testMethod void testClosed() 
	{
		Case testCase = new Case(Status = 'New');
		insert testCase;
		Test.StartTest(); 
        ApexPages.StandardController stdc = new ApexPages.StandardController(testCase);
        CaseCloneControllerV2 c = new CaseCloneControllerV2(stdc);
 		Test.StopTest();
	}
    
    static testMethod void testReturn() 
	{
		Case testCase = new Case(Status = 'Closed');
		insert testCase;
		Test.StartTest(); 
        ApexPages.StandardController stdc = new ApexPages.StandardController(testCase);
        CaseCloneControllerV2 c = new CaseCloneControllerV2(stdc);
        c.returnToOriginalCase();
		Test.StopTest();
	}
    
}