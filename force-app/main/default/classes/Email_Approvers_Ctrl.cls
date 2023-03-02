global class Email_Approvers_Ctrl {
    
    public string ParentId { get; set; }
   public list <sbaa__Approval__c> AllApprovers { get; set; }
    
   public list <sbaa__Approval__c> RecordsToDisplay
    {
        get
        {
            list <sbaa__Approval__c> AllRs = new list <sbaa__Approval__c> (); 
            set <string> ApproversName = new set <string> ();
            for(sbaa__Approval__c app : [SELECT Id, sbaa__Status__c, WDCX_ConsolidatedApprover__c  FROM sbaa__Approval__c where Quote__c =:ParentId ORDER BY sbaa__ApprovalStep__c , sbaa__Status__c ])
            {
                if(!(ApproversName.contains(app.WDCX_ConsolidatedApprover__c ))){
                ApproversName.add(app.WDCX_ConsolidatedApprover__c );
                AllRs.add(app);
                }
            }
            AllApprovers = AllRs;
            return AllApprovers;
        }
        set;
    }
    
    public Email_Approvers_Ctrl()
    {
    }

    
  
}