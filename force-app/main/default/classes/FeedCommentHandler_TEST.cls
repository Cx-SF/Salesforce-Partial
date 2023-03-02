@istest
private class FeedCommentHandler_TEST 
{
    
    @istest (seealldata = false)
    static void TestTrigger()
    {
        Account a= TestObjectCreator.CreateAccount();
        insert a;
        
        Case c = TestObjectCreator.CreateCase (a);
        insert c;
        
        FeedItem fi = TestObjectCreator.CreateFI (c.id);
        insert fi;
        
        FeedComment fc = TestObjectCreator.CreateFC (fi.id);
        insert fc;
    }

}