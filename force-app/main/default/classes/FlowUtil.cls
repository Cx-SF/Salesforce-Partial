global class FlowUtil
{
  @InvocableMethod
  public static list<string> getClonedLicenseId(list<string> idLst){
      
      /* Lena added ver.210
        idLst[0] contains ['oldLicenseId;currentOpportunityID']
      */
     
     system.debug('-----');
     list<License__c> sltOfLicences = new list<License__c>();
     list<id> idList = new List<id>();
     License__c licensToClone = new License__c();     
      
     licensToClone = [select id
                               ,Name,Issued__c,Account__c,Activation_Date__c,API_Message__c,API_Status__c,Auto_Generate_License__c,Expiration_Date__c,Expiration_Type__c,File_did_not_retrieve__c
                               ,Opportunity__c,Opportunity_Link__c,HID__c,Maximum_lines_of_code__c,Number_of_Auditors__c,Number_Of_Server_Managers__c,Number_of_Servers__c
                               ,Number_of_Companies__c,Number_of_Company_Managers__c,Number_of_Reviewers__c,Number_of_Admin_users__c,Number_of_Engines__c
                               ,Number_of_Scanners__c,Issued_To__c,Issued_to_Email__c,Waiting_for_Update__c, /*Lena added ver.214-start*/ Languages__c, AppSec_Coach_Expiration__c, AppSec_Coach__c 
                               ,OSA_Trial_Expiration__c, OSA_Type__c, OSA__c, Projects__c, Region__c, license_Edition__c /*Lena added ver.214-end*/ 
                                from License__c where id =:idLst[0].substringBefore(';') Limit 1];
     system.debug('----cloned-'+licensToClone);
     License__c newL = new License__c();
     newL = licensToClone.clone();
     newL.Opportunity__c = idLst[0].substringAfter(';'); //Lena added ver.210
     sltOfLicences.add(newL);
      try{
       insert sltOfLicences;                
          
     }catch(exception e){
       system.debug('----err'+e.getmessage()); 
     }
     system.debug('----id-'+sltOfLicences[0].id);
     
      /*Lena added ver.210-start*/
       licensToClone.Status__c = 'Inactive';
       update licensToClone;
       /*Lena added ver.210-end*/
      
      for(License__c lsc:sltOfLicences){
        idList.add(lsc.id);
     }
     return idList;
  }
}