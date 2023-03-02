public class SalesvueEmailOptOutManager
{
    public static boolean TestSalesvueEmailOptOutManager()
    {
        boolean b = true;
        return b;
    }
    
    /*
	@InvocableMethod(label='Update Opt Out Flag' description='Update opt out flag on leads and contacts	when unsubcribe events occur in Salesvue')
	public static void updateOptOut(List<Id> ids)
	{ 
		if (ids == null || ids.isEmpty()) 
		{
			return;
		}
		try 
		{
			List<Salesvue__Email_Event__c> events = [select Salesvue__Lead__c,
			Salesvue__Contact__c from Salesvue__Email_Event__c where Id in :ids];
			Set<Id> leadIds = new Set<Id>();
			Set<Id> contactIds = new Set<Id>();
			for (Salesvue__Email_Event__c event : events) 
			{
				if (event.Salesvue__Lead__c != null) 
				{
					leadIds.add(event.Salesvue__Lead__c);
				}
				if (event.Salesvue__Contact__c != null) 
				{
					contactIds.add(event.Salesvue__Contact__c);
				}
			}
			final List<SObject> toUpdate = new List<SObject>();
			for (Id leadId : leadIds) 
			{
				toUpdate.add((SObject)new Lead(Id = leadId, HasOptedOutOfEmail = true));
			}
			for (Id contactId : contactIds) 
			{
				toUpdate.add((SObject)new Contact(Id = contactId, HasOptedOutOfEmail = true));
			}
			if (!toUpdate.isEmpty()) 
			{
				update toUpdate;
			}
		}
		catch (Exception e) 
		{
			Salesvue__SV_Error__c err = new Salesvue__SV_Error__c(Salesvue__Error_Message__c = e.getMessage());
			insert err;
		}
	}*/
}