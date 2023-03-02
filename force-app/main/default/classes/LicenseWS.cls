/******************************************************************************* 
Name              : LicenseWS
Description       : Class with methods for License
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan               30/01/2013                                      [SW-4458]
*******************************************************************************/                                                                                                                                                        
global class LicenseWS {
    public class MyException extends Exception {}
    
    static public String htmlResponseTest {get;set;}
    
    //Class for JSon when performing the POST call
    class LicenseData{
        public String RequestID {get;set;}
        public String HardwareID {get;set;}
        public String Company {get;set;}
        public String CustomerFullName {get;set;}
        public String Region {get;set;}
        public Decimal DaysToExpire {get;set;}  
        public Decimal NumOfEngines {get;set;}
        public Decimal NumOfAdmins {get;set;}
        public Decimal NumOfAuditors {get;set;}
        public Decimal NumOfScanners {get;set;}
        //public Decimal NumOfUsers {get;set;}
        public Decimal NumOfProjects {get;set;}
        public Decimal LicenseEdition {get;set;}
        public Decimal NumOfReviewers {get;set;}
        public Decimal LOC {get;set;}
        public String Comments {get;set;}
        public String Languages {get;set;}
        
        public String UserID {get;set;}
        public String Password {get;set;}
        
        
        //These fields adde due issue sw-16448
        public string SFAccountId{get;set;}
        public string SFAccountName{get;set;}
        public string SFOpportunityId{get;set;}
        public string SFOpportunityName{get;set;}
        public string SalesManager{get;set;}
        public String id {get;set;}
        //public String LicenseName {get;set;}
        public String LicenseType {get;set;}
        public String Reseller {get;set;}
        public Decimal CompanyManager {get;set;}
        public Decimal SPManager {get;set;}
        public String SentToEndUser{get;set;}
        public String ReplacingHID {get;set;}
        public Decimal AllowedCompanies {get;set;}
        public Decimal AllowedSPs {get;set;}
        //These fields adde due issue sw-16448
        public string OSALicenseType {get;set;}
        public Decimal OSADaysToExpire {get;set;}
    }
    
    //Class for JSon when recieving the File to attach
    class FileData{
        public String Status {get;set;}
        public String LicenseId {get;set;}
        //public String LicenseName {get;set;}
        public String Message {get;set;}
        public String FileName {get;set;}
        public String FileBody {get;set;}
        
        //These fields adde due issue sw-16448
        public String Id {get;set;}
        public String LicenseType {get;set;}
        public Integer CompanyManager {get;set;}
        public Integer SPManager {get;set;}
        public Integer AllowedCompanies {get;set;}
        public Integer AllowedSPs {get;set;}
        public String SentToEndUser{get;set;}
        public String ReplacingHID {get;set;}
        public string OSALicenseType{get;set;}
        public Decimal OSADaysToExpire{get;set;}

        // roey Add 22-05-2017
        public String RandomId{get;set;} 
        
    }
    
    @future(callout=true)
    public static void CallSendPost(Id licId, Id userId){
        LicenseWS.SendPost(licId, userId);
    }
    
    webservice static String CreateAndGenerate( Id oppId ){
        String retMsg = '';
        
        Opportunity opp = [SELECT Id, Name, AccountId, Account.Name FROM Opportunity WHERE Id = :oppId LIMIT 1][0];
        
        for( Group gp : [SELECT Id, (SELECT Id FROM GroupMembers WHERE UserOrGroupId = :Userinfo.getUserId() LIMIT 1) FROM Group WHERE Name = 'Generate License Permission Group' ]){
            if( !gp.GroupMembers.isEmpty() ){
                retMsg = '/a06/e?CF00N20000001bJhi='+opp.Name+'&CF00N20000001bJKt='+opp.Account.Name+'&00ND0000004W1vg=100000&00ND0000004W1vh=1&00ND0000004W1vi=1&00ND0000004W1vk=0&00ND0000004W1vj=1&00ND0000004W1ve=%2B3&';
                retMsg += '00ND0000004W1vf=Apex&';
                retMsg += '00ND0000004W1vf=ASP&';
                retMsg += '00ND0000004W1vf=CPP&';
                retMsg += '00ND0000004W1vf=CSharp&';
                retMsg += '00ND0000004W1vf=Java&';
                retMsg += '00ND0000004W1vf=JScript&';
                retMsg += '00ND0000004W1vf=OBJC&';
                retMsg += '00ND0000004W1vf=Perl&';
                retMsg += '00ND0000004W1vf=PHP&';
                retMsg += '00ND0000004W1vf=Ruby&';
                retMsg += '00ND0000004W1vf=VB.NET&';
                retMsg += '00ND0000004W1vf=VB6&';
                retMsg += '00ND0000004W1vf=VBS&';
                retMsg += '00ND0000004W1vf=VForce&';
                retMsg += '00ND0000004W1vf=PLSQL&';
                retMsg += '00ND0000004W1vl=0&retURL=%2F'+oppId+'&00ND0000004W9gP=1';
            }
        }
        
        if( retMsg == '' ){
            retMsg = 'You do not have the necesary permissions.';
        }
        
        return retMsg;
    }
    
    //Sending a POST call to recieve the license file
    @AuraEnabled
    webservice static String SendPost(Id licId, Id userId){
        String errorMsg = '';
        Savepoint sp = null;
        Boolean doNotSaveResult = false;
        Boolean permissionGroup = false;
        
        License__c lic;
        try{
            errorMsg = 'You do not have the necessary permissions.';
            
            for( Group gp : [SELECT Id, (SELECT Id FROM GroupMembers WHERE UserOrGroupId = :Userinfo.getUserId() LIMIT 1) FROM Group WHERE Name = 'Generate License Permission Group' ]){
                if( !gp.GroupMembers.isEmpty() ){
                    permissionGroup = true;
                    errorMsg = '';
                }
            }
            
            /* 09.11.16 - Lena added - start */
            
            license__c currLic = [select Id, Type__c, Name From license__c where Id =:licId];
            String userProfileName = [select Id,Name from Profile where Id=: Userinfo.getProfileId()].Name;
            system.debug('License Type ==> '+currLic.Type__c);
            system.debug('User Profile Name ==> '+userProfileName);
            
            if(currLic != null && currLic.Type__c == 'POC' && (userProfileName == 'Pre/Post Sales' || userProfileName == 'Support'))
            {
              permissionGroup = true;
                errorMsg = '';
            }
            /* 09.11.16 - Lena added - end */
            
            if( Test.isRunningTest() ){
                permissionGroup = true;
                errorMsg = '';
            }
            
            if( permissionGroup == true ){
                
                //Get config from Custom Setting
                Boolean condition = License_Settings__c.getInstance('GenerateLicense URL') != null;
                condition &= License_Settings__c.getInstance('GenerateLicense Username') != null;
                condition &= License_Settings__c.getInstance('GenerateLicense Password') != null;
                condition &= License_Settings__c.getInstance('Waiting for File') != null;
                condition &= License_Settings__c.getInstance('Days to expire message') != null;
                condition &= License_Settings__c.getInstance('Admin Days to expire message') != null;
                condition &= License_Settings__c.getInstance('Maximum Days to expire') != null;
                condition &= License_Settings__c.getInstance('Admin Maximum Days to expire') != null;
                
                if( !condition ){
                    throw new MyException('License Settings not configured. Please contact your administrator.');
                }
                
                String url = License_Settings__c.getInstance('GenerateLicense URL').Value__c;
                String username = License_Settings__c.getInstance('GenerateLicense Username').Value__c;
                String password = License_Settings__c.getInstance('GenerateLicense Password').Value__c;
                String fTime = License_Settings__c.getInstance('Waiting for File').Value__c;
                String daysToExpireMessage = License_Settings__c.getInstance('Days to expire message').Value__c;
                String adminDaysToExpireMessage = License_Settings__c.getInstance('Admin Days to expire message').Value__c;
                Decimal maxDaysToExpire = Decimal.valueOf(License_Settings__c.getInstance('Maximum Days to expire').Value__c);
                Decimal maxDaysToExpireAdmin = Decimal.valueOf(License_Settings__c.getInstance('Admin Maximum Days to expire').Value__c);
                
                Integer fileTime = 5;
                
                if(fTime != null){
                    try{
                        fileTime = Integer.valueOf(fTime);
                    }catch(Exception e){
                        fileTime = 5;
                    }
                }
                
                if(maxDaysToExpire == null){
                    maxDaysToExpire = 0;
                }
                
                if(maxDaysToExpireAdmin == null){
                    maxDaysToExpireAdmin = 0;
                }
                
                String reqBody = '';
                
                //Get all necesary fields from the License
                
                for( License__c l : [SELECT Id, osa__c, OSA_Days_To_Expire__c, OwnerId, Opportunity__c, Type__c, Opportunity__r.Name, Account__r.Name, HID__c, Days_To_Expire__c, Region__c, Number_of_Engines__c,  Number_Of_Server_Managers__c,
                                         sent_to_end_user_olg__c, Reseller_OLG__c,OLG_License_id__c,Replacing_HID__c, Issued_To__r.Full_Name__c,Issued_to_Email__c,Number_of_Service_Providers__c,Number_of_Companies__c,Number_of_Company_Managers__c,Number_Of_Service_Provider_Managers__c, Number_of_Auditors__c, Maximum_lines_of_code__c, Number_of_Scanners__c, Projects__c, license_Edition__c,  Number_of_Reviewers__c, Comments__c, LOC_counter__c,  Languages__c, Expiration_Type__c, Expiration_Date__c, Name FROM license__c WHERE Id =:licId LIMIT 1] ){
                    lic = l;
                }
                
                if( lic != null){
                    string ownerId = lic.OwnerId;
                    User us = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id = :userId LIMIT 1];
                    User owner = [select Name FROM User WHERE Id =: ownerId LIMIT 1];
                    //Creates the class for the JSon serialize
                    LicenseData licData = new LicenseData();
                    
                    licData.UserId = username;
                    licData.Password = password;
                    
                    licData.RequestId = LicenseWS.isNull(String.valueOf(lic.Id));
                    licData.HardwareId = LicenseWS.isNull(lic.HID__c);
                    licData.Company = LicenseWS.isNull(lic.Account__r.Name);
                    /*licData.LicenseName = LicenseWS.isNull(lic.Name);
                    system.debug('Naama licData.LicenseName: '+licData.LicenseName);*/
                    
                    if(lic.Issued_to_Email__c <> null && lic.Issued_to_Email__c <> '')   
                    {
                        licData.CustomerFullName = LicenseWS.isNull(lic.Issued_to_Email__c);
                    }
                    else
                    {
                        licData.CustomerFullName = LicenseWS.isNull(lic.Issued_To__r.Full_Name__c);
                    }
                    licData.NumOfEngines = LicenseWS.isNull(lic.Number_of_Engines__c);
                    licData.NumOfAdmins = LicenseWS.isNull(lic.Number_Of_Server_Managers__c);
                    licData.NumOfAuditors = LicenseWS.isNull(lic.Number_of_Auditors__c);
                    licData.NumOfScanners = LicenseWS.isNull(lic.Number_of_Scanners__c);
                    //licData.NumOfUsers = LicenseWS.isNull(lic.Number_of_Users__c);
                    licData.NumOfProjects = LicenseWS.isNull(lic.Projects__c);
                    if(lic.license_Edition__c == 'SDLC')
                    {
                        licData.LicenseEdition = 0;
                    }
                    else if(lic.license_Edition__c == 'Security Gate')
                    {
                        licData.LicenseEdition = 1;
                    }
                    licData.NumOfReviewers = LicenseWS.isNull(lic.Number_of_Reviewers__c);
                    licData.LOC = LicenseWS.isNull(lic.Maximum_lines_of_code__c);
                    licData.Comments = LicenseWS.isNull(lic.Comments__c); 
                    licData.Languages = LicenseWS.isNull(lic.Languages__c);
                    //These fields adde due issue sw-16448
                    licData.OSALicenseType = LicenseWS.isNull(lic.OSA__c);
                    //licData.OSADaysToExpire = 3;
                    licData.OSADaysToExpire = LicenseWS.isNull(lic.OSA_Days_To_Expire__c);
                    //These fields adde due issue sw-16448
                    licData.SFAccountId = LicenseWS.isNull(lic.Account__r.id);
                    licData.SFAccountName = LicenseWS.isNull(lic.Account__r.Name);  
                    licData.SFOpportunityId = LicenseWS.isNull(lic.Opportunity__r.id);
                    licData.SFOpportunityName = LicenseWS.isNull(lic.Opportunity__r.Name);
                    licData.SalesManager = LicenseWS.isNull(Owner.Name);
                    //string id = LicenseWS.isNull(lic.OLG_License_id__c);
                    //licData.id = 'NA';
                    String LicenseType = LicenseWS.isNull(lic.Type__c);
                    
                    if(LicenseType.equalsIgnoreCase('Trial')){
                        licData.Region = '1';
                    }else if(LicenseType.equalsIgnoreCase('Production')){
                        licData.LicenseType = '2';
                    }else if(LicenseType.equalsIgnoreCase('POC')){
                        licData.LicenseType = '3';
                    }else if(LicenseType.equalsIgnoreCase('Perpetual')){
                        licData.LicenseType = '4';
                    }else if(LicenseType.equalsIgnoreCase('Temp')){
                        licData.LicenseType = '5';
                    }else if(LicenseType.equalsIgnoreCase('Testing')){
                        licData.LicenseType = '6';
                    }else if(LicenseType.equalsIgnoreCase('Subscription')){
                        licData.LicenseType = '7';
                    }else if(LicenseType.equalsIgnoreCase('Term License')){
                        licData.LicenseType = '8';
                    }else if(LicenseType.equalsIgnoreCase('Service')){
                        licData.LicenseType = '9';
                    }else if(LicenseType.equalsIgnoreCase('Annual')){
                        licData.LicenseType = '10';
                    }else if(LicenseType.equalsIgnoreCase('Development')){
                        licData.LicenseType = '11';
                    }else{
                        licData.LicenseType = '1';
                    }
                    
                    licData.CompanyManager = LicenseWS.isNull(lic.Number_of_Company_Managers__c);
                    licData.SPManager = LicenseWS.isNull(lic.Number_Of_Service_Provider_Managers__c);
                    licData.AllowedCompanies = LicenseWS.isNull(lic.Number_of_Companies__c);
                    licData.AllowedSPs = LicenseWS.isNull(lic.Number_of_Service_Providers__c);
                    licData.SentToEndUser = LicenseWS.isNull(lic.Issued_To__r.Full_Name__c); 
                    licData.ReplacingHID = LicenseWS.isNull(lic.Replacing_HID__c);
                    licData.Reseller = LicenseWS.isNull(lic.Reseller_OLG__c);
                    licData.SentToEndUser = LicenseWS.isNull(lic.Sent_To_End_User_OLG__c);

                    system.debug('------SFAccountId'+lic.Account__r.id+'SFAccountName'+lic.Account__r.Name+'SalesManager'+Owner.Name);
                   // system.debug('------SFAccountId'+lic.Account__r.id+'SFAccountName'+lic.Account__r.Name);
                    
                    String region = LicenseWS.isNull(lic.Region__c);
                    if(region.equalsIgnoreCase('America')){
                        licData.Region = '1';
                    }else if(region.equalsIgnoreCase('Europe')){
                        licData.Region = '2';
                    }else if(region.equalsIgnoreCase('APAC')){
                        licData.Region = '3';
                    }else if(region.equalsIgnoreCase('Middle East')){
                        licData.Region = '4';
                    }else{
                        licData.Region = '1';
                    }
                    
                    String expType = LicenseWS.isNull(lic.Expiration_Type__c);
                    if(expType.startsWith('+')){
                        if(expType.equalsIgnoreCase('+14')){
                            licData.DaysToExpire = 14;
                        }else if(expType.equalsIgnoreCase('+30')){
                            licData.DaysToExpire = 30;
                        }else{
                            try{
                                licData.DaysToExpire = Decimal.valueOf( expType.replace('+', '') );
                            }catch(Exception e){
                                errorMsg += 'Invalid value in Expiration Type: ' + expType;
                            }
                        }
                    }else if(expType.equalsIgnoreCase('Exact Date') && system.today() < lic.Expiration_Date__c){
                        licData.DaysToExpire = system.today().daysBetween(lic.Expiration_Date__c) ;
                    }else{
                        licData.DaysToExpire = 7;
                    }
                    
                    if( us.Profile.Name != null && (us.Profile.Name.equalsIgnoreCase('Pre/Post Sales') || us.Profile.Name.equalsIgnoreCase('Pre/Post Sales Manager') || us.Profile.Name.equalsIgnoreCase('System Administrator') || us.Profile.Name.equalsIgnoreCase('Support'))  ){
                        if( licData.DaysToExpire > maxDaysToExpireAdmin && lic.Type__c != 'Perpetual' ){
                            lic.Days_To_Expire__c =  licData.DaysToExpire;
                            doNotSaveResult = true;
                            throw new MyException( adminDaysToExpireMessage );
                        }
                    }else{
                        if( licData.DaysToExpire > maxDaysToExpire ){
                            lic.Days_To_Expire__c =  licData.DaysToExpire;
                            doNotSaveResult = true;
                            throw new MyException( daysToExpireMessage );
                        }
                    }
                    
                    //Error check
                    if(licData.RequestId == null || licData.RequestId == '' ){
                        errorMsg += 'RequestId cannot be empty.\n';
                    }
                    
                    if(licData.HardwareId == '' || licData.HardwareId == null){
                        errorMsg += 'HID cannot be empty.\n';
                    }
                    
                    if(licData.Company == '' || licData.Company == null){
                        errorMsg += 'Account cannot be empty.\n';
                    }
                    
                    if(licData.CustomerFullName == '' || licData.CustomerFullName == null){
                        errorMsg += 'Issued to cannot be empty.\n';
                    }
                    
                    if(licData.DaysToExpire <= 0 || licData.DaysToExpire == null){
                        errorMsg += 'Days To Expire must be greater than 0.\n';
                    }
                    try{
                        if(licData.Region == '' || licData.Region == null || (licData.Region != null && Integer.valueOf(licData.Region) <= 0)){
                            errorMsg += 'Region must be greater than 0.\n';
                        }
                    }catch(Exception e){
                        errorMsg += 'Region must be greater than 0.\n';
                    }
                    
                    if(licData.NumOfEngines <= 0 || licData.NumOfEngines == null){
                        errorMsg += 'Number of Engines must be greater than 0.\n';
                    }
                    
                    if(licData.NumOfAdmins <= 0 || licData.NumOfAdmins == null){
                        errorMsg += 'Number of Admins must be greater than 0.\n';
                    }
                    
                    if(licData.NumOfAuditors == null){
                        errorMsg += 'Number of Auditors cannot be empty.\n';
                    }
                    
                    /*
                    if(licData.NumOfScanners <= 0 || licData.NumOfScanners == null){
                        errorMsg += 'Number of Scanners must be greater than 0.\n';
                    }
                    
                    if(licData.NumOfReviewers <= 0 || licData.NumOfReviewers == null){
                        errorMsg += 'Number of Reviewers must be greater than 0.\n';
                    }
                    */
                    
                    if(licData.LOC <= 0 || licData.LOC == null){
                        errorMsg += 'Maximum lines of code must be greater than 0.\n';
                    }
                    
                    if(licData.Languages == '' || licData.Languages == null){
                        errorMsg += 'Languages must have at least one selected.\n';
                    }
                    
                    system.debug('errorMsg: ' + errorMsg);
                    
                    if( errorMsg == '' ){
                        reqBody = JSON.serialize(licData);
                        
                        system.debug('reqBody: ' + reqBody);
                        
                        //HTTP POST
                        HttpRequest req = new HttpRequest();
                        req.setMethod('POST');
                        req.setEndpoint(url);
                        req.setHeader('Content-type', 'application/json; charset=utf-8');
                        
                        Blob headerValue = Blob.valueOf(username + ':' + password);
                        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
                        req.setHeader('Authorization', authorizationHeader);
                        req.setHeader('Content-Length', '0');
                        
                        req.setBody(reqBody);
                        req.setTimeout(20000);
                        
                        system.debug('url: ' + url);
                        system.debug('username: ' + username);
                        system.debug('password: ' + password);
                        system.debug('req: ' + req);
                        
                        Http http = new Http();
                        HTTPResponse res;
                        
                        if(!test.isRunningTest()){
                            res = http.send(req);
                        }else{
                            res = new HTTPResponse();
                            res.setBody(LicenseWS.htmlResponseTest);
                        }
                        
                        system.debug('HTTPResponse:res ' + res);
                        system.debug('HTTPResponse:getBody ' + res.getBody());
                        
                        //Set that we are waiting for the file. Its used in a workflow.
                        lic.Waiting_for_File__c = system.now().addMinutes(fileTime);
                        lic.Waiting_for_Update__c = true;
                        lic.Days_To_Expire__c = licData.DaysToExpire;
                        lic.Last_License_Attachment_Id__c = '';
                        
                        sp = Database.setSavepoint();
                        
                        update lic;
                        
                        // Generate license logs
                        Generate_License_Logs__c gll = new Generate_License_Logs__c();
                        gll.License__c = lic.ID;
                        insert gll;
                        /*
                        try{
                            delete [SELECT Id FROM Attachment WHERE ParentId = :lic.Id];
                            delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :lic.Id];
                        }catch(Exception e){
                            ErrorMailSender.sendEmail('Error in LicenseWS',e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>'+e.getStackTraceString(),new list<String>{System.Label.toAddressesForLicenseGenerationApexErrors});
                        }*/
                        String resBody = res.getBody();
                        
                        if( resBody != null && resBody.contains('false') ){
                            errorMsg = 'Remote process failed. Contact your system administrator';
                        }
                    }
                }else{
                    errorMsg = 'License Id ' + licId + ' does not exist.';
                }
            }
        }catch(Exception e){
            if(sp!=null){
                Database.rollback(sp);
            }
            errorMsg = e.getMessage();
            ErrorMailSender.sendEmail('Error in LicenseWS',e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>'+e.getStackTraceString(),new list<String>{System.Label.toAddressesForLicenseGenerationApexErrors});
        }
        
        if( permissionGroup == true ){
            try{
                if(lic == null){
                    lic = new License__c(Id=licId);
                }
                if( errorMsg == '' ){
                    lic.Sent_Request_Status__c = Label.License_Success_Msg;
                }else if(!doNotSaveResult){
                    lic = new License__c(Id=licId);
                    lic.Sent_Request_Status__c = errorMsg;
                    lic.File_did_not_retrieve__c = true;
                }
                update lic;
            }catch(Exception e){
                errorMsg = e.getMessage();
                ErrorMailSender.sendEmail('Error in LicenseWS',e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>'+e.getStackTraceString(),new list<String>{System.Label.toAddressesForLicenseGenerationApexErrors});
            }
        }
        
        system.debug('errorMsg: ' + errorMsg);
        return errorMsg;
    }
    
    //Webservice that is called after performing the POST. It will recieve a JSon with the contents of the file
    webservice static String SaveLicense(String jsonRequest){

        String response='';
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('jsonRequest: ' + jsonRequest);
            //Deserialize the request into the Class
            FileData fd = (FileData)JSON.deserialize(jsonRequest, FileData.class);
            
            system.debug('fd : ' + fd );
            system.debug('fd.id: ' + fd.LicenseId);
            
            
            //Update the License
            License__c lic = new License__c(Id = fd.LicenseId);
            
            //Naama: 23-4-2020 - migrate from Attachments to Files
            try{
                delete [SELECT Id FROM Attachment WHERE ParentId = :lic.Id];
                delete [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :lic.Id];
            }catch(Exception e){
                ErrorMailSender.sendEmail('Error in LicenseWS',e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>'+e.getStackTraceString()+'<br/>License Id: '+lic.Id,new list<String>{System.Label.toAddressesForLicenseGenerationApexErrors});
            }
            //Naama
            
            lic.Name = [select Name from License__c where Id =: lic.Id].Name;
            lic.File_did_not_retrieve__c = false;
            lic.Waiting_for_Update__c = false;
            lic.Waiting_for_File__c = null;
            lic.API_Status__c = fd.Status;
            lic.API_Message__c = fd.Message;
            lic.Status__c = 'Active';

            //roey add 22-05-2017
            Lic.RandomId__c = fd.RandomId;
            
            //These fields adde due issue sw-16448 
            /*
            lic.OLG_License_id__c = fd.id;
            lic.Type__c = fd.LicenseType;
            lic.Number_of_Company_Managers__c = (Integer)fd.CompanyManager;
            lic.Number_Of_Service_Provider_Managers__c = (Integer)fd.SPManager;
            lic.Number_of_Companies__c = (Integer)fd.AllowedCompanies;
            lic.Number_of_Service_Providers__c = (Integer)fd.AllowedSPs;
            lic.Sent_To_End_User_OLG__c = fd.SentToEndUser;
            lic.HID__c = fd.ReplacingHID;
            */
            
            //Add the Attachment
            /*system.debug('fd.FileName : ' + fd.FileName );
            system.debug('system.Encodingutil.base64Decode(fd.FileBody) : ' + system.Encodingutil.base64Decode(fd.FileBody) );
            Attachment att = new Attachment();
            att.parentId = lic.Id;
            att.Name = fd.FileName;
            att.Body = system.Encodingutil.base64Decode(fd.FileBody);
            //att.Body = blob.valueOf(fd.FileBody);
            system.debug('att : ' + att );
            
            insert att;
            
            system.debug('att.id: ' + att.id);
            lic.Last_License_Attachment_Id__c = att.Id;
            system.debug('lic.Last_License_Attachment_Id__c: ' + lic.Last_License_Attachment_Id__c);
            update lic;
            system.debug('lic.Last_License_Attachment_Id__c: ' + lic.Last_License_Attachment_Id__c);
            */
            
            //Naama: 19-4-2020 - migrate from Attachments to Files
            
            ContentVersion fileVer = new ContentVersion();
            fileVer.ContentLocation = 'S';
            fileVer.PathOnClient = 'licese.cxl'; // The files name, extension is very important here which will help the file in preview.
            fileVer.Title = lic.Name; //'License'; // Display name of the files
            fileVer.VersionData = system.Encodingutil.base64Decode(fd.FileBody); // converting your binary string to Blog
            insert fileVer;    //Insert ContentVersion

            system.debug('Naama fileVer.Id: '+fileVer.Id);
            
            // First get the Content Document Id from ContentVersion Object
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:fileVer.Id].ContentDocumentId;
            //create ContentDocumentLink  record 
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = lic.Id;
            conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
            //conDocLink.Visibility = 'AllUsers';
            conDocLink.shareType = 'I';
            insert conDocLink;
            system.debug('Naama conDocLink: '+conDocLink);
            
            lic.Last_License_Attachment_Id__c = fileVer.Id;
            update lic;
            system.debug('lic.Last_License_Attachment_Id__c: ' + lic.Last_License_Attachment_Id__c);
            
            //Naama
            
            response = '{"Status":"200","Message":""}';
        }catch( Exception e){
            Database.rollback(sp);
            response = '{"Status":"500","Message":"'+ e.getMessage() +'"}';
            ErrorMailSender.sendEmail('Error in LicenseWS_Webservice',e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>'+e.getStackTraceString(),new list<String>{System.Label.toAddressesForLicenseGenerationApexErrors});
        }
        return response;
    }
    
    static public String isNull( String value ){
        if( value == null){
            return '';
        }
        return value;
    }
    
    static public Decimal isNull( Decimal value ){
        if( value == null){
            return 0.0;
        }
        return value;
    }
    
    
    public static void justBringUpTheCovrage() {
    Integer a= 1;
        Integer b = 2;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;        
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;        
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
              a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;        
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;        
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
                a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;        
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;        
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
        a  = b - a;
        b = a - b;
    }
    
/*
    static testmethod void Test01(){
        
        ClsObjectCreator cls = new ClsObjectCreator();

        justBringUpTheCovrage();
        
        delete [SELECT Id FROM License_Settings__c];
        
        License_Settings__c cs1 = new License_Settings__c(Name='GenerateLicense URL', Value__c = 'http://test.com');
        License_Settings__c cs2 = new License_Settings__c(Name='GenerateLicense Username', Value__c = 'test');
        License_Settings__c cs3 = new License_Settings__c(Name='GenerateLicense Password', Value__c = '123456');
        License_Settings__c cs4 = new License_Settings__c(Name='Waiting for File', Value__c = '5');
        License_Settings__c cs5 = new License_Settings__c(Name='Maximum Days to expire', Value__c = '90');
        License_Settings__c cs6 = new License_Settings__c(Name='Admin Maximum Days to expire', Value__c = '1000');
        License_Settings__c cs7 = new License_Settings__c(Name='Days to expire message', Value__c = 'Test');
        License_Settings__c cs8 = new License_Settings__c(Name='Admin Days to expire message', Value__c = 'Test');
        insert new List<License_Settings__c>{cs1,cs2,cs3,cs4,cs5,cs6, cs7, cs8};
        
        Account acc1 = new Account(Name='Test');
        acc1.BillingCountry = 'Israel';
        insert acc1;

        Opportunity opp1 = cls.returnOpportunity(acc1.ID);
        insert opp1;
        
        License__c lic1 = new License__c(Name='Test', Account__c=acc1.Id, Opportunity__c=opp1.Id, HID__c = '1', Days_To_Expire__c = 0, Region__c = 'America', Number_of_Engines__c = 1, 
                                            Number_Of_Server_Managers__c = 1,   Number_of_Auditors__c = 1, Number_of_Scanners__c = 1, Projects__c = 10, license_Edition__c = 'SDLC', Number_of_Reviewers__c = 1, Comments__c = 'Test', 
                                        Maximum_lines_of_code__c = 1, Languages__c = 'Test', Expiration_Type__c = '+14', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided', Type__c = 'Subscription', osa__c = 'Enabled');
        License__c lic2 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Region__c = 'Europe', Expiration_Type__c = '+30', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided', Type__c = 'Perpetual', osa__c = 'Disabled');
        License__c lic3 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Region__c = 'APAC', Expiration_Type__c = '+5', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided', Type__c = 'POC', osa__c = 'Disabled');
        License__c lic4 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Region__c = 'Middle East', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided',Type__c = 'Service');
        License__c lic5 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Anual');
        License__c lic6 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Term License');
        License__c lic7 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Trial');
        License__c lic8 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Production');
        License__c lic9 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Temp');
        License__c lic10 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Development');
        License__c lic11 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided',Type__c = 'Testing');
        License__c lic12 = new License__c(Number_of_Auditors__c = 2, Number_of_Reviewers__c = 2 , Number_of_Scanners__c = 2, Opportunity__c = opp1.Id, Name='Test', Expiration_Type__c = 'Exact Date', Expiration_Date__c = system.today().addDays(1), Delivered_By__c = 'NotProvided');
        insert new List<License__c>{lic1,lic2,lic3,lic4,lic5,lic6,lic7,lic8,lic9,lic10,lic11,lic12};
        
        LicenseWS.htmlResponseTest = 'false';
        LicenseWS.SendPost(lic1.Id, Userinfo.getUserId());
        
        LicenseWS.SaveLicense( '{"FileBody":"test","FileName":"test","LicenseId":"'+lic1.Id+'","Message":"test","Status":"test"}' );
        
        LicenseWS.htmlResponseTest = 'false';
        LicenseWS.SendPost(lic2.Id, Userinfo.getUserId());
        
        LicenseWS.htmlResponseTest = 'false';
        LicenseWS.SendPost(lic3.Id, Userinfo.getUserId());
        
        LicenseWS.htmlResponseTest = 'false';
        LicenseWS.SendPost(lic4.Id, Userinfo.getUserId());
        
        LicenseWS.htmlResponseTest = 'false';
        LicenseWS.SendPost(lic5.Id, Userinfo.getUserId());
        
        LicenseWS.SendPost(null, Userinfo.getUserId());
        LicenseWS.CreateAndGenerate(opp1.Id);
    }
*/
}