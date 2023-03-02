public class CompleteMilestoneHandler {
    //Test Class: MilestoneTest
    public static void DefineListforComplete(List<Case> triggerNew,Map<Id, SObject> triggerOldMap){
        if (UserInfo.getUserType() == 'Standard'){
            DateTime completionDate = System.now(); 
            List<Id> updateCases = new List<Id>();
            List<Id> updateTier2Cases = new List<Id>();
            for (Case c : triggerNew){
                case oldCase = (Case)triggerOldMap.get(c.Id);
                String oldValue = oldCase.Assigned_group__c;
                String newValue = c.Assigned_group__c;
                if (oldValue!=null && newValue!=null && (oldValue.contains('Tier_2') || oldValue.contains('Tier2')) && !(newValue.contains('Tier_2') || newValue.contains('Tier2'))) 
                    updateTier2Cases.add(c.Id);
                if (((c.isClosed == true)||(c.Status == 'Closed'))&&((c.SlaStartDate <= completionDate)&&(c.SlaExitDate == null)))
                    updateCases.add(c.Id);
            }
            if (updateCases.isEmpty() == false)
                milestoneUtils.completeMilestone(updateCases, '', completionDate);
            if (updateTier2Cases.isEmpty() == false)
                milestoneUtils.completeMilestone(updateTier2Cases, 'Tier 2', completionDate);
        }
    }
}