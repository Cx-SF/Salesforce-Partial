global class Email_Template_Ctrl {
    
    public string ObjToDisplay { get; set; }
    public string ParentId { get; set; }
    public string ApprovalId { get; set; }
    public String fSetName { get; set; }
    public String referenceName { get; set; }
    
    public List<Schema.FieldSetMember> fsList
    {
        get
        {
            fsList = readFieldSet( fSetName , ObjToDisplay );
            return fsList;
        }
        set;
    }
    public static List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName)
    {
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }
    
    
  /*  public List<SBQQ__QuoteLine__c> QuoteLines {
        get
        {
            return [SELECT Id, SBQQ__ProductName__c, SBQQ__SubscriptionTerm__c, WD_Trial_Period__c, WD_Catalog_Price__c,SBQQ__Quantity__c,WD_Additional_Overage_Cost__c,SBQQ__ProductFamily__c, WD_Overall_Package_Discount__c
                    ,WD_Overall_Add_On_Discount__c, af_Product_Name_for_Document__c , AF_discount_for_document__c ,   
                    SBQQ__ListPrice__c, SBQQ__TotalDiscountRate__c, SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c where SBQQ__Quote__c =: ParentId AND SBQQ__Hidden__c= false];
        }
        set;}
    
     public List<sbaa__Approval__c> Approvals {
        get
        {
            return [SELECT Id, Name, Days_to_approve__c, WD_Approver_Group__c, sbaa__Status__c , sbaa__Rule__c FROM sbaa__Approval__c where Quote__c  =: ParentId];
        }
        set;}*/
    
    
    public List<sobject> RecordsToDisplay {
        get
        {
            String query = 'SELECT id  ';           
            for(Schema.FieldSetMember fsObj : fsList)
                query += ',' + fsObj.getFieldPath() ;
            query += ' FROM ' + ObjToDisplay;
            query += ' Where ' + referenceName + ' =: ParentId';
            if(ObjToDisplay == 'SBQQ__QuoteLine__c'){
                /*query += ' and SBQQ__Bundled__c != true ';*/
                query += ' and SBQQ__Product__r.SBQQ__Hidden__c != true ';
                query += '  order by WDCX_LineOrder__c ';
            }
            return Database.query(query);
        }
        set;}
    
    public Email_Template_Ctrl()
    {
    }

    
  
}