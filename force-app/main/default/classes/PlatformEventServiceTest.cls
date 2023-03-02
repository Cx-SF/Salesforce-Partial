@IsTest
private class PlatformEventServiceTest {

    @IsTest
    private static void TestCaseEvents (){
        Case c = new Case();
        insert c;

        Test.startTest();

        Boolean firstReq = PlatformEventService.thisEventAlreadyExist(c.Id+'Case');
        Boolean secondReq = PlatformEventService.thisEventAlreadyExist(c.Id+'Case');

        Boolean neverCaseReq1 = PlatformEventService.thisEventAlreadyExist(c.Id+'Case_test');
        Boolean neverCaseReq2 = PlatformEventService.thisEventAlreadyExist(c.Id+'Case_test');

        Test.stopTest();

        System.assertEquals(true,firstReq);
        System.assertEquals(true,secondReq);

        System.assertEquals(false,neverCaseReq1);
        System.assertEquals(true,neverCaseReq2);

    }

    @IsTest
    private static void TestCaseComentEvents (){
        Case c = new Case();
        insert c;

        CaseComment cc = new CaseComment(ParentId = c.Id,CommentBody='blank comment');
        insert cc;



        Test.startTest();

        Boolean firstReq = PlatformEventService.thisEventAlreadyExist(cc.Id+'Comment');
        Boolean secondReq = PlatformEventService.thisEventAlreadyExist(cc.Id+'Comment');

        Boolean neverCommentReq1 = PlatformEventService.thisEventAlreadyExist(cc.Id+'Comment_test');
        Boolean neverCommentReq2 = PlatformEventService.thisEventAlreadyExist(cc.Id+'Comment_test');

        Test.stopTest();

        System.assertEquals(false,firstReq);
        System.assertEquals(true,secondReq);

        System.assertEquals(false,neverCommentReq1);
        System.assertEquals(true,neverCommentReq2);

    }

    @IsTest
    private static void TestCaseEmailEvents (){
        Case c = new Case();
        insert c;

        EmailMessage mail = new EmailMessage(ParentId = c.Id,TextBody='blank email');
        insert mail;



        Test.startTest();

        Boolean firstReq = PlatformEventService.thisEventAlreadyExist(mail.Id+'Email');
        Boolean secondReq = PlatformEventService.thisEventAlreadyExist(mail.Id+'Email');

        Boolean neverEmailReq1 = PlatformEventService.thisEventAlreadyExist(mail.Id+'Email_test');
        Boolean neverEmailReq2 = PlatformEventService.thisEventAlreadyExist(mail.Id+'Email_test');

        Test.stopTest();

        System.assertEquals(false,firstReq);
        System.assertEquals(true,secondReq);

        System.assertEquals(false,neverEmailReq1);
        System.assertEquals(true,neverEmailReq2);

    }

}