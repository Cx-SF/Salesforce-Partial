public class MilestoneUtils {
        //Test Class: MilestoneTest
    public static void completeMilestone(List<Id> caseIds,String milestoneName, DateTime complDate) {
        String sql='select Id, completionDate,caseId from CaseMilestone where caseId in :caseIds and completionDate = null ';
        if(milestoneName!='')
            sql+= 'and MilestoneType.Name=:milestoneName';
        system.debug('sql:'+sql);
        List<CaseMilestone> cmsToUpdate =Database.query(sql);
        /* List<CaseMilestone> cmsToUpdate = [select Id, completionDate,caseId
												from CaseMilestone cm
												where caseId in :caseIds and cm.MilestoneType.Name=:milestoneName
												and completionDate = null limit 1];*/
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                Case c=[select Id,status from case where Id=:cm.caseId];
                system.debug('c.status:'+c.status);
                cm.completionDate = complDate;
            }
            update cmsToUpdate;
        }
    }
}