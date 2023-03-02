public class IdeaHistoryTrackingController {

    	//ApexPages.StandardController controller; 
    public Integer CountTotalRecords{get;set;}
    public String QueryString {get;set;}
    public Integer OffsetSize = 0;
    private Integer QueryLimit = 15;
    public list<Idea_History__c> records;
    public String RecordId {get;set;}
    public string ideaId {get; set;} 

    
    
   
    
    public IdeaHistoryTrackingController() {
        
        ideaId = ApexPages.currentPage().getParameters().get('id');
        CountTotalRecords= [select count() from Idea_History__c where Feature_Request__r.Id =: ideaId];
        system.debug('ideaId:' + ideaId);                                    
    }
    
    public list<Idea_History__c> getRecords() {
        
        records = new list<Idea_History__c>();
        records = [Select status_Previous__c, status_New__c, Planned_version_Previous__c, Planned_version_New__c, CreatedDate, CreatedBy.Name, 
                   CreatedById, Assigned_PM_Previous__c, Assigned_PM_New__c,Feature_Request__c 
                   From Idea_History__c where Feature_Request__r.Id =: ideaId limit :QueryLimit offset :OffsetSize];
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
 
    public PageReference Next() {
        OffsetSize += QueryLimit;
        return null;
    }
 
    public PageReference Previous() {
        OffsetSize -= QueryLimit;
        return null;
    }
    public PageReference FirstPage()	{
		OffsetSize = 0;
        return null;
	}
}