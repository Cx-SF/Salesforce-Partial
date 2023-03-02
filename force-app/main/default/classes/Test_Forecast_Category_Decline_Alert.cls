@istest(seeAllData=true)
private class Test_Forecast_Category_Decline_Alert 
{
	static testMethod void test_notifyManagers() 
    {
        Forecast_Category_Decline_Alert testingClass = new Forecast_Category_Decline_Alert();
        testingClass.notifyManagers();
    }
}