@isTest
private class TestMethods 
{
    static testMethod void test_vf_productionLicenses() 
    {
        ClsObjectCreator cls = new ClsObjectCreator();
        
        Account acc1 = cls.returnAccount('Test4323');
        insert acc1;

        Contact con = cls.returnContact(acc1.ID , 'TestA1@test.com');
        insert con;
        
        Opportunity opp1 = new Opportunity(Name='Test', Accountid = acc1.ID, StageName = 'Demo', CloseDate = system.today(), Description = NULL);
        insert opp1;

        Quote q = new Quote( Name = 'Test', OpportunityId = opp1.Id );
        insert q;
        
        License__c lic1 = new License__c(Name='Test', Account__c=acc1.Id, Opportunity__c=opp1.Id, HID__c = '1', Days_To_Expire__c = 0, Region__c = 'America', Number_of_Engines__c = 1, 
                                        Number_of_Admin_users__c = 1,   Number_of_Auditors__c = 1, Number_of_Scanners__c = 1, Number_of_Reviewers__c = 1, Comments__c = 'Test', 
                                        Maximum_lines_of_code__c = 1, Languages__c = 'Test', Expiration_Type__c = '+14', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided');
        insert new List<License__c>{lic1};

        vf_productionLicenses controller ; 

        System.Test.setCurrentPage(Page.vf_productionLicenses) ; 
        Apexpages.currentPage().getParameters().put('Id', opp1.Id);
        Apexpages.currentPage().getParameters().put('qtId', q.Id);
        controller = new vf_productionLicenses();
        
        controller.selectedLicense = null ; 
        controller.DoNext() ;
        
        controller.selectedLicense = 'Service' ; 
        controller.DoNext() ;
        
        controller.selectedLicense = 'Annual' ; 
        controller.DoNext() ;
        
        controller.selectedLicense = 'Perpetual' ; 
        controller.DoNext() ;
        
        controller.getApprovalProcessURL() ;
        controller.getIsMultiPeriodLicenseItemsitems() ;
        controller.dummyisMultiPeriodLicenseItems() ;
        
        controller.loadDefaultValues() ;
        controller.loadDefaultValuesBasic() ;  
        controller.loadDefaultValuesAdvanced() ;
        
        controller.license.Expiration_Date__c = null ;
        controller.DoSave() ; 
        
        controller.license.Expiration_Date__c = system.today() ;
        controller.Numberoflicenses.Issued_To__c = null ; 
        controller.DoSave() ;  
        
        controller.oppDesc = 'bla bla' ; 
        controller.license.Expiration_Date__c = system.today() ;
        controller.Numberoflicenses.Issued_To__c = con.Id ;  
        controller.DoSave() ;  
        
        
        /// For failure
        opp1.StageName = 'Closed Won' ;
        update opp1;
        System.Test.setCurrentPage(Page.vf_productionLicenses) ; 
        Apexpages.currentPage().getParameters().put('Id', opp1.Id);
        controller = new vf_productionLicenses();
    }
    

    static testMethod void test_vf_absolute() 
    {
        ClsObjectCreator cls = new ClsObjectCreator();
        Account acc1 = cls.returnAccount('Test6534');
        insert acc1;

        Opportunity opp1 = new Opportunity(Name='Test', StageName = 'Demo', CloseDate = system.today());
        insert opp1;
        
        License__c lic1 = new License__c(Name='Test', Account__c=acc1.Id, Opportunity__c=opp1.Id, HID__c = '1', Days_To_Expire__c = 0, Region__c = 'America', Number_of_Engines__c = 1, 
                                        Number_of_Admin_users__c = 1,   Number_of_Auditors__c = 1, Number_of_Scanners__c = 1, Number_of_Reviewers__c = 1, Comments__c = 'Test', 
                                        Maximum_lines_of_code__c = 1, Languages__c = 'Test', Expiration_Type__c = '+14', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided');
        insert new List<License__c>{lic1};

        vf_absolute controller ; 

        System.Test.setCurrentPage(Page.vf_absolute) ; 
        controller = new vf_absolute();
        controller.init() ; 
        
        System.Test.setCurrentPage(Page.vf_absolute) ; 
        Apexpages.currentPage().getParameters().put('id', lic1.Id);
        controller = new vf_absolute();
        controller.init() ; 
        
        System.Test.setCurrentPage(Page.vf_absolute) ; 
        Apexpages.currentPage().getParameters().put('id', lic1.Id);
        Apexpages.currentPage().getParameters().put('oppMode', 'true');
        controller = new vf_absolute();
        controller.init() ;
        
        System.Test.setCurrentPage(Page.vf_absolute) ; 
        Apexpages.currentPage().getParameters().put('id', lic1.Id);
        Apexpages.currentPage().getParameters().put('oppMode', 'true');
        Apexpages.currentPage().getParameters().put('oppId', opp1.Id);
        controller = new vf_absolute();
        controller.init() ;
    }

    static testMethod void CheckLeadCompanyNameInAccount_Test() {

        ClsObjectCreator cls = new ClsObjectCreator();
        
        Account acc1 = cls.returnAccount('Test Account 1563');
        insert acc1;
        
        Lead ld = cls.returnLead('Test11@test.com');
        insert ld;
        
        ld = [SELECT Id, Existing_Account__c FROM Lead WHERE Id = :ld.Id LIMIT 1][0];
        
        //system.assertEquals(ld.Existing_Account__c, acc1.Id);
    }
    
    static testMethod void CheckAccountNameInLead_Test() {
        
        ClsObjectCreator cls = new ClsObjectCreator();

        MonitorRecursionClass.setFullRegistrationFlowMonitor(true);
        Lead ld = cls.returnLead('Test12@test.com');
        insert ld;
        
        
        Account acc1 = cls.returnAccount('Test Account 14342');
        insert acc1;
        
        ld = [SELECT Id, Existing_Account__c FROM Lead WHERE Id = :ld.Id LIMIT 1][0];
        
        //system.assertEquals(ld.Existing_Account__c, acc1.Id);
    }
    
    
    static testmethod void LicenseAutoGenerate_Test(){
        License__c lic = new License__c();
        lic.Auto_Generate_License__c = true;
        lic.Delivered_By__c = 'Test';
        String errorMsg='';
        try{
            insert lic;
        }catch(Exception e){
            errorMsg = e.getMessage();
        }
        //system.assertEquals( true, errorMsg.contains('generate the License') );
    }
    
    static testmethod void PrimaryCampaignOnLeadConvert_Test(){
        
        ClsObjectCreator cls = new ClsObjectCreator();

        Lead ld = cls.returnLead('Test13@test.com');
        insert ld;
        
        Campaign camp1 = new Campaign(Name='Test01');
        Campaign camp2 = new Campaign(Name='Test02');
        insert new List<Campaign>{camp1, camp2};
        
        CampaignMember cm1 = new CampaignMember( CampaignId = camp1.Id, LeadId = ld.Id );
        insert cm1;
        
        CampaignMember cm2 = new CampaignMember( CampaignId = camp2.Id, LeadId = ld.Id );
        insert cm2;
        
        Database.Leadconvert lc = new Database.Leadconvert();
        lc.setLeadId(ld.Id);
        lc.setConvertedStatus([SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1][0].MasterLabel);
        
        Database.convertLead(lc);
    }
    
    static testmethod void OpportunityPrimaryCampaignOnLeadConvert_Test(){

        ClsObjectCreator cls = new ClsObjectCreator();

        Lead ld = cls.returnLead('Test14@test.com');
        insert ld;
        
        Campaign camp1 = new Campaign(Name='Test01');
        Campaign camp2 = new Campaign(Name='Test02');
        insert new List<Campaign>{camp1, camp2};
        
        CampaignMember cm1 = new CampaignMember( CampaignId = camp1.Id, LeadId = ld.Id );
        insert cm1;
        
        CampaignMember cm2 = new CampaignMember( CampaignId = camp2.Id, LeadId = ld.Id );
        insert cm2;
        
        Database.Leadconvert lc = new Database.Leadconvert();
        lc.setLeadId(ld.Id);
        lc.setConvertedStatus([SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1][0].MasterLabel);
        
        Database.convertLead(lc);
        
        Id conId = [SELECT ConvertedContactId FROM Lead WHERE Id =: ld.Id][0].ConvertedContactId;
        
        Opportunity opp = new Opportunity(Name = 'Test Opp', CloseDate = system.today(), StageName = 'Prospecting');
        insert opp;   
        
        insert new OpportunityContactRole(OpportunityId = opp.Id, IsPrimary = true, ContactId = conId);
        
        update opp;     
    }
    
    /*
    //Trigger was commented
    static testmethod void LeadStatusContactedMeeting_Test(){
        Lead ld1 = new Lead(LastName='Test01', Company='Test01', Country='USA', Status = 'Open', Lead_Origin__c = 'Outbound', Sales_Rep__c = Userinfo.getUserId());
        Lead ld2 = new Lead(LastName='Test02', Company='Test02', Country='USA', Status = 'Contacted - Meeting scheduled', Lead_Origin__c = 'Outbound', Sales_Rep__c = Userinfo.getUserId());
        Lead ld3 = new Lead(LastName='Test03', Company='Test03', Country='USA', Status = 'Open', Lead_Origin__c = 'Outbound', Sales_Rep__c = Userinfo.getUserId());
        insert new List<Lead>{ld1,ld2,ld3};
        
        system.assertEquals( 0, [SELECT Id FROM Task WHERE WhoId = :ld1.Id ].size() );
        system.assertEquals( 1, [SELECT Id FROM Task WHERE WhoId = :ld2.Id ].size() );
        system.assertEquals( 0, [SELECT Id FROM Task WHERE WhoId = :ld3.Id ].size() );
        
        ld3.Status = 'Contacted - Meeting scheduled';
        update ld3;
        
        system.assertEquals( 0, [SELECT Id FROM Task WHERE WhoId = :ld1.Id ].size() );
        system.assertEquals( 1, [SELECT Id FROM Task WHERE WhoId = :ld2.Id ].size() );
        system.assertEquals( 1, [SELECT Id FROM Task WHERE WhoId = :ld3.Id ].size() );
    }

    static testmethod void CancelWorkflowForConversionOnLeadConvert_Test(){
        Lead ld = new Lead(LastName='L1', Company='Test Account 1');
        insert ld;
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc,false);
        
        ld = [SELECT CancelWorkflowForConversion__c FROM Lead WHERE Id = :ld.Id LIMIT 1][0];
        
        system.assertEquals(true, lcr.isSuccess());
        system.assertEquals(true, ld.CancelWorkflowForConversion__c);
    }
    */
}