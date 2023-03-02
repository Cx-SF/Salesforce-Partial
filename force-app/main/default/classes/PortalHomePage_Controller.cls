public without sharing class PortalHomePage_Controller {
    public List<New_Product_Release__c> newReleaseList {get;set;}
    public List<Latest_News__c> latestNewsList {get;set;}
    
    public PortalHomePage_Controller(){
    	
        newReleaseList = [SELECT Id, Read_More__c, Link__c, Subject__c, Post__c, Image__c FROM New_Product_Release__c WHERE Public__c = true ORDER BY Published_Date__c desc];
        latestNewsList = [SELECT Id, Read_More__c, Link__c, Post__c, Subject__c, Published_Date__c, Image__c FROM Latest_News__c WHERE Public__c = true ORDER BY Published_Date__c desc];
        
    }
}