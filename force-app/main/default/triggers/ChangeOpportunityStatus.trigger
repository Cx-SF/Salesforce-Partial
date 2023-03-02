trigger ChangeOpportunityStatus on Quote (after update) {
  /*
    List<Quote> quoteList = new List<Quote>();
    List<Id> oppIdList = new List<Id>();
    
    for(Quote quote : trigger.new){
    
           
        if(quote.IsSyncing == true && quote.Status != NULL && trigger.oldMap.get(quote.id).Status != NULL && quote.OpportunityId != NULL){
        
           if(quote.Status == 'Approved'  && quote.Status != trigger.oldMap.get(quote.id).Status){
               quoteList.add(quote);
               oppIdList.add(quote.OpportunityId);    
           }
           
           if(quote.Status == 'Rejected'  && quote.Status != trigger.oldMap.get(quote.id).Status){
               quoteList.add(quote);
               oppIdList.add(quote.OpportunityId);                 
           }
           if(quote.Status == 'In Review' && quote.Status != trigger.oldMap.get(quote.id).Status){
               quoteList.add(quote);
               oppIdList.add(quote.OpportunityId);      
           }
        }
        
    }
    
    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT id, StageName
                                                            FROM Opportunity
                                                            WHERE id IN :oppIdList]);
    
                                                            
   if(!oppMap.isEmpty()){
        for(Quote quote : quoteList ){
            if(quote.Status == 'Approved' )
            {
                oppMap.get(quote.OpportunityId).StageName = 'Closed Won';
                oppMap.get(quote.OpportunityId).Approved_via_Approval_Process__c = true;
            }
            else{
                if(quote.Status == 'In Review' )
                    oppMap.get(quote.OpportunityId).StageName = 'Pending Approval';     
                else    
                    oppMap.get(quote.OpportunityId).StageName = quote.Status;
            }
        }
        update oppMap.values();
   }                                                   
    */
}



/*
trigger ChangeOpportunityStatus on Quote (after update) {
    List<Quote> quoteList = new List<Quote>();
    List<Id> oppIdList = new List<Id>();
    
    for(Quote quote : trigger.new){
        oppIdList.add(quote.OpportunityId);      
    }
    
    List<Opportunity> oppList = new List<Opportunity>([SELECT id, StageName
                                                            FROM Opportunity
                                                            WHERE id IN :oppIdList]);
    for(Quote quote : trigger.new){
        for(Opportunity opp : oppList){
            if(quote.OpportunityId == opp.id){
                if( (quote.Status != NULL) && (
                     quote.Status == 'Approved' ||
                     quote.Status == 'Rejected' ||
                     quote.Status == 'In Review')  ){
                                            
                     opp.StageName = quote.Status;                               
                }
            }
        }
    }
    update oppList;
    
}

*/