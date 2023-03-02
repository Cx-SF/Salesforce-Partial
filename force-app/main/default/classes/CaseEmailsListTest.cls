@IsTest
public with sharing class CaseEmailsListTest {

    @IsTest
    static void getCase2EmailAddress_test() { 
        String localPart = 'checkmarxsupport';
        Test.startTest();
            String email = CaseEmailsListCtrl.getCase2EmailAddress(localPart);
        Test.stopTest();
        System.assertEquals(true,email.contains('@'),'getCase2EmailAddress test failed. String not contains "@" ');
    }

    @IsTest
    static void sendMailMethod_test() {
        Case testCase = new Case(
                Subject = 'Newest Case'
        );
        Test.startTest();
        insert testCase;
        List<String> atts = new List<String>();
        atts.add('test1');
        atts.add('test2');
        Map<String, Map<String, String>> attachData = new Map<String, Map<String, String>>();
        Map<String, String> attachment = new Map<String, String>();
        attachment.put('file1.txt', 'PD94bWwgdmVyc2lvbj0iMS4wIiA/PjwhRE9DVFlQRSBzdmcgIFBVQkxJQyAnLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4nICAnaHR0cDovL3d3dy53My5vcmcvR3JhcGhpY3MvU1ZHLzEuMS9EVEQvc3ZnMTEuZHRkJz48c3ZnIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUwIDUwIiBoZWlnaHQ9IjUwcHgiIGlkPSJMYXllcl8xIiB2ZXJzaW9uPSIxLjEiIHZpZXdCb3g9IjAgMCA1MCA1MCIgd2lkdGg9IjUwcHgiIHhtbDpzcGFjZT0icHJlc2VydmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiPjxyZWN0IGZpbGw9Im5vbmUiIGhlaWdodD0iNTAiIHdpZHRoPSI1MCIvPjxwYXRoIGQ9Ik0zNC4zOTcsMjlMMjAsNDhMNS42MDQsMjkgIEgxNUMxNSwwLDQ0LDEsNDQsMVMyNSwyLjM3MywyNSwyOUgzNC4zOTd6IiBmaWxsPSJub25lIiBzdHJva2U9IiMwMDAwMDAiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLW1pdGVybGltaXQ9IjEwIiBzdHJva2Utd2lkdGg9IjIiLz48L3N2Zz4=');
        attachData.put('file1', attachment);
        attachment = new Map<String, String>();
        attachment.put('file2.txt', 'PD94bWwgdmVyc2lvbj0iMS4wIiA/PjwhRE9DVFlQRSBzdmcgIFBVQkxJQyAnLS8vVzNDLy9EVEQgU1ZHIDEuMS8vRU4nICAnaHR0cDovL3d3dy53My5vcmcvR3JhcGhpY3MvU1ZHLzEuMS9EVEQvc3ZnMTEuZHRkJz48c3ZnIGVuYWJsZS1iYWNrZ3JvdW5kPSJuZXcgMCAwIDUwIDUwIiBoZWlnaHQ9IjUwcHgiIGlkPSJMYXllcl8xIiB2ZXJzaW9uPSIxLjEiIHZpZXdCb3g9IjAgMCA1MCA1MCIgd2lkdGg9IjUwcHgiIHhtbDpzcGFjZT0icHJlc2VydmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiPjxyZWN0IGZpbGw9Im5vbmUiIGhlaWdodD0iNTAiIHdpZHRoPSI1MCIvPjxwYXRoIGQ9Ik0zNC4zOTcsMjlMMjAsNDhMNS42MDQsMjkgIEgxNUMxNSwwLDQ0LDEsNDQsMVMyNSwyLjM3MywyNSwyOUgzNC4zOTd6IiBmaWxsPSJub25lIiBzdHJva2U9IiMwMDAwMDAiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLW1pdGVybGltaXQ9IjEwIiBzdHJva2Utd2lkdGg9IjIiLz48L3N2Zz4=');
        attachData.put('file2', attachment);
        CaseEmailsListCtrl.sendMailMethod('noreply@google.com', 'cc@email.com', 'String mSubject','String mbody', testCase.Id, atts, attachData);
        Test.stopTest();
    }

    @IsTest
    static void getCaseEmailMessages_test() {
        Case testCase = new Case(
                Subject = 'Newest Case'
        );
        Test.startTest();
        insert testCase;
        List<EmailMessage> emailList = CaseEmailsListCtrl.getCaseEmailMessages(testCase.Id).emailMessageList;
        Test.stopTest();
    }
    
    @IsTest
    static void sendErrorTest() {
        Case testCase = new Case(
                Subject = 'Newest Case'
        );
        insert testCase;
        Test.startTest();
        CaseEmailsListCtrl.sendMailOnError(testCase.Id, 'error message');
        Test.stopTest();
    }
    
    @IsTest
    static void createFeedItemTest() {
        Case testCase = new Case(
                Subject = 'Newest Case'
        );
        insert testCase;
        List<Map<String, String>> attachData = new List<Map<String, String>>();
        Map<String, String> attach1 = new Map<String, String>();
        Map<String, String> attach2 = new Map<String, String>();
        attach1.put('documentId', '12345');
        attach1.put('name', 'file1.txt');
        attachData.add(attach1);
        attach2.put('documentId', '54321');
        attach2.put('name', 'file2.txt');
        attachData.add(attach2);
        Test.startTest();
        CaseEmailsListCtrl.createFeedItemOnAttachmentsUpload(testCase.Id, attachData);
        Test.stopTest();
    }
    
    
    
}