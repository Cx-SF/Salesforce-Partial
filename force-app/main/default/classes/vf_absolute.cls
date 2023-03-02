public with sharing class vf_absolute 
{
	public pageReference init()
	{
		License__c updLicense ; 
		if (ApexPages.currentPage().getParameters().get('id') != null)
		{
			String licenseId = ApexPages.currentPage().getParameters().get('id');
			updLicense = new License__c(Id = licenseId) ; 
			updLicense.status__c = 'Obsolete' ;  
			update updLicense ; 
		}
		else
		{
			return null ; 
		}
		
		
		if (ApexPages.currentPage().getParameters().get('oppMode') != null &&  ApexPages.currentPage().getParameters().get('oppMode') == 'true')
		{
			if (ApexPages.currentPage().getParameters().get('oppId') != null)
			{
				String oppId = ApexPages.currentPage().getParameters().get('oppId');
				return new pageReference('/' + oppId) ; 			
			}
			else
			{
				return null ; 
			}
		}
		else
		{
			return new pageReference('/' + updLicense.Id) ; 
		}
	}
}