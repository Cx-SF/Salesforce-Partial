/************************************************************************************** 
Name              : NewOpp
Description       : Controller for VF New Opportunity
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Irit					29/07/2013				Itay Sinvani				[SW-5728]
****************************************************************************************/
@isTest
private class NewOpp_Test
{	
	public class MyException extends Exception {}
	static testmethod void NewOpportunity_Test()
	{
		ClsObjectCreator cls = new ClsObjectCreator();
		
		Account acc = cls.returnAccount('TestAcc');
		insert acc;
		Contact con = cls.returnContact(acc.ID , 'TestB2@test.com');
		insert con;			
		
		Test.startTest();
		Apexpages.standardController sc1 = new Apexpages.standardController(con);
		NewOpp np1 = new NewOpp(sc1);
		
		Opportunity opp = new Opportunity(Name = 'TestOpp',StageName = 'Prospecting',CloseDate = Date.today().addDays(5));
		insert opp;
		Apexpages.standardController sc2 = new Apexpages.standardController(opp);
		NewOpp np2 = new NewOpp(sc2);		
		//con.New_Opportunity();			
		
		Test.stopTest();	
		MyException e = new MyException('This is Exception Handling');
		np1.ErrorFound(e);	
		np2.ErrorFound(e);	
				
	}
}