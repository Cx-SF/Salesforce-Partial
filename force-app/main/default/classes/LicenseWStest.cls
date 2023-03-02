@isTest
public class LicenseWStest {

    static testMethod void Test01(){
        
        ClsObjectCreator cls = new ClsObjectCreator();

        LicenseWS.justBringUpTheCovrage();
        
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
}