global class PbBatchUpdate  implements Database.Batchable<sobject>, Database.Stateful
{ 
 
    global Database.Querylocator start (Database.BatchableContext BC)
     {
    	return Database.getQueryLocator([select ID from CampaignMember Where LeadId != null Order BY CreatedDate Asc]);//Query which will be determine the scope of Records fetching the same
    }
    
  //Execute method
  global void execute (Database.BatchableContext BC, List<sobject> scope)
  {
  	try
  	{
	  	list<CampaignMember> campMembrList = (list<CampaignMember>) scope;  // we need to cast the "scope"
		//
		
			// <CODE>
			update campMembrList;
		
		//
  	}
 	catch(Exception ex)
	{
			system.debug('@@@@ Exception ' + ex);		
			throw(ex);
	}  	 
  }
  
  //Finish Method
  global void finish(Database.BatchableContext BC)
  {
  	// FInish Metohs is not a must.
  }	
}