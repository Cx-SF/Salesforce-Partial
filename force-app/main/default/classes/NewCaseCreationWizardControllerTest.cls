@isTest
global class NewCaseCreationWizardControllerTest {

    static testMethod void testGetMetadata() {
		Test.StartTest();        
        String metadataNew = NewCaseCreationWizardController.getMetadata();
		Test.StopTest();
	}
    
    static testMethod void testFetchArticles() {
        Knowledge__kav[] res = NewCaseCreationWizardController.fetchArticles('test');
    }
    
    static testMethod void testCreateNewCaseWithArticle() {
		Knowledge__kav article=new Knowledge__kav(Title='Test',UrlName='Troubleshooting-Test-Article1',IsVisibleInCsp = true,IsVisibleInPkb = true,IsVisibleInPrm = true);
        insert article;
        //Knowledge__kav article = ([Select Id From Knowledge__kav])[0];
        Test.StartTest();
        Case c = new Case();
        c.Subject = '00001';
        c.Description = 'Description';
        NewCaseCreationWizardController.createNewCaseWithArticle(c, article.Id);
        Test.StopTest();
    }
    
}