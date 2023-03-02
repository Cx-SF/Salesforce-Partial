public class IdeaToAccountsViewController {

    public Integer CountTotalRecords{get;set;}
    public String QueryString {get;set;}
    public Integer OffsetSize = 0;
    private Integer QueryLimit = 25;
    public list<Idea_Account_juction__c> records;
    public String RecordId {get;set;}
    public string ideaId {get; set;} 
    public String message{get;set;}
    
    
    
    public IdeaToAccountsViewController() {
        
        ideaId = ApexPages.currentPage().getParameters().get('id');
        CountTotalRecords= [select count() from Idea_Account_juction__c where Ideas__r.Id =: ideaId];
        
        
    }
    
  public list<Idea_Account_juction__c> getRecords() { 
        
        records = new list<Idea_Account_juction__c>();
        records = [Select name,CreatedBy.Name,Ideas__r.Id,Ideas__r.title,Ideas__c, Id, Account__r.NumberOfEmployees, Account__r.Industry, Account__r.Type,Account__r.Touching_level__c,
                   Account__r.Name, Account__r.Contracts_Status__c,Account__r.Parent_Account__c,Account__r.of_Closed_Won_Opps__c,Account__r.Total_Won_Amount__c,
                   Account__r.Id, Account__c,Account__r.Region__c,Account__r.Total_Active_ACV__c,Ideas__r.Main_Interested_Account__c,Business_justification__c,
                   Business_Justification_Reason__c,Expected_Usage__c,Feature_Planned_Version__c,Feature_Product__c,Feature_Status__c,Requesting_Contact__c,Account_use_case__c,
                   Customer_priority__c
                  
                   From Idea_Account_juction__c where Ideas__r.Id =: ideaId limit :QueryLimit offset :OffsetSize];
        return records; 
    }
    public PageReference cancel() {
        
        PageReference pageRef = new PageReference('/'+ ideaId);
        pageRef.setRedirect(true);
        return pageRef; 
    }
    
    
    public Boolean getDisablePrevious(){
        if(OffsetSize>0){
            return false;
        }
        else return true;
    }
 
    public Boolean getDisableNext() {
        if (OffsetSize + QueryLimit < countTotalRecords){
            return false;
        }
        else return true;
    }
 
    public string getTitle() {
        
        return records[0].Ideas__r.title;
            //records[0].Ideas__r.title.length() > 250 ? records[0].Ideas__r.title.left(249) + '...' : records[0].Ideas__r.title;
        
    }
    public PageReference Next() {
        OffsetSize += QueryLimit;
        return null;
    }
 
    public PageReference Previous() {
        OffsetSize -= QueryLimit;
        return null;
    }
    public PageReference FirstPage()    {
        OffsetSize = 0;
        return null;
    }
    
    public PageReference save(){
      try{
         upsert records;
         return null;

      }
      catch(Exception e){
            message='An Issue Accored when trying to save changes to the records: ' + e.getMessage();
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, message));
            return null; 
        }
   }
}