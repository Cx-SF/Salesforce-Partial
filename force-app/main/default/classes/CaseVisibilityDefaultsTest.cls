@isTest(SeeAllData=True)
public with sharing class CaseVisibilityDefaultsTest {
	@isTest
    public static void doTest()
    {
        Case c = new Case();
        c.Subject = 'Test';
        insert c;
        
        ContentDocument cd = [select id from ContentDocument limit 1];
        //Attachment a = new Attachment(ContentType='text/html', name='test', body=ENcodingUtil.base64Decode(''), parentId = c.id);
        //insert a;        
        ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cd.id, LinkedENtityId = c.id, ShareType = 'V');
        insert cdl;
        ContentDocumentLink cdl2 = [select id,Visibility from ContentDocumentLink where id=:cdl.id limit 1 ];
        System.assertEquals('AllUsers', cdl2.Visibility);
        
    }
}