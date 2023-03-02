public class lightningCarouselController {

    @AuraEnabled(cacheable=true)
    public static List<Support_Community_Announcement__c> getCarouselAnnouncement(string AnnouncementType){
        return [Select Id,
                       OwnerId,                       
                       Header__c ,
                       Announcement__c,     
                       Announcement_Rich_Text__c,                  
                       IsActive__c,                       
                       Image_Url__c,
                       Target_Link__c,
                       Target_Link_Type__c,
                       Knowledge__c
                       from Support_Community_Announcement__c
                       Where IsActive__c = true 
                       And type__c = :AnnouncementType ];
    }
}