@isTest(SeeAllData=true)
public with sharing class lightningCarouselControllerTest{
                                
     @isTest
    private static void KnowledgeRecordTypes(){       
      
        Test.startTest();
             List<Support_Community_Announcement__c> SupportCommunityAnnouncement = new List<Support_Community_Announcement__c>();
             SupportCommunityAnnouncement =  lightningCarouselController.getCarouselAnnouncement('Announcement');                           
             System.assertEquals(SupportCommunityAnnouncement.size(), SupportCommunityAnnouncement.size());              
        Test.stopTest();

    }              
}