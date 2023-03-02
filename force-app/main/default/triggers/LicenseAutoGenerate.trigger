/******************************************************************************* 
Name              : LicenseAutoGenerate
Description		  : Auto generates the Post Call on insert of a single License if the Auto Generate License checkbox is checked.
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by	      Related Task/Issue 			 
----------------------------------------------------------------------------------------
1. Hernan          		27/02/2012              			           	[SW-4667]
*******************************************************************************/
trigger LicenseAutoGenerate on License__c (after insert) {
	try{
		if( trigger.size == 1){
			License__c lic = trigger.new[0];
			if( trigger.new[0].Auto_Generate_License__c == true ){
				String errorMsg='';
	            if(lic.HID__c == '' || lic.HID__c == null){
	                errorMsg += '"HID" cannot be empty.<br/>';
	            }
	            
	            if(lic.Account__c == null){
	                errorMsg += '"Account" cannot be empty.<br/>';
	            }
	            
	            if(lic.Opportunity__c == null){
	                errorMsg += '"Opportunity" cannot be empty.<br/>';
	            }
	            
	            if(lic.Number_of_Engines__c <= 0 || lic.Number_of_Engines__c == null){
	                errorMsg += '"Number of Engines" must be greater than 0.<br/>';
	            }
	            
	            if(lic.Number_of_Admin_users__c <= 0 || lic.Number_of_Admin_users__c == null){
	                errorMsg += '"Number of Admins" must be greater than 0.<br/>';
	            }
	            
	            if(lic.Number_of_Auditors__c == null){
	                errorMsg += '"Number of Auditors" cannot be empty.<br/>';
	            }
	            
	            if(lic.Maximum_lines_of_code__c <= 0 || lic.Maximum_lines_of_code__c == null){
	                errorMsg += '"Maximum lines of code" must be greater than 0.<br/>';
	            }
	            
	            if(lic.Languages__c == '' || lic.Languages__c == null){
	                errorMsg += '"Languages" must have at least one selected.<br/>';
	            }
	            
	            if( errorMsg != '' ){
	            	errorMsg = 'In order to generate the License, check the following fields:<br/>' + errorMsg;
	            	trigger.new[0].addError(errorMsg);
	            }
				LicenseWS.CallSendPost(trigger.new[0].Id, Userinfo.getUserId());
			}
		}
	}catch(Exception e){
		trigger.new[0].addError(e.getMessage());
	}
}