public with sharing class CloseCaseController {
 
    @AuraEnabled
    public static String getStatus(Id caseId) {
        return ([Select Status From Case Where Id = :caseId])[0].Status;
    }
    
    @AuraEnabled
    public static void updateStatus(Case caseRecord){
        UpdateCaseAfterCloseController.updateStatusCase(caseRecord);
    }
}