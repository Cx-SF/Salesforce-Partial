@isTest(SeeAllData=true)
global class CommunityUserProfileCtrlTest {

    static testMethod void testFetchUserDetail() {
		Test.StartTest();        
        User user = CommunityUserProfileCtrl.fetchUserDetail();
		Test.StopTest();
	}

}