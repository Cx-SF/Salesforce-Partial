@isTest(SeeAllData=true)
private class ErrorMailSender_Test {
    static testMethod void Test() {
        Id caseId = [select Id from Case where RecordTypeId <> '0123z000000VG35' limit 1].Id;
        ErrorMailSender.sendMailOnError(caseId,'testBody');
        ErrorMailSender.sendEmail('testSubject','testBody',new list<String>{'test@test.com'});
    }
}