@IsTest 
public with sharing class ClsObjectCreator 
{
	public ClsObjectCreator() 
	{
		
	}

	//ACCOUNT
	public Account createAccount(String name)
	{
		Account acc = new Account();
		acc.Name = name;
		acc.BillingCountry = 'Israel';

		insert acc;
		return acc;
	}

	public Account returnAccount(String name)
	{
		Account acc = new Account();
		acc.Name = name;
		acc.BillingCountry = 'Israel';

		return acc;
	}

	//CONTACT

	public Contact CreateContact(ID accID , String eml)
	{
		Contact con = new Contact();
		con.LastName = 'testContact';
		con.AccountId = accID;
		con.MailingCountry = 'Israel';
		con.Email = eml;
		con.Customer_Type__c = 'Other';

		insert con;
		return con;
	}

	public Contact returnContact(ID accID , String eml)
	{
		Contact con = new Contact();
		con.LastName = 'testContact';
		con.AccountId = accID;
		con.MailingCountry = 'Israel';
		con.Email = eml;
		con.Customer_Type__c = 'Other';

		return con;
	}


	//LEAD
	public Lead createLead(String eml)
	{
		Lead led = new Lead();
		led.LastName = 'leadTest';
		led.Customer_Type__c = 'SAAS';
		led.Company='TestCompany';
		led.Email = eml;
		led.Country = 'Israel';

		insert led;
		return led;
	}

	public Lead returnLead(String eml)
	{
		Lead led = new Lead();
		led.LastName = 'returnLeadTest';
		led.Customer_Type__c = 'SAAS';
		led.Company='returnLeadTestCompany';
		led.Email = eml;
		led.Country = 'Israel';

		return led;
	}


	//Opportunity
	public Opportunity createOpportunity(ID accID)
	{
		Opportunity opp = new Opportunity();
		opp.Name='TestOpp';
		opp.StageName = 'Value Proposition';
		opp.CloseDate = system.today();
		opp.AccountId = accID;
		opp.Paying_entity__c = 'End User';
		opp.Type = 'New Business';
		opp.Customer_Type__c = 'On Premise';
		opp.License_Type__c	= 'Subscription';
		opp.ForecastCategoryName = 'Pipeline';
		opp.CurrencyIsoCode = 'USD';

        Id recType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
		opp.RecordTypeId = recType;

		insert opp;
		return opp;
	}

	public Opportunity returnOpportunity(ID accID)
	{
		Opportunity opp = new Opportunity();
		opp.Name='TestOpp';
		opp.StageName = 'Value Proposition';
		opp.CloseDate = system.today();
		opp.AccountId = accID;
		opp.Paying_entity__c = 'End User';
		opp.Type = 'New Business';
		opp.Customer_Type__c = 'On Premise';
		opp.License_Type__c	= 'Subscription';
		opp.ForecastCategoryName = 'Pipeline';
		opp.CurrencyIsoCode = 'USD';
		//opp.Hidden_LeadId__c ='00Q261234567890';

        Id recType = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
		opp.RecordTypeId = recType;
		return opp;
	}

    //QUOTE
	public Quote createQuote(ID accID , ID oppID)
	{
		Quote qut = new Quote();
		qut.Name = 'Test';
		qut.OpportunityId = oppID;
		//qut.AccountId = accID;

		insert qut;
		return qut;
	}

	public Quote returnQuote(ID accID , ID oppID)
	{
		Quote qut = new Quote();
		qut.Name = 'Test';
		qut.OpportunityId = oppID;
		//qut.AccountId = accID;

		return qut;
	}

	public PS_Entitlement__c returnEntitlment(Id accountId,Id OppId) {
		
		PS_Entitlement__c entitlment = new PS_Entitlement__c();
        entitlment.Name = 'PS Test';
        entitlment.EntitlementAccount__c =accountId;
        entitlment.WDCX_Quantity__c = 4;
        entitlment.WDCX_Hours_per_unit__c = 5;
        entitlment.WDCX_Opportunity__c = OppId;
        entitlment.WDCX_Hours_Used__c =0;
        return entitlment;
	}
	
	public Idea returnFR(Id accountId,Id CommunityId ) {
		
		Idea FR = new Idea();
		FR.Main_Interested_Account__c = accountId;
		FR.CommunityId = CommunityId;
		FR.title = 'test FR';
		
		return FR;
	}

	public Contract returnContract(Id accountId,Id oppId ) {
		
		contract cont = new contract();
		cont.accountId = accountId;
		cont.SBQQ__Opportunity__c = oppId;
	
		
		return cont;
	}
	
}