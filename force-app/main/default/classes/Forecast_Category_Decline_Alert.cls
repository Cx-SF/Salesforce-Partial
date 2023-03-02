global class Forecast_Category_Decline_Alert Implements Schedulable
{
	global void execute(SchedulableContext sc)
    {
        notifyManagers();
    }

    public void notifyManagers()
    {
        List<Id> lst_of_managerIDs = new List<ID>();
        List<User> lst_of_managers = new List<User>();
        List<Id> toAddressList = new List<ID>();
        
        Group Sub_Region_Directors_Group = new Group();
        Sub_Region_Directors_Group = [Select Id, DeveloperName, (Select Id, UserOrGroupId  From GroupMembers) From Group Where DeveloperName ='Sub_Region_Directors'];
        
        if(!Sub_Region_Directors_Group.GroupMembers.isEmpty())
        {
            for(GroupMember groupMem:Sub_Region_Directors_Group.GroupMembers)
            {
                lst_of_managerIDs.add(groupMem.UserOrGroupId);
            }
            
            lst_of_managers = [Select Id, Name, Email, IsActive From User Where ID IN:lst_of_managerIDs And IsActive = TRUE];
            
            if(!lst_of_managers.isEmpty())
            {
                for(User manager:lst_of_managers)
                {
                   	toAddressList = new List<ID>();
                    toAddressList.add(manager.Id);
                    String managerName = manager.Name.replace(' ','%20');
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
					
                    mail.setSubject(Alert_Email_Settings__c.getInstance('Alert_Email').Email_Subject__c);
					mail.setHtmlBody(Alert_Email_Settings__c.getInstance('Alert_Email').Email_Body__c.replace('MANAGERNAME',managerName));
                    mail.setToAddresses(toAddressList);                                                    	    
                	mail.setSaveAsActivity(false);  
                
                	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
                }               
            }
        }        
    }
}