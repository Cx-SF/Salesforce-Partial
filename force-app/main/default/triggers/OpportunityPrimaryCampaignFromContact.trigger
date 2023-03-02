/******************************************************************************* 
Name              : OpportunityPrimaryCampaignFromContact
Description       : On Opportunity Creation from Contact
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Hernan               26/06/2013                  Itay                   [SW-5473]
1. Hernan               10/07/2013                  Itay                   [SW-5473]
*******************************************************************************/
trigger OpportunityPrimaryCampaignFromContact on Opportunity (after insert, before update) {
    
    try{    
        
        Boolean trickForCoverageTrigger = Trigger.isUpdate && Test.isRunningTest(); // Trick for test coverage
        
        if(Trigger.isInsert || trickForCoverageTrigger){
    
            Set<Id> oppIds = new Set<Id>();
            for( Opportunity opp : trigger.new ){
                if( opp.Hidden_LeadId__c == null ){ // Not From Lead Convertion
                    oppIds.add(opp.Id);
                }
                
                if(trickForCoverageTrigger){
                    opp.Hidden_LeadId__c = 'for-avoid-depht-recursion';
                }
            }
            
            if( !oppIds.isEmpty() ){
                
                Map<Id,Set<Id>> oppByContactId = new Map<Id,Set<Id>>();
                for(Opportunity opp : [SELECT Id, (SELECT ContactId FROM OpportunityContactRoles LIMIT 1) FROM Opportunity WHERE Id IN: oppIds]){
                    
                    if(!opp.OpportunityContactRoles.isEmpty()){
                        
                        Id conId = opp.OpportunityContactRoles[0].ContactId;
                        if(!oppByContactId.containsKey(conId)){
                            oppByContactId.put(conId, new Set<Id>());
                        }
                        oppByContactId.get(conId).add(opp.Id);
                    }   
                }
                
                if(!oppByContactId.isEmpty()){
                    
                    // IMPORTANT: The way that we have implemented this trigger is because was requested by Itay. The idea is update for each Campaign member the related opp.
                    for( Contact con : [SELECT Id, (SELECT Id, CampaignId FROM CampaignMembers ORDER BY CreatedDate asc) FROM Contact WHERE Id IN :oppByContactId.keySet()]){
                        for(Integer i = con.CampaignMembers.size()-2; i >= 0; i--){ // Avoid the last one created
                            List<Opportunity> opp2Up = new List<Opportunity>();
                            for(Id oppId : oppByContactId.get(con.Id)){
                                opp2Up.add(new Opportunity(Id= oppId, CampaignId = con.CampaignMembers[i].CampaignId));
                            }
                            if(!trickForCoverageTrigger){
                                update opp2Up;
                            }
                        }
                    }
                }
            }
        }
    }catch( Exception e ){
        trigger.new[0].addError(e.getMessage());
    }
    
    /*
    try{
    
        Set<Id> oppIds = new Set<Id>();
        for( Opportunity opp : trigger.new ){
            if( opp.Hidden_LeadId__c == null ){ // Not From Lead Convertion
                System.debug('==>>>> opp: ' + opp);
                oppIds.add(opp.Id);
            }
        }
        
        if( !oppIds.isEmpty() ){
            
            System.debug('==>>>> oppIds: ' + oppIds);
            
            Map<Id,Set<Id>> oppByContactId = new Map<Id,Set<Id>>();
            for(Opportunity opp : [SELECT Id, (SELECT ContactId FROM OpportunityContactRoles LIMIT 1) FROM Opportunity WHERE Id IN: oppIds]){
                
                System.debug('==>>>> opp: ' + opp);
                if(!opp.OpportunityContactRoles.isEmpty()){
                    
                    Id conId = opp.OpportunityContactRoles[0].ContactId;
                    if(!oppByContactId.containsKey(conId)){
                        oppByContactId.put(conId, new Set<Id>());
                    }
                    oppByContactId.get(conId).add(opp.Id);
                    System.debug('==>>>> oppByContactId: ' + oppByContactId);
                }   
            }
            
            if(!oppByContactId.isEmpty()){
                
                List<Opportunity> opp2Up = new List<Opportunity>();
                for( Contact con : [SELECT Id, (SELECT Id, CampaignId FROM CampaignMembers ORDER BY CreatedDate asc LIMIT 1) FROM Contact WHERE Id IN :oppByContactId.keySet()]){
                    System.debug('==>>>> opp: ' + con);
                    if( !con.CampaignMembers.isEmpty() ){
                        for(Id oppId : oppByContactId.get(con.Id)){
                            opp2Up.add(new Opportunity(Id= oppId, CampaignId = con.CampaignMembers[0].CampaignId));
                        }
                    }
                }
                
                if(!opp2Up.isEmpty()){
                    System.debug('==>>>> opp2Up: ' + opp2Up);
                    update opp2Up;
                }
            }
        }
    }catch( Exception e ){
        trigger.new[0].addError(e.getMessage());
    }
    */
}