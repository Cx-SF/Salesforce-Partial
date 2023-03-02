trigger PreventCaseDeletion on Case (before delete) 
{
    Profile userProfile = [Select Name from Profile where Id =: UserInfo.getProfileId()];
    Boolean permissionGroup = false;
   
    for(Group gp:[SELECT Id, (SELECT Id FROM GroupMembers WHERE UserOrGroupId =:Userinfo.getUserId() LIMIT 1) FROM Group WHERE DeveloperName  = 'Allow_Delete_Cases' ])
    {
        if( !gp.GroupMembers.isEmpty() )
        {
            permissionGroup = true;
        }
    }
    
    for (Case record : trigger.old)
    {
        if (userProfile.Name != Label.System_Admin_Profile && permissionGroup == false)
        {
            record.addError(Label.Case_deletion_Error);
        }
    }
}