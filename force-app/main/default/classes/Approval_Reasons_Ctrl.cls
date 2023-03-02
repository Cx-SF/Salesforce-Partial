global class Approval_Reasons_Ctrl {
    
    public string ParentId { get; set; }
    public string CurrQuote { get; set; }
    public set <String> AllReasons { get; set; }
    
    
    public Approval_Reasons_Ctrl()
    {
        
    }

    
    public set<string> ResList
    {
        get
        {
            set <string> AllRs = new set <string> (); 
            for(sbaa__Approval__c app : [SELECT Id, sbaa__ApprovalChain__r.name, Quote__c FROM sbaa__Approval__c where sbaa__Approver__c =:ParentId and Quote__c =:CurrQuote ])
            {
                AllRs.add(app.sbaa__ApprovalChain__r.name);
            }
            ResList = AllRs;
            return ResList;
        }
        set;
    }
}