public class CompleteFirstResponseEmailHandler {

    public CompleteFirstResponseEmailHandler(List<EmailMessage> emList)
    {
        if (UserInfo.getUserType() == 'Standard'){
        DateTime completionDate = System.now();
        system.debug('**TEST completionDate:'+completionDate);
        Map<Id, String> emIds = new Map<Id, String>();
       
            for (EmailMessage em : emList)
            {
                if(em.Incoming == false)
                    emIds.put(em.ParentId, em.ToAddress);
        	}
    		
            
            if (emIds.isEmpty() == false)
            {
                Set <Id> emCaseIds = new Set<Id>();
                emCaseIds = emIds.keySet();
                List<Case> caseList = [Select c.Id, c.ContactId, c.Contact.Email,
                                       c.OwnerId, c.Status,
                                       c.EntitlementId,
                                       c.SlaStartDate, c.SlaExitDate
                                       From Case c where c.Id IN :emCaseIds];
                system.debug('**TEST caseList:'+caseList);
                
                if (caseList.isEmpty()==false){
                    List<Id> updateCases = new List<Id>();
                    for (Case caseObj:caseList)
                    {
                        if (//(emIds.get(caseObj.Id)==caseObj.Contact.Email)&&
                            //(caseObj.Status == 'In Progress')&&
                            (caseObj.EntitlementId != null)&&
                            (caseObj.SlaStartDate <= completionDate)&&
                            (caseObj.SlaStartDate != null)&&
                            (caseObj.SlaExitDate == null)
                           )
                            updateCases.add(caseObj.Id);
                    }
                    
                    if(updateCases.isEmpty() == false)
                        milestoneUtils.completeMilestone(updateCases,'First Response', completionDate);
                }
            }
    
   	   }
    }
}