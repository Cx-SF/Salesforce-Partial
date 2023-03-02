/******************************************************************************* 
Name              : OpportunityPrimaryCampaignOnLeadConvert
Description       : On Lead Convert, sets the Opportunitites Primary Campaign to the first CampaignMember
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan               10/07/2013                  Itay                   [SW-5473]
*******************************************************************************/
trigger OpportunityPrimaryCampaignOnLeadConvertion on Lead (after update) {
 	
 	try{
 		
	 	Map<Id,Id> oppIdByLeadId = new Map<Id,Id>();
	 	for(Integer i=0; i < trigger.size; i++){
	        if(trigger.old[i].isConverted != trigger.new[i].isConverted && trigger.new[i].isConverted == true && trigger.new[i].ConvertedOpportunityId <> null){
	        	oppIdByLeadId.put(trigger.new[i].Id, trigger.new[i].ConvertedOpportunityId);
	        }
	    }
      
    	if( !oppIdByLeadId.isEmpty() ){
			// IMPORTANT: The way that we have implemented this trigger is because was requested by Itay. The idea is update for each Campaign member the related opp.
			for( Lead l : [SELECT Id, (SELECT Id, CampaignId FROM CampaignMembers ORDER BY CreatedDate asc) FROM Lead WHERE Id IN :oppIdByLeadId.keySet()]){
				for(Integer i = l.CampaignMembers.size()-2; i >= 0; i--){ // Avoid the last one created
					System.debug('==>>>> l.CampaignMembers[i].CampaignId: ' + l.CampaignMembers[i].CampaignId);
					update new Opportunity(Id= oppIdByLeadId.get(l.Id), CampaignId = l.CampaignMembers[i].CampaignId);
				}
			}
		}
	}catch( Exception e ){
		trigger.new[0].addError(e.getMessage());
	}  
}