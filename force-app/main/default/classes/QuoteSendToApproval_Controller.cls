/******************************************************************************* 
Name              : QuoteSendToApproval_Controller
Description		  : Controller for VF that sends quote to Approval Process
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by	      Related Task/Issue 			 
----------------------------------------------------------------------------------------
1. Hernan          		25/03/2013              	Itay		           	[SW-4881]
2. Hanit          		02/10/2014              	Kfir		           	[SW-10570]
3. Dana					01/02/2015					Kfir					[SW-12106]
*******************************************************************************/

public class QuoteSendToApproval_Controller 
{	
	public Quote theQuote {get;set;}
	public Opportunity theOpp;
	public Boolean isError {get;set;}
	public Boolean isSyncing {get;set;}
	
    public QuoteSendToApproval_Controller(ApexPages.StandardController controller) 
    {
		theQuote = (Quote) controller.getRecord();
		theOpp = [Select Id,License_Type__c, MUS_Renewal_Day__c,MUS_Renewal_Month__c,MUS_Renewal_Year__c,Subscription_Renewal_Day__c,Subscription_Renewal_Month__c,Subscription_Renewal_Year__c,Payments_Terms__c From Opportunity where Id =: theQuote.OpportunityId Limit 1][0];
    }
	
	public PageReference DoAction()
	{
		PageReference page = null;
		isError = false;
		
		//For testing
		if(!Test.isRunningTest())
		{
			isSyncing = theQuote.isSyncing;
		}
		Boolean isLicenceType = true;
		String licenceType = theOpp.License_Type__c;
		Boolean hasPaymentTerms = true;
		
		if( ((licenceType=='MUS renewal' || licenceType== 'Perpetual')  && (theOpp.MUS_Renewal_Day__c==null || theOpp.MUS_Renewal_Month__c== null || theOpp.MUS_Renewal_Year__c==null)) || 
		      ((licenceType=='Subscription')  && (theOpp.Subscription_Renewal_Day__c==null || theOpp.Subscription_Renewal_Month__c== null || theOpp.Subscription_Renewal_Year__c==null)) )
		{
			isLicenceType = false;
		}
		
		if(theOpp.Payments_Terms__c == null || theOpp.Payments_Terms__c == '')
		{
			hasPaymentTerms = false;
		}
				
		if(!theQuote.Opportunity.IsClosed && isSyncing && isLicenceType && hasPaymentTerms)
		{
			if(!Apexpages.currentPage().getParameters().containsKey('close'))
			{
				//BillingContact == true > billing contact is populated on the quote
				if(Apexpages.currentPage().getParameters().containsKey('billingcontact'))
				{
					if(Apexpages.currentPage().getParameters().get('billingcontact') == 'true')
					{
						//page = DoApprovalProcess();
						page = new pageReference('/apex/vf_productionLicenses?id='+theQuote.Opportunity.Id +'&qtId=' + theQuote.Id) ; 
					}
				}
			}
		}
		else
		{
			String msg = '';
			if(theQuote.Opportunity.IsClosed)
			{
				msg = 'Cannot send for approval if Opportunity is closed';
			}
			
			if(!isSyncing )
			{
				msg = 'Cannot send for approval if Quote is not syncing';
			}
			else if(!isLicenceType)
			{
				if(licenceType == 'Subscription')
				{
					msg = 'Please fill in the Subscription Renewal Information fields before submitting for approval';
				}
				else
				{
					msg = 'Please fill in the MUS Renewal Information fields before submitting for approval';
				}
			}
			else if(!hasPaymentTerms)
			{
				msg = 'Please select the Payment Terms before submitting for approval';
			}	
			isError = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
		}
		
		return page;
	}
	
	public PageReference DoSave()
	{
		//Save button on VF
		PageReference page = null;
		try
		{
			theQuote.Quote_Approval_Process__c = system.now();
			update theQuote;
			//page = DoApprovalProcess();
			page = new pageReference('/apex/vf_productionLicenses?id='+theQuote.Opportunity.Id +'&qtId=' + theQuote.Id) ; 
		}
		catch(Exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return page;
	}
	
	public PageReference DoApprovalProcess()
	{
		//Process for creating the Approval Process
		PageReference page = null;
		try
		{
			// Send Quote to Approval process
	        List<Approval.ProcessSubmitRequest> processes2Submit = new List<Approval.ProcessSubmitRequest>();
	        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
	        req.setComments('Submitting Quote for approval.');
	        req.setObjectId(theQuote.Id);
	        processes2Submit.add(req);
	        
	        List<Approval.ProcessResult> results = Approval.process(processes2Submit);
	        
	        if(results[0].isSuccess())
	        {
	        	page = Close();
	        }
	        else
	        {
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, results[0].getErrors()[0].getMessage() ));
	        }
		}
		catch(Exception e)
		{
			String errorMsg = e.getMessage();
			
			//errorMsg = CleanErrorMsg( errorMsg, 'ALREADY_IN_PROCESS');
			if(errorMsg.contains('ALREADY_IN_PROCESS'))
			{
				errorMsg = 'Quote already in approval process.';
			}
			else if(errorMsg.contains('NO_APPLICABLE_PROCESS'))
			{
				errorMsg = 'No applicable approval process was found for the quote.';
			}
			else
			{
				errorMsg = CleanErrorMsg( errorMsg, 'FIELD_CUSTOM_VALIDATION_EXCEPTION');
				errorMsg = errorMsg.replaceAll(': \\[\\]','');
			}
			
			isError = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
		}
        return page;
	}
	
	public PageReference Close()
	{
    	String newPageUrl = '/apex/QuoteSendToApproval?id=' + theQuote.Id + '&billingcontact=false&close=1';
		PageReference newPage = new PageReference(newPageUrl);
		newPage.setRedirect(true);
		return newPage;
	}
	
	public String CleanErrorMsg(String errorMsg, String keyword)
	{
		if(errorMsg.contains(keyword))
		{
            Integer lastIndex = errorMsg.length();
            if(errorMsg.indexOf(keyword) < errorMsg.lastIndexOf(':'))
            {
                lastIndex = errorMsg.lastIndexOf(':');
            }
            errorMsg = errorMsg.substring(errorMsg.indexOf(keyword) + keyword.length()+2, lastIndex);
        }
        return errorMsg;
	}

	// -----------------------------------------------------------------------------------------------------------------
	// -----------------------------------------------------------------------------------------------------------------
	// -----------------------------------------------------------------------------------------------------------------
	static testmethod void Test01()
	{
		Opportunity opp = new Opportunity(Name = 'Test', StageName = 'Demo', CloseDate = system.today().addDays(1));
		insert opp;
		
		Quote q = new Quote( Name = 'Test', OpportunityId = opp.Id );
		insert q;
		
		PageReference pageRef = Page.QuoteSendToApproval;
		Test.setCurrentPageReference(pageRef);
		pageRef.getParameters().put('id',q.Id);
		pageRef.getParameters().put('billingcontact','false');
		
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(q);
		QuoteSendToApproval_Controller controller = new QuoteSendToApproval_Controller(sc);
		
		controller.isSyncing = true;
		controller.Close();
		controller.CleanErrorMsg('Test 123 Test', '123');
		controller.DoAction();
		controller.DoApprovalProcess();
		
		
		pageRef.getParameters().put('billingcontact','true');
		controller.DoAction();
		controller.DoSave();
		
		opp.StageName = 'Closed Won';
		update opp;
		
		controller.isSyncing = false;
		
		controller.DoAction();
	}
}