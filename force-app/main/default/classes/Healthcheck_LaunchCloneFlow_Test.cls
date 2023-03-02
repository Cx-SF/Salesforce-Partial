@isTest
public class Healthcheck_LaunchCloneFlow_Test {
    static testMethod void Healthcheck_LaunchCloneFlow_Test(){

        Account acc = new Account();
        acc.Name = 'test';
        acc.BillingCountry = 'Israel';
        insert acc;
        CSM__c hc = new CSM__c();
        hc.Account__c = acc.Id;
        insert hc;
        hc = [select Id from CSM__c where Id =: hc.Id];
        hc.Record_ID__c = hc.Id;
        update hc;
        
        Healthcheck_Product__c hcProduct = new Healthcheck_Product__c();
        hcProduct.Healthcheck__c = hc.Id;
        insert hcProduct;
        
        hc.clone(false,false,false,false);
        //update hc;
        
        CSM__c clonedHC = new CSM__c();
        clonedHC.Record_ID__c = hc.Id;
        clonedHC.Account__c = acc.Id;
        clonedHC.Solution_Suggestions__c = 'testClass';
        insert clonedHC;
        
        clonedHC = [select Id, Record_ID__c from CSM__c where Id =: clonedHC.Id];
        
        Map<String, String> params = new Map<String, String>();
        params.put('NewHealthcheckID', clonedHC.Id);
        params.put('recordID', clonedHC.Record_ID__c);
        Flow.Interview.Clone_Healthcheck_Products flow = new Flow.Interview.Clone_Healthcheck_Products(params);
        flow.start();
    }
}