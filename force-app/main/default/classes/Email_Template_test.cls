@IsTest (SeeAllData=true)
public class Email_Template_test  {
    public static testMethod void runTest() {
        
        Account testAcc = new Account(Name = 'TestAcc');
		insert testAcc;
		//Contact con = new Contact(LastName = 'TestContact', Account = testAcc , MailingCountry = 'France');
		//insert con;			
		
	
		Opportunity testOpp = new Opportunity(Name = 'TestOpp',StageName = 'Prospecting',CloseDate = Date.today().addDays(5));
		insert testOpp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c( SBQQ__Account__c = testAcc.Id, SBQQ__Opportunity2__c = testOpp.Id/*,*/
                                                  /*WD_Document_Type__c = 'IO'*/);
        insert quote;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c (SBQQ__Quote__c  = quote.id);
        //insert ql; 
        sbaa__Approver__c approver = new sbaa__Approver__c(name = 'app', sbaa__GroupId__c = null);
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
		//Approvers.cc_aproverId = approver.Id;
		//Approvers.cc_groupId = 
		Approvers.cc_Name = 'test';
		Approvers.cc_userId = UserInfo.getUserId();
		Approvers.cc_OwnerId = UserInfo.getUserId();
		String nn = Approvers.inTheGroup;
		List<String> strList = Approvers.memberGroup;
        list <sbaa__Approval__c> apps = Approvers.RecordsToDisplay; 

		Email_Template_renewal_Info_Ctrl info = new Email_Template_renewal_Info_Ctrl();
		info.Acv_Difference_Amount = '45';
		info.Acv_Difference_Percent = '1';
		info.Acv_DownSell_Amount = '54';
		info.Acv_DownSell_Percent = '2';
		info.AcvDifference_Amount = 66;
		info.AcvDifference_Percent = 2;
		info.AcvDownSell_Amount = 76;
		info.AcvDownSell_Percent = 4;

		info.Expected_Renewal_ACV = '78';
		info.ExpectedRenewal_ACV = 75;
		info.UpliftedExpected_RenewalACV = 44;
		info.Uplifted_ExpectedRenewal_ACV = '44';
		info.currencyISO = 'USD';
		
		info.currencyISO = 'USD';
        test.stopTest();
    }
}