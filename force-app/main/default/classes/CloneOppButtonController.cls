/*
    ClassName:      CloneOppButtonController
    Description:    Controller for Visualforce page to implement button to call an Apex method
    
    Change History
    
    Version  Date       Init    Description of Change
    ------- ------      ------  --------------------------------------------
    1.0     25-02-10    RAC     Initial Version
    
    ************************************************************************************** 
	Name              : CloneOppButtonController
	Description       : -
	Revision History  : -
	Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
	----------------------------------------------------------------------------------------
	2. Hanit(Update)	   12/10/2015          Eyal	                  [SW-15641]
    ************************************************************************************
*/
public with sharing class CloneOppButtonController {

   /* private final ApexPages.StandardController theController;

    public CloneOppButtonController(ApexPages.StandardController stdController) {
        theController = stdController;
    }

    public PageReference autoRun() {
        Id cloneId; 

        // Call the Apex Method we want to invoke and then show the new page
        try {
            // TODO: Uncomment the action you wish to use and comment out the other one.
            //cloneId = CloneOpportunity.clone((Opportunity)theController.getRecord());
            cloneId = CloneOpportunity.cloneWithProducts(theController.getId());
            //Opportunity opp = new Opportunity(Id = theController.getId(),Renew_Opportunity__c = cloneId); 
            Opportunity opp = new Opportunity(Id = theController.getId()); //Update by Rafa 22/02/23 
            update opp;
        }
        catch (Exception e) {
            system.debug('Error = ' + e.getMessage() + '  ' + e.getStackTraceString());
            theController.getRecord().addError('Opportunity could not be cloned, check debug log for errors');
        }

        // New page is id of the cloned object if it worked, or previous page otherwise
        if (cloneId == null) cloneId = theController.getId();
        
        return new PageReference('/' + cloneId);
    }
    
    // Unit Test - code coverage only - update according to your implementation
    // NOTE! - if you have additional mandatory fields you will need to include them below
    static testMethod void testController() {
        //Account acct = [select id from Account where Name = 'Service Wise' limit 1];
        //acct.Name = 'Acc Test';
       // update acct; 
        ClsObjectCreator cls = new ClsObjectCreator();
        Account acc = cls.createAccount('AccTestController');

        Opportunity opp = cls.returnOpportunity(acc.ID);
        opp.Name = '$$Service Wise- License Flow Tests$$';
        insert opp;

        Opportunity opp1 = [select id from Opportunity where Name = '$$Service Wise- License Flow Tests$$' limit 1];
        /*opp1.AccountId = acct.Id;
        opp1.Name = 'Opp Test';
        opp1.Amount = 100;
        opp1.CloseDate = System.today();
        opp1.StageName = 'Closed Won';
        opp1.Type='Renewal';
        opp1.CurrencyIsoCode='USD';
        opp1.Customer_Type__c='SAAS';
        opp1.License_Type__c='Perpetual';
        opp1.Payment_collected_amount__c=1000;*/
      //  update opp1;
        /*Test.startTest() ;
        ApexPages.StandardController sc = new ApexPages.StandardController(opp1);
        CloneOppButtonController controller = new CloneOppButtonController(sc);
        controller.autorun();
        Test.stopTest() ;
    } */

}