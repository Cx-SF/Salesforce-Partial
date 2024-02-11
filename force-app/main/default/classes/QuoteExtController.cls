public with sharing class QuoteExtController {
    private Id quoteId;
    private Id salesOpsProfileId;
    //29.12 Liad Tcziffer adding by nurit request
    private Id SysAdminProfileId;
    public Boolean hasError {
        get{
            return (hasError == null ? false : hasError);
        } Set; }
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
        String ProfileIdStr = Label.Sales_Ops_Profile;
        //29.12 Liad Tcziffer adding by nurit request
        String ProfileSysAdminIdStr = Label.Admin_Profile;
        if (String.isNotBlank(ProfileIdStr)) salesOpsProfileId = Id.valueOf(ProfileIdStr);
        //29.12 Liad Tcziffer adding by nurit request
        if (String.isNotBlank(ProfileSysAdminIdStr)) SysAdminProfileId = Id.valueOf(ProfileSysAdminIdStr);
    }
    public PageReference onSubmit() {
        if (quoteId != null) {
            SBQQ__Quote__c q = [SELECT Id, SBQQ__StartDate__c, SBQQ__ExpirationDate__c, CX_ListPriceChange__c, CX_Account_Renewal_Pricing_Method__c, WDCX_Down_sell__c, 
                                       WDCX_Opportunity_Type__c, SBQQ__Account__r.Developers__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SAST_Products__c, 
                                       SBQQ__Opportunity2__r.CX_ASTProducts__c, WDCX_Down_Sell_Percent__c, CX_Downsell_Reason__c, WDCX_Approval_Notes__c ,ApprovalStatus__c ,
                                       CX_End_Of_Life_Products__c,CX_Early_Estimation_Products__c,SBQQ__Partner__c,SBQQ__Partner__r.Type,SBQQ__Distributor__c,SBQQ__Distributor__r.Type,CX_Number_of_AST_Products__c,CX_Why_not_AST__c 
                                FROM SBQQ__Quote__c WHERE Id = :quoteId LIMIT 1];

            if (q == null || (q.SBQQ__StartDate__c == null )) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Start Date is mandatory on all quote types. If unknown, please provide an estimation.')); }
            if (q != null && ((q.WDCX_Down_sell__c != null && q.WDCX_Down_sell__c > 0) || (q.WDCX_Down_Sell_Percent__c != null && q.WDCX_Down_Sell_Percent__c > 0)) && q.CX_Downsell_Reason__c == null) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Downsell reason is mandatory for any DownSell gaps.')); }
            if (q != null && ((q.WDCX_Down_sell__c != null && q.WDCX_Down_sell__c > 0) || (q.WDCX_Down_Sell_Percent__c != null && q.WDCX_Down_Sell_Percent__c > 0)) && q.WDCX_Approval_Notes__c == null) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Approval notes are mandatory for any DownSell gaps.')); }
            if (q != null && q.SBQQ__ExpirationDate__c != null && q.SBQQ__ExpirationDate__c < Date.today()) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Quote is already expired; please update Expires On field')); }
            if (q != null && q.SBQQ__ExpirationDate__c == null) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Expiration date is mandatory')); }
            if (q != null && (q.SBQQ__Account__r.Developers__c == null || q.SBQQ__Account__r.Developers__c == 0)) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Number of Developers in account is mandatory.')); }
            if (q != null && q.CX_Early_Estimation_Products__c != null && q.CX_Early_Estimation_Products__c >0 ) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'You cannot submit quote with early estimation product for an approval.')); }
            if (q != null && q.CX_End_Of_Life_Products__c >0 && UserInfo.getProfileId() != salesOpsProfileId && UserInfo.getProfileId() != SysAdminProfileId) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'You cannot send this quote for approval since it contains End Of Life Products. Please Contact Revenue operations for additional information.')); }
            if (q != null && q.SBQQ__Partner__c != null && q.SBQQ__Partner__r.Type != 'Partner/ Reseller' ) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Partner Account type must be a Partner/ Reseller, please select the correct account')); }      
            if (q != null && q.SBQQ__Distributor__c != null && q.SBQQ__Distributor__r.Type != 'Distributor') { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Distributor Account type must be a Distributor, please select the correct account')); }
            if (q != null && (q.CX_Number_of_AST_Products__c == null || q.CX_Number_of_AST_Products__c == 0) && q.CX_Why_not_AST__c == null) { hasError = true; apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error, 'Please provide an explanation why the quote does not contain Cx1 offering')); }       
        
                    if (q != null && q.CX_ListPriceChange__c != null && q.CX_Account_Renewal_Pricing_Method__c == 'List'
                      && q.CX_ListPriceChange__c > 0 && UserInfo.getProfileId() != salesOpsProfileId && UserInfo.getProfileId() != SysAdminProfileId
                     )
                      {
                          hasError = true;
                          apexpages.addMessage(new ApexPages.message(Apexpages.Severity.error,
                       'Please note prices have not been refreshed yet to match the current pricebook. Click "Edit Lines" and then "Refresh Prices" and adjust any discounts if needed.'));
                      }
            if (!hasError) { SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c); return new PageReference('/' + quoteId); }  
                           }
        return null;
    }
    public PageReference onRecall() {
        if (quoteId != null) {
            SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
        }
        return new PageReference('/' + quoteId);
    }
    public PageReference goBack() {
        return new PageReference('/' + quoteId);
    }
}