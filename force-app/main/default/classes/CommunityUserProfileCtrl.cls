public class CommunityUserProfileCtrl {
    @AuraEnabled 
    public static user fetchUserDetail() {
        return [Select Id, Name, SmallPhotoUrl, FullPhotoUrl From User Where Id =: Userinfo.getUserId()];
    }
}