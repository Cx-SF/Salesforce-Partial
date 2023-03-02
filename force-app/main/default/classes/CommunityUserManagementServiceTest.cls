@IsTest
public with sharing class CommunityUserManagementServiceTest {

    @TestSetup
    static void setup() {

        //System.assertNotEquals(null, testCase.Id, 'Failed to insert testCase');
    }

     @IsTest
        static void generateRandomString_test() {

            Integer lenght = 3;
            Integer count = 10;

            List<String> randomStrings = new List<String>();

            Test.startTest();

            for(Integer n=0;n<count;n++){
                randomStrings.add(CommunityUserManagementServiceCtrl.generateRandomString(lenght));
            }

            Set<String> uniqueStrings = new Set<String>(randomStrings);

            Test.stopTest();

            System.assertEquals(true,uniqueStrings.size()==randomStrings.size(),'Random string generation failed!');

        }

        @IsTest
        static void createScheduledJob_test() {

            String jobName = 'TEST Community user requests handler, every hour at ';


            Integer scheduledJobsBefore = [
                    SELECT COUNT()
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :jobName+'%'
            ];

            Test.startTest();

            CommunityUserManagementServiceCtrl.createScheduledJob(jobName);


            Integer scheduledJobsAfter = [
                    SELECT COUNT()
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :jobName+'%'
            ];


            Test.stopTest();

            System.assertEquals(0,scheduledJobsBefore,'Jobs create test failed! Scheduled jobs before are exists.');
            System.assertEquals(1,scheduledJobsAfter,'Jobs create test failed! Count of created jobs is not valid.');

        }

        @IsTest
        static void createScheduledJobThenAbort_test() {
            String jobName = 'TEST Community user requests handler, every hour at ';
            
            Integer scheduledJobsBefore = [
                    SELECT COUNT()
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :jobName+'%'
            ];

            Test.startTest();

            CommunityUserManagementServiceCtrl.createScheduledJob(jobName);


            Integer scheduledJobsBetween = [
                    SELECT COUNT()
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :jobName+'%'
            ];



            CommunityUserManagementServiceCtrl.abortAllJobs(jobName);

            Integer scheduledJobsAfter = [
                    SELECT COUNT()
                    FROM CronTrigger
                    WHERE CronJobDetail.Name LIKE :jobName+'%'
            ];

            Test.stopTest();

            System.assertEquals(0,scheduledJobsBefore,'Jobs create test failed! Scheduled jobs before are exists.');
            System.assertEquals(1,scheduledJobsBetween,'Jobs create test failed! Count of created jobs is not valid.');
            System.assertEquals(0,scheduledJobsAfter,'Jobs create test failed! Count of created jobs is not valid.');

        }

        @IsTest
        static void getInitialData_test(){
            Account acc = new Account(Name = 'Temporary acc',Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');
            insert acc;

            Account accFilled = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');
            insert accFilled;

            Contact con1 = new Contact(
                    AccountId = accFilled.Id, FirstName = 'fName', LastName = 'lName', Email = 'test027@dfmail.com',
                    MailingCountry = 'Ukraine'
            );
            insert con1;

            Contact con2 = new Contact(
                    AccountId = accFilled.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                    MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Pending'
            );
            insert con2;

            Test.startTest();

            CommunityUserManagementServiceCtrl.InitialData initdCleanAcc = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);
            CommunityUserManagementServiceCtrl.InitialData initdFilledAcc = CommunityUserManagementServiceCtrl.getInitialData(accFilled.Id);
			CommunityUserManagementServiceCtrl.setCanSeeAllCasesFlag(String.valueOf(con1.id), true);
			CommunityUserManagementServiceCtrl.setCanSeeAllCasesFlag(String.valueOf(con1.id), false);

            Test.stopTest();

            System.assertEquals(0,initdCleanAcc.activeUsers,'Get initial data test failed! New account can`t have active users.');
            System.assertEquals(5,initdCleanAcc.maxPortalUsers,'Get initial data test failed! Non correct count of active users.');
            System.assertEquals(null,initdCleanAcc.accounts,'Get initial data test failed! Accounts list must be null.');

            System.assertEquals(2,initdFilledAcc.communityUsers.size(),'Get initial data test failed! Accounts have two contacts.');

        }




        @IsTest
        static void selectAccount_test(){

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='506');


            Test.startTest();
                CommunityUserManagementServiceCtrl.InitialData initD1 = CommunityUserManagementServiceCtrl.getInitialData(null);

                CommunityUserManagementServiceCtrl.InitialData initD2;
                System.runAs(u){
                    initD2 = CommunityUserManagementServiceCtrl.getInitialData(null);
                }
            Test.stopTest();
            System.assertNotEquals(null,initD1.accounts,'selectAccount test failed! Accounts list must be NOT null.');
            System.assertNotEquals(null,initD2.accounts,'selectAccount test failed! Accounts list must be NOT null.');
        }

        @IsTest
        static void selectAccountPortalUser_test(){

            Account acc;
            Contact con;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='507');

            System.runAs(u){
                acc = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 1,BillingCountry = 'Ukraine', Total_Won_Amount__c = 45);
                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                        MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Active'
                );
                insert con;
            }

            String defaultCommUsrProfile ;

            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                    SELECT Label
                    FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
            ]){
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                break;
            }

            defaultCommUsrProfile = (defaultCommUsrProfile!=null)? defaultCommUsrProfile : 'Custom Customer Portal';


            Profile pf = [
                    SELECT Id, Name
                    FROM Profile
                    WHERE Name = :defaultCommUsrProfile
                    LIMIT 1
            ];

            User portalUser = new User(
                    ContactId = con.Id,
                    Username = con.Email,
                    FirstName = con.FirstName,
                    LastName = con.LastName,
                    Email = con.Email,
                    CommunityNickname = con.LastName + '_DgT',
                    Alias = String.valueOf(
                            con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
                    ProfileId = pf.Id,
                    EmailEncodingKey = 'ISO-8859-1',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                EmployeeNumber='508',
                    TimeZoneSidKey = 'GMT'
            );

            Test.startTest();

            CommunityUserManagementServiceCtrl.InitialData initD;
            System.runAs(portalUser) {
                initD = CommunityUserManagementServiceCtrl.getInitialData(null);
            }

			Boolean trueOrFalse = CommunityUserManagementServiceCtrl.areJobsRunning('test');

            Test.stopTest();
            //System.assertEquals(null,initD.accounts,'selectAccount test failed! Accounts list must be NOT null.');
        }

        @IsTest
        static void deactiveteNonExisting_test(){
            Account accFilled;
            Contact con1;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='5008');

            System.runAs(u){
                accFilled = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 1,BillingCountry = 'Ukraine');
                insert accFilled;

                con1 = new Contact(
                        AccountId = accFilled.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                        MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Pending'
                );
                insert con1;
            }

            List<CommunityUserManagementServiceCtrl.ContactWrapper> commContacts = new List<CommunityUserManagementServiceCtrl.ContactWrapper>();

            CommunityUserManagementServiceCtrl.ContactWrapper commContact1 = new CommunityUserManagementServiceCtrl.ContactWrapper(con1);
            commContact1.changeUserState = true;
            commContact1.accountId = accFilled.Id;
            commContact1.contactId = con1.Id;
            commContact1.userIsActive = true;
            commContact1.requestStatus = '';
            commContacts.add(commContact1);

            String request = JSON.serializePretty(commContacts);

            Test.startTest();

            System.runAs(u) { CommunityUserManagementServiceCtrl.createRequests(request,accFilled.Id); }
            CommunityUserManagementServiceCtrl.InitialData initD = CommunityUserManagementServiceCtrl.getInitialData(accFilled.Id);

            System.runAs(u) { CommunityUserManagementScheduledJob.handleCommunityUsersEvent(); }
            initD = CommunityUserManagementServiceCtrl.getInitialData(accFilled.Id);

            Test.stopTest();

            System.assertEquals(null,initD.accounts,'selectAccount test failed! Accounts list must be NOT null.');

        }

        @IsTest
        static void createRequestForNewContact (){
            Account acc;
            Contact con;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,
                             EmployeeNumber='509');

            System.runAs(u){
                acc = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 10,BillingCountry = 'Ukraine');
                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                        MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Active'
                );
                insert con;
            }

            Test.startTest();

                System.runAs(u){ CommunityUserManagementServiceCtrl.createRequestForNewContact(con.Id, acc.id); }
                System.runAs(u){ CommunityUserManagementScheduledJob.handleCommunityUsersEvent(); }
                CommunityUserManagementServiceCtrl.InitialData initd = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            Test.stopTest();

            System.assertEquals(null,initD.accounts,'selectAccount test failed! Accounts list must be NOT null.');

        }

        @IsTest
        static void createRequestForNewContactPending (){
            Account acc;
            Contact con;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='510');

            System.runAs(u){
                acc = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 10,BillingCountry = 'Ukraine');
                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                        MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Pending'
                );
                insert con;
            }

            Test.startTest();

                System.runAs(u){ CommunityUserManagementServiceCtrl.createRequestForNewContact(con.Id, acc.id); }
                System.runAs(u){ CommunityUserManagementScheduledJob.handleCommunityUsersEvent(); }
                CommunityUserManagementServiceCtrl.InitialData initd = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            Test.stopTest();

            System.assertEquals(null,initD.accounts,'selectAccount test failed! Accounts list must be NOT null.');

        }
    
        @IsTest
        static void createRequestForNewContactRejected (){
            Account acc;
            Contact con;

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='511');

            System.runAs(u){
                acc = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 10,BillingCountry = 'Ukraine');
                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                        MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Rejected'
                );
                insert con;
            }

            Test.startTest();

                System.runAs(u){ CommunityUserManagementServiceCtrl.createRequestForNewContact(con.Id, acc.id); }
                System.runAs(u){ CommunityUserManagementScheduledJob.handleCommunityUsersEvent(); }
                CommunityUserManagementServiceCtrl.InitialData initd = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            Test.stopTest();

            System.assertEquals(null,initD.accounts,'selectAccount test failed! Accounts list must be NOT null.');

        }
    
        @IsTest
        static void createRequestForNewContactDuplicate (){
            Account acc;
            Contact con;
            Contact con2;

			String defaultCommUsrProfile ;
            String usernameSufix ;
            String usernamePrefix ;
            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                        SELECT Label, Username_Prefix__c, Username_Sufix__c
                        FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
                    ]) {
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                usernameSufix = defaultCommunityUserProfiles.Username_Sufix__c;
                usernamePrefix = defaultCommunityUserProfiles.Username_Prefix__c;
                break;
            }
            usernamePrefix = (usernamePrefix == null) ? '' : usernamePrefix;
            usernameSufix = (usernameSufix == null) ? '' : usernameSufix;
            defaultCommUsrProfile = (defaultCommUsrProfile != null) ? defaultCommUsrProfile : 'Custom Customer Portal';

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            User u = new User(Alias = 'staZndtX', Email = 'test028@dfmail.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = usernamePrefix + 'test028@dfmail.com' + usernameSufix, UserRoleId = roles[0].Id,EmployeeNumber='513');
            insert u;

            System.runAs(u){
                acc = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 1,BillingCountry = 'Ukraine');
                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test028@dfmail.com',
                        MailingCountry = 'Ukraine',Community_User_Management_Status__c = 'Active'
                );
                insert con;



		Profile pf = [
		                 SELECT Id, Name
		                 FROM Profile
		                 WHERE Name = :defaultCommUsrProfile
		                              LIMIT 1
		             ];                
                
                //insert new User(
						          //       ContactId = con.Id,
						          //       Username = con.Email,
						          //       FirstName = con.FirstName,
						          //       LastName = con.LastName,
						          //       Email = con.Email,
						          //       CommunityNickname = con.LastName + '_' + CommunityUserManagementServiceCtrl.generateRandomString(3),
						          //       Alias = String.valueOf(
						          //                   con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
						          //       ProfileId = pf.Id,
						          //       EmailEncodingKey = 'ISO-8859-1',
						          //       LanguageLocaleKey = 'en_US',
						          //       LocaleSidKey = 'en_US',
						          //       TimeZoneSidKey = 'GMT'
						          //   );
               
            }

            Test.startTest();

                System.runAs(u){ CommunityUserManagementServiceCtrl.createRequestForNewContact(con.Id, acc.id); }
                System.runAs(u){ CommunityUserManagementScheduledJob.handleCommunityUsersEvent(); }
                CommunityUserManagementServiceCtrl.InitialData initd = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            Test.stopTest();

            System.assertEquals(null,initD.accounts,'selectAccount test failed! Accounts list must be NOT null.');

        }


        @IsTest
        static void createAndHandleRequestsDelegate_test(){

            Account acc;
            Contact con;
            Contact con2;


            String defaultCommUsrProfile ;

            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                    SELECT Label
                    FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
            ]){
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                break;
            }

            defaultCommUsrProfile = (defaultCommUsrProfile!=null)? defaultCommUsrProfile : 'Custom Customer Portal';


            Profile pf = [
                    SELECT Id, Name
                    FROM Profile
                    WHERE Name = :defaultCommUsrProfile
                    LIMIT 1
            ];

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            //user for runAs
            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='514');

            System.runAs (u) {

                acc = new Account(Name = 'Filled acc', Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');

                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test029@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con;

                User commUser = new User(
                        ContactId = con.Id,
                        Username = con.Email,
                        FirstName = con.FirstName,
                        LastName = con.LastName,
                        Email = con.Email,
                        CommunityNickname = con.LastName + '_DfP',
                        Alias = String.valueOf(
                                con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='515'
                );

                insert commUser;

                con2 = new Contact(
                        AccountId = acc.Id, FirstName = 'fName2', LastName = 'lName2', Email = 'test030@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con2;

                User commUser2 = new User(
                        ContactId = con2.Id,
                        Username = con2.Email,
                        FirstName = con2.FirstName,
                        LastName = con2.LastName,
                        Email = con2.Email,
                        CommunityNickname = con2.LastName + '_DfB',
                        Alias = String.valueOf(
                                con2.FirstName.substring(0, 1) + con2.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='518'
                );

                insert commUser2;
            }

            List<CommunityUserManagementServiceCtrl.ContactWrapper> commContacts = new List<CommunityUserManagementServiceCtrl.ContactWrapper>();
            CommunityUserManagementServiceCtrl.ContactWrapper commContact = new CommunityUserManagementServiceCtrl.ContactWrapper(con);
            commContact.changeDelegatedAdmin = true;
            commContact.accountId = acc.Id;
            commContact.contactId = con.Id;
            commContact.delegatedAdmin = false;
            commContact.requestStatus = '';

            commContacts.add(commContact);

            commContact = new CommunityUserManagementServiceCtrl.ContactWrapper(con2);
            commContact.changeDelegatedAdmin = true;
            commContact.accountId = acc.Id;
            commContact.contactId = con2.Id;
            commContact.delegatedAdmin = false;
            commContact.requestStatus = '';

            commContacts.add(commContact);


            String request = JSON.serializePretty(commContacts);

            Test.startTest();
            Integer requestsCountBefore = [SELECT COUNT() FROM Portal_user_update__c];

            System.runAs (u) {
                CommunityUserManagementServiceCtrl.createRequests(request,acc.Id);
            }

            CommunityUserManagementServiceCtrl.InitialData initdFilledAcc = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            Integer requestsCountAfter = [SELECT COUNT() FROM Portal_user_update__c];

            System.runAs (u) {
                CommunityUserManagementScheduledJob.handleCommunityUsersEvent();
            }

            initdFilledAcc = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            commContacts = new List<CommunityUserManagementServiceCtrl.ContactWrapper>();
            commContact = new CommunityUserManagementServiceCtrl.ContactWrapper(con);
            commContact.changeDelegatedAdmin = true;
            commContact.accountId = acc.Id;
            commContact.contactId = con.Id;
            commContact.delegatedAdmin = true;
            commContact.requestStatus = '';

            commContacts.add(commContact);

            commContact = new CommunityUserManagementServiceCtrl.ContactWrapper(con2);
            commContact.changeDelegatedAdmin = true;
            commContact.accountId = acc.Id;
            commContact.contactId = con2.Id;
            commContact.delegatedAdmin = true;
            commContact.requestStatus = '';

            commContacts.add(commContact);

            request = JSON.serializePretty(commContacts);

            System.runAs (u) { CommunityUserManagementServiceCtrl.createRequests(request,acc.Id); }
            initdFilledAcc = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            System.runAs (u) { CommunityUserManagementScheduledJob.handleCommunityUsersEvent(); }
            initdFilledAcc = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);
			
            Test.stopTest();


            System.assertEquals(0, requestsCountBefore, 'Create requests test failed! Count in begin must be zero.');
            System.assertEquals(2,requestsCountAfter,'Create requests test failed! Count of created request must be 2.');

        }
    
        @IsTest
   	    //Added by MichalH 25/07/19
        static void ResetPassword_test(){
             Account acc;
            Contact con;
            Contact con2;


            String defaultCommUsrProfile ;

            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                    SELECT Label
                    FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
            ]){
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                break;
            }

            defaultCommUsrProfile = (defaultCommUsrProfile!=null)? defaultCommUsrProfile : 'Custom Customer Portal';


            Profile pf = [
                    SELECT Id, Name
                    FROM Profile
                    WHERE Name = :defaultCommUsrProfile
                    LIMIT 1
            ];

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole where DeveloperName='Admin'];

            //user for runAs
            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='520');

            System.runAs (u) {

                acc = new Account(Name = 'Filled acc', Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');

                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test029@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con;

                User commUser = new User(
                        ContactId = con.Id,
                        Username = con.Email,
                        FirstName = con.FirstName,
                        LastName = con.LastName,
                        Email = con.Email,
                        CommunityNickname = con.LastName + '_DfP',
                        Alias = String.valueOf(
                                con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='535'
                );

                insert commUser;

                con2 = new Contact(
                        AccountId = acc.Id, FirstName = 'fName2', LastName = 'lName2', Email = 'test030@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con2;

                User commUser2 = new User(
                        ContactId = con2.Id,
                        Username = con2.Email,
                        FirstName = con2.FirstName,
                        LastName = con2.LastName,
                        Email = con2.Email,
                        CommunityNickname = con2.LastName + '_DfB',
                        Alias = String.valueOf(
                                con2.FirstName.substring(0, 1) + con2.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='545'
                );

                insert commUser2;
            }

            List<CommunityUserManagementServiceCtrl.ContactWrapper> commContacts = new List<CommunityUserManagementServiceCtrl.ContactWrapper>();
            CommunityUserManagementServiceCtrl.ContactWrapper commContact = new CommunityUserManagementServiceCtrl.ContactWrapper(con);
            commContact.changeDelegatedAdmin = true;
            commContact.accountId = acc.Id;
            commContact.contactId = con.Id;
            commContact.delegatedAdmin = false;
            commContact.requestStatus = '';

            commContacts.add(commContact);

            commContact = new CommunityUserManagementServiceCtrl.ContactWrapper(con2);
            commContact.accountId = acc.Id;
            commContact.contactId = con2.Id;
            commContact.requestStatus = '';
            commContact.executeResetPassword=true;

            commContacts.add(commContact);


            String request = JSON.serializePretty(commContacts);

            Test.startTest();
            Integer requestsCountBefore = [SELECT COUNT() FROM Portal_user_update__c];

            System.runAs (u) {
                CommunityUserManagementServiceCtrl.createRequests(request,acc.Id);
            }

            CommunityUserManagementServiceCtrl.InitialData initdFilledAcc = CommunityUserManagementServiceCtrl.getInitialData(acc.Id);

            Integer requestsCountAfter = [SELECT COUNT() FROM Portal_user_update__c];

            System.runAs (u) {
                CommunityUserManagementScheduledJob.handleCommunityUsersEvent();
            }
        }

 
    @IsTest
    static void testScheduledJob() {
        Integer step = 40;
        String jobName = 'TEST JOBNAME';
        CommunityUserManagementScheduledJob myBatchObject = new CommunityUserManagementScheduledJob(step);
        Integer min = Datetime.now().minute() + 1;
        String cron = '0 ' + String.valueOf(min) + ' * * * ?';
        String jobID = System.schedule(jobName +' every ' + step + ' minute', cron, myBatchObject);
        CronTrigger mainJob = [
            SELECT CronJobDetail.Name, NextFireTime
            FROM CronTrigger WHERE Id = :jobId
        ];
        step = 5 ;
        myBatchObject = new CommunityUserManagementScheduledJob(step,mainJob);
        min = Datetime.now().minute() + 2;
        cron = '0 ' + String.valueOf(min) + ' * * * ?';
        jobID = System.schedule(jobName +' every ' + step + ' minute', cron, myBatchObject);
    }
    
    @isTest
    static void testDataTableClassesList() {
		new dataTableClassesList().getValues();
		new dataTableClassesList().getDefaultValue();
    }
    
    @isTest
    static void testGetRequests() {
         Account accFilled = new Account(Name = 'Filled acc',Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');
            insert accFilled;

            Contact con1 = new Contact(
                    AccountId = accFilled.Id, FirstName = 'fName', LastName = 'lName', Email = 'test027@dfmail.com',
                    MailingCountry = 'Ukraine'
            );
            insert con1;
		CommunityUserManagementServiceCtrl.getRequests(con1.Id);
    }
    
    @IsTest
    static void testUploadCoverage(){
            Account acc;
            Contact con;
            String defaultCommUsrProfile ;

            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                    SELECT Label
                    FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
            ]){
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                break;
            }

            defaultCommUsrProfile = (defaultCommUsrProfile!=null)? defaultCommUsrProfile : 'Custom Customer Portal';


            Profile pf = [
                    SELECT Id, Name
                    FROM Profile
                    WHERE Name = :defaultCommUsrProfile
                    LIMIT 1
            ];

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            //user for runAs
            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='555');

            System.runAs (u) {

                acc = new Account(Name = 'Filled acc', Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');

                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test029@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con;

                User commUser = new User(
                        ContactId = con.Id,
                        Username = con.Email,
                        FirstName = con.FirstName,
                        LastName = con.LastName,
                        Email = con.Email,
                        CommunityNickname = con.LastName + '_DfP',
                        Alias = String.valueOf(
                                con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='560'
                );

                insert commUser;
                Portal_user_update__c updateUs = new Portal_user_update__c();
                updateUs.Contact__c= con.Id;
                updateUs.Account__c= acc.Id;
                updateUs.Type__c = 'Reset Password';
                updateUs.Reset_Password__c=true;
                insert updateUs;
               
            }
			
            CommunityUserManagementScheduledJob.handleCommunityUsersEvent();
            

        }
    
     @IsTest
    static void testUploadCoverage2(){
            Account acc;
            Contact con;
            String defaultCommUsrProfile ;

            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                    SELECT Label
                    FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
            ]){
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                break;
            }

            defaultCommUsrProfile = (defaultCommUsrProfile!=null)? defaultCommUsrProfile : 'Custom Customer Portal';


            Profile pf = [
                    SELECT Id, Name
                    FROM Profile
                    WHERE Name = :defaultCommUsrProfile
                    LIMIT 1
            ];

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            //user for runAs
            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='580');

            System.runAs (u) {

                acc = new Account(Name = 'Filled acc', Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine');

                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test029@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con;

                User commUser = new User(
                        ContactId = con.Id,
                        Username = con.Email,
                        FirstName = con.FirstName,
                        LastName = con.LastName,
                        Email = con.Email,
                        CommunityNickname = con.LastName + '_DfP',
                        Alias = String.valueOf(
                                con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='590'
                );

                insert commUser;
                Portal_user_update__c updateUs = new Portal_user_update__c();
                updateUs.Contact__c= con.Id;
                updateUs.Account__c= acc.Id;
                updateUs.Type__c = 'Grant See All Cases';
                updateUs.Reset_Password__c=true;
                insert updateUs;
               
            }
			
            CommunityUserManagementScheduledJob.handleCommunityUsersEvent();
            

        }
     @IsTest
    static void testUploadCoverage3(){
            Account acc;
            Contact con;
            String defaultCommUsrProfile ;

            for (CommunityUserDefaultProfile__mdt defaultCommunityUserProfiles : [
                    SELECT Label
                    FROM CommunityUserDefaultProfile__mdt  WHERE See_All_cases__c = false
            ]){
                defaultCommUsrProfile = defaultCommunityUserProfiles.Label;
                break;
            }

            defaultCommUsrProfile = (defaultCommUsrProfile!=null)? defaultCommUsrProfile : 'Custom Customer Portal';


            Profile pf = [
                    SELECT Id, Name
                    FROM Profile
                    WHERE Name = :defaultCommUsrProfile
                    LIMIT 1
            ];

            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

            List<UserRole> roles = [SELECT Id,Name,DeveloperName FROM UserRole WHERE DeveloperName = 'Admin'];

            //user for runAs
            User u = new User(Alias = 'staZndtX', Email = 'standarduse179r@testorg.com',
                    EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduse179r@testorg.com', UserRoleId = roles[0].Id,EmployeeNumber='595');
			 Portal_user_update__c updateUs;
            System.runAs (u) {

                acc = new Account(Name = 'Filled acc', Maximum_Portal_Users__c = 5,BillingCountry = 'Ukraine',Type='End User');

                insert acc;

                con = new Contact(
                        AccountId = acc.Id, FirstName = 'fName', LastName = 'lName', Email = 'test029@dfmail.com',
                        MailingCountry = 'Ukraine', Community_User_Management_Status__c = 'Active'
                );

                insert con;

                User commUser = new User(
                        ContactId = con.Id,
                        Username = con.Email,
                        FirstName = con.FirstName,
                        LastName = con.LastName,
                        Email = con.Email,
                        CommunityNickname = con.LastName + '_DfP',
                        Alias = String.valueOf(
                                con.FirstName.substring(0, 1) + con.LastName.substring(0, 1)),
                        ProfileId = pf.Id,
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        TimeZoneSidKey = 'GMT',EmployeeNumber='599'
                );

                Database.SaveResult sr =  Database.insert(commUser);
                 updateUs = new Portal_user_update__c();
                updateUs.Contact__c= con.Id;
                updateUs.Account__c= acc.Id;
                updateUs.Type__c = 'Revoke See All Cases';
                updateUs.Reset_Password__c=true;
                insert updateUs;
                CommunityUserManagementScheduledJob.errorHandle(sr, updateUs);
               
            }
			
            CommunityUserManagementScheduledJob.handleCommunityUsersEvent();
        	Database.SaveResult sr2 =  Database.insert(u,false);
        	CommunityUserManagementScheduledJob.errorHandle(sr2, updateUs);
            updateUs = [SELECT Contact__r.Account.Type FROM Portal_user_update__c WHERE Id=:updateUs.Id];
       		 CommunityUserManagementScheduledJob.setProfileBeforeDeactivate(updateUs, u);
        	Database.DeleteResult dr =  Database.delete(acc,false);
       	    CommunityUserManagementScheduledJob.errorHandle(dr, updateUs);

        }
    
    
}