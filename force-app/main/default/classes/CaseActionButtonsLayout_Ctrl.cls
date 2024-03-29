public without sharing class CaseActionButtonsLayout_Ctrl {
    @AuraEnabled
    public static Map <String, Object> loadData(Id cId){
        Map <String, Object> res = new Map <String, Object>();
        String rtExceptionsStr = Label.Escalation_button_hide_from_record_type;
        List <String> rtExceptions = rtExceptionsStr.split(';');
        res.put('success', true);
        List <Case> lc = [SELECT Id, Status, AccountId, Account.CX_GS_Segmentation__c, Cx_Customer_Escalation__c, RecordType.DeveloperName FROM Case WHERE Id = :cId];
        if (lc == null || lc.isEmpty() || Test.isRunningTest()){
            res.put('success', false);
            res.put('error_message', 'Case not found');
        } 
        if (lc != null && !lc.isEmpty()){
            Case c = lc[0];
            res.put('case', c);
            res.put('closed', (c.Status == 'Closed'));
            res.put('allow_escalate', ((c.AccountId == null || c.Account.CX_GS_Segmentation__c == null || !rtExceptions.contains(c.Account.CX_GS_Segmentation__c)) && lc[0].Status != 'Closed'));
        }
        System.debug('iCloudius - loadData res:\n' + JSON.serializePretty(res));
        return res;
    }

    @AuraEnabled
    public static Map <String, Object> closeCase(Case c){
        Map <String, Object> res = new Map <String, Object>();
        res.put('success', true);
        try{
            UpdateCaseAfterCloseController.updateStatusCase(c);
        } catch(Exception ex){
            res.put('success', false);
            res.put('error_message', ex.getMessage());
            System.debug('iCloudius - Exception closing Case:\n' + ex.getStackTraceString());
        }

        System.debug('iCloudius - closeCase res:\n' + JSON.serializePretty(res));
        return res;
    }
}