/************************************************************************************** 
Name              : testMethods3
Description       : -
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nevo Harari               26/11/2015               Eyal zarenkin         [SW-16295]
****************************************************************************************/
@isTest(SeeAllData=true)
private class TestMethodsUtil_seeAllData {
   
   static testMethod void  FlowUtil_Test(){

   		ClsObjectCreator cls = new ClsObjectCreator();
   		Account acc = cls.createAccount('AccForTest');
   		Opportunity opp = cls.createOpportunity(acc.ID); 

        opportunity op = [select id from opportunity limit 1];
        contact con = [select id from contact limit 1];
        
        License__c lcs = new  License__c(Name='name',opportunity__c=op.id,Expiration_Type__c='+3',HID__c='looong',Maximum_lines_of_code__c=23,Number_of_Auditors__c=3,Number_of_Reviewers__c=3,Number_of_Admin_users__c=3,Number_Of_Server_Managers__c=4,Issued_To__c=con.id,Number_of_Engines__c=1,Number_of_Scanners__c=2);
        insert lcs;
        list<String> idLst = new list<String>();
        idLst.add(lcs.id +';'+ opp.ID);
        FlowUtil.getClonedLicenseId(idLst); 
    }

}