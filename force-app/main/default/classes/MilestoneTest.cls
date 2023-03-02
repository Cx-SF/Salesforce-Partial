/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
*
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*/
@isTest(seeAllData=true)
private class MilestoneTest{
    
    static testMethod void TestCompleteMilestoneCase(){
        
        List<Account> acts = new List<Account>();
        Account myAcc = new Account(Name='TestAct', phone='1001231234');
        acts.add(myAcc);
        
        Account busAcc = new Account(Name = 'TestForMS', phone='4567890999');
        acts.add(busAcc);
        insert acts;
        
        Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = busAcc.id, MailingCountry='Israel',OtherCountry='Israel',email='test@test11.com');
        system.debug('cont'+cont);
        insert(cont);
        
        Id contactId = cont.Id;
        
        Entitlement entl = new Entitlement(Name='TestEntitlement', AccountId=busAcc.Id);
        insert entl;
        
        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name,IsVersionDefault FROM SlaProcess WHERE IsActive = true Limit 1];
        if (lstEntitlementProcess.size()>0)
        {
            system.debug('lstEntitlementProcess[0].id:'+lstEntitlementProcess[0].id);
            entl.SlaProcessId = lstEntitlementProcess[0].id;
            update entl;        
        }
        system.debug('***Michal TEST entl.SlaProcessId:'+entl.SlaProcessId);
        String entlId;
        if (entl != null)
            entlId = entl.Id; 
        
        List<Case> cases = new List<Case>{};
            if (entlId != null){
                Case c = new Case(Subject = 'Test Case with Entitlement ', AccountId = busAcc.id, ContactId = cont.id, EntitlementId=entl.id, slaStartDate=system.now());
                cases.add(c);
            }
        
        List<CaseMilestone> CaseMilestones=[select Id, completionDate,caseId from CaseMilestone where completionDate =null and MilestoneType.Name='First Response'];
        system.debug('CaseMilestone:'+CaseMilestones);
        if (cases.isEmpty()==false){
            insert cases;
            List<Id> caseIds = new List<Id>();
            for (Case cL : cases){
                caseIds.add(cL.Id);
            }
            caseIds.add(CaseMilestones[0].caseId);
            milestoneUtils.completeMilestone(caseIds, 'First Response', System.now());
        }
    }
    
    static testMethod void testCompleteMilestoneViaCase(){
        
        // Perform data preparation
        Account acc = new account(name='Test Account');
        insert acc;
        
        Contact oContact = new Contact(FirstName = 'Test', LastName = 'LastName', phone='4567890999', accountid = acc.id, MailingCountry='Israel',OtherCountry='Israel',email='test@test33.com');
        insert oContact;
        
        Entitlement entl = new entitlement(name='Test Entilement',accountid=acc.id,type='Gateway Support', StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)));
        insert entl;
        
        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name,IsVersionDefault FROM SlaProcess WHERE IsActive = true Limit 1];
        if (lstEntitlementProcess.size()>0)
        {
            entl.SlaProcessId = lstEntitlementProcess[0].id;
            update entl;        
        }
        
        String entlId;
        if (entl != null)
            entlId = entl.Id;
        List<Case> cases = new List<Case>{};
            for(Integer i = 0; i < 1; i++){
                Case c = new Case(Subject = 'Test Case ' + i);
                cases.add(c);
                if (entlId != null){
                    c = new Case(Subject = 'Test Case with Entitlement ', AccountId = acc.id, ContactId = oContact.id, EntitlementId=entl.id, slaStartDate=system.now());
                    cases.add(c);
                }
            }
        
        List<CaseMilestone> CaseMilestones=[select Id, completionDate,caseId from CaseMilestone where completionDate =null and MilestoneType.Name='First Response'];
        List<Case>mycase=[select id,Contact.Email from case where id=:CaseMilestones[0].caseId];
        system.debug('CaseMilestone:'+CaseMilestones);
        List<case> caseIds = new List<case>();
        if (cases.isEmpty()==false){
            insert cases;         
            for (Case cL : cases){
                caseIds.add(cL);
            }
            caseIds.addall(mycase);
        }
        
        // Now create emailmessage objects for them.
        List<EmailMessage> emails = new List<EmailMessage>();
        for(case c : caseIds){
            system.debug('caseIds:'+c);
            emails.add(new EmailMessage(parentId = c.id,ToAddress=c.Contact.Email));
        }
        Test.startTest();
        if(emails.isEmpty()==false)
            database.insert(emails);
        Test.stopTest();
        
    }
}