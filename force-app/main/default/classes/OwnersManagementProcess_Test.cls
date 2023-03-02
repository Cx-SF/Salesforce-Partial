@isTest
public class OwnersManagementProcess_Test  {
    @testSetup
    private static void setup(){

    }

    @IsTest
    static void getRegionalDirector(){
        OwnersManagementProcessCtrl.getRegionalDirector();
    }

    @IsTest
    static void getAccountOwner(){
        OwnersManagementProcessCtrl.getAccountOwner('00ED0000001Jse5MAC');
    }

   /* @IsTest
    static void getPicklists(){
        OwnersManagementProcessCtrl.getPicklists();
    }

    @IsTest
    static void getStatusValue(){
        OwnersManagementProcessCtrl.getStatusValue();
    }*/

    @IsTest
    static void getDataTable(){
        Map<String, Object> dataObj = new Map<String, Object>();
        dataObj.put('owner','0053z00000B5q7EAAR');
        dataObj.put('org','EMEA DACH & EE');
        dataObj.put('position','P0822');
        dataObj.put('ownerName','Andreas Oswald');
        dataObj.put('random',0.4697669412773571);

        Map<String, Object> dataObj2 = new Map<String, Object>();
        dataObj2.put('batchId','YR783S');
        dataObj2.put('status','In Progress');

        OwnersManagementProcessCtrl.getDataTable(dataObj);
        OwnersManagementProcessCtrl.getDataTable(dataObj2);
    }

    @IsTest
    static void updateRecords(){
        Map<String, Object> accountObj = new Map<String, Object>{'Id'=>'001D000001HEdY4IAL','Name'=>'Noser Engineering','BillingCountry'=>'Switzerland','Total_Active_ACV__c'=>0,'Account_Owner__c'=>'Andreas Oswald','of_Open_Opportunities__c'=>0,'OwnerId'=>'0053z00000B5q7EAAR','Existing_Quota__c'=>false,'Account_Status__c'=>'Prospect','rowNumber'=>1,'ownerChange'=>''};
        
        Map<String, Object> opportunityObj = new Map<String, Object>{'Id'=>'0064K000006d3elQAA','Name'=>'EMEA-CH-Swiss Post Solutions-ASP-1Yr','Account_name__c'=>'Swiss Post Ltd','AccountId'=>'0013z00002Nd35IAAR','Channel__c'=>'Direct','Type'=>'New Business','StageName'=>'Stage zero Prospecting','CloseDate'=>'2021-06-30','OwnerId'=>'0053z00000B2QVFAA3','Opportunity_Owner_Name__c'=>'David Schulze','Existing_Quota__c'=>false,'rowNumber'=>1,'ownerChange'=>''};

        List<Object> accList = new List<Object>();
        accList.add(accountObj);

        List<Object> oppList = new List<Object>();
        oppList.add(opportunityObj);

        Map<String, Object> dataObj = new Map<String, Object>();
        dataObj.put('currentOwnerId', '0053z00000B5q7EAAR');
        dataObj.put('selectedOwner', '005D0000003mf1JIAQ');
        dataObj.put('newAssigment', 'Replacement');
        dataObj.put('account', accList);
        dataObj.put('opportunity', oppList);

        OwnersManagementProcessCtrl.updateRecords(dataObj);
    }

    @IsTest
    static void search(){
    String nam = 'Refael';
    List<String> strList = new List<String>{'0053z00000B5q7EAAR', '0074r00000Br7fhuwe'};
        OwnersManagementProcessCtrl.search(nam, 'true',strList);
        OwnersManagementProcessCtrl.getRecentlyViewed();
    }
    
}