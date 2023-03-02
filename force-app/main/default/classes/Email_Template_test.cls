@IsTest (SeeAllData=true)
public class Email_Template_test  {
    public static testMethod void runTest() {
        
        Account testAcc = new Account(Name = 'TestAcc');
		insert testAcc;
		Contact con = new Contact(LastName = 'TestContact', Account = testAcc , MailingCountry = 'France');
		insert con;			
		
	
		Opportunity testOpp = new Opportunity(Name = 'TestOpp',StageName = 'Prospecting',CloseDate = Date.today().addDays(5));
		insert testOpp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c( SBQQ__Account__c = testAcc.Id, SBQQ__Opportunity2__c = testOpp.Id/*,*/
                                                  /*WD_Document_Type__c = 'IO'*/);
        insert quote;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c (SBQQ__Quote__c  = quote.id);
        //insert ql; 
        sbaa__Approver__c approver = new sbaa__Approver__c(name = 'app');
        insert approver;
        sbaa__ApprovalChain__c chaim = new sbaa__ApprovalChain__c(Name = 'Renewal' , sbaa__TargetObject__c  = 'SBQQ__Quote__c' ) ;
        insert chaim;
        sbaa__Approval__c app = new sbaa__Approval__c (Quote__c = Quote.id , sbaa__ApprovalStep__c = 1, sbaa__RecordField__c = 'Quote__c' ,sbaa__ApprovalChain__c  = chaim.id , sbaa__Approver__c = approver.id);
        insert app;
        test.startTest();
        Email_Template_Ctrl ctrl = new Email_Template_Ctrl();
        ctrl.ApprovalId = app.id;
        ctrl.fSetName = 'Email_Template_Fields';
        ctrl.ObjToDisplay = 'SBQQ__QuoteLine__c';
        ctrl.referenceName = 'SBQQ__Quote__c';
        ctrl.ParentId = quote.id;
        List<sobject> c = ctrl.RecordsToDisplay;
        Approval_Reasons_Ctrl RES = NEW Approval_Reasons_Ctrl();
        RES.ParentId = approver.id;
        res.CurrQuote = quote.id;
        set<string> ANS = RES.ResList;
        Email_Approvers_Ctrl Approvers = new Email_Approvers_Ctrl();
        Approvers.ParentId = quote.id;
        list <sbaa__Approval__c> apps = Approvers.RecordsToDisplay; 
        test.stopTest();
    }
}