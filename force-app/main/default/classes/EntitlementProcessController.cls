public class EntitlementProcessController {
     //Test Class: EntitlementProcessControllerTest
    private List<Id> batchClassIdList=new List<Id>();
    private Id inactiveContractbatchClassId;
    final public String NOT_START = 'not_started';
    final public String PROCESSING = 'processing';
    final public String FINISHED = 'finished';
    public String batchStatus {get;set;}
    public Id batchId {get;set;}
    public Map<Id,String> ClassMap=new Map<Id,String>();
    public String message {get;set;}
    public Integer errornum {get;set;}
    public Boolean runOver{ get; set; }
    public dateTime nowDateTime{ get; set; }
    public Integer count{get;set;}
    
    public String AccountsIds{get;set;}
    
    public EntitlementProcessController (){
        batchClassIdList.clear();
        for(ApexClass ac:[Select Name, Id From ApexClass Where Name = 'ContractUpdateServiceAvailabilityBatch' or name='EntitlementsProcessActiveContractBatch' or name ='EntitlementsProcessInactiveContractBatch']){
            batchClassIdList.add(ac.Id);
            if(ac.Name=='EntitlementsProcessInactiveContractBatch')
                inactiveContractbatchClassId=ac.Id;
            ClassMap.put(ac.Id, ac.Name);
        }
        batchStatus = NOT_START;
        nowDateTime=system.now();
        batchId = null;
        message = ''; 
        errornum =0; 
        count=0;
        
    }
    public boolean getShowProgressBar() {
        if(batchStatus == PROCESSING )
            return true;
        return false;
    }
    //this method will fetch apex jobs and will update status,JobItemsProcessed,NumberOfErrors,TotalJobItems
    public BatchJob[] getJobs() {
        
        List<AsyncApexJob> apexJobs = 
            [Select TotalJobItems, Status, NumberOfErrors, ExtendedStatus, JobItemsProcessed, Id, JobType, ApexClassId, CreatedDate,ParentJobId From AsyncApexJob Where ApexClassId in :batchClassIdList AND CreatedDate>=:nowDateTime Order by CreatedDate DESC];
        List<BatchJob> jobs = new List<BatchJob>();      
        
        if(apexJobs.size() == 0) {
            return new List<BatchJob>();
        }
        
        for(AsyncApexJob job : apexJobs) {
            
            
            BatchJob bj = new BatchJob();
            bj.isCompleted = false;
            bj.NumberOfErrors=0;
            
            /* if(job.ApexClassId == batchClassId) {
				bj.Job_Type = 'Process 1';
			} */           
            bj.aj = job;
            if(job.ApexClassId!=null){
                if(ClassMap.get(job.ApexClassId)!=null)
                    bj.Class_Name=ClassMap.get(job.ApexClassId);             
            }
            
            //NOT EXIST ROWS IN SCOPE
            if(job.jobItemsProcessed == 0 && job.NumberOfErrors==0 && job.Status=='Completed'){
                bj.Percent= 100;
                bj.isCompleted = true;
                jobs.add(bj);
                // FINISHED
                if(job.ApexClassId == inactiveContractbatchClassId && job.Status=='Completed') {
                    batchStatus = FINISHED;  
                }
                continue;
            }
            
            // NOT START YET
            if(job.jobItemsProcessed == 0) {
                bj.Percent= 0;
                jobs.add(bj);
                continue;
            }
            
            if( job.TotalJobItems==0)
                continue;
            Decimal d = job.jobItemsProcessed;
            d = d.divide(job.TotalJobItems, 2)*100;
            bj.Percent= d.intValue();
            
            
            
            // PROCESSING
            if(bj.Percent != 100){
                jobs.add(bj);
                continue;
            }
            
            // FINISED
            if(job.ApexClassId == inactiveContractbatchClassId && job.Status=='Completed') {
                batchStatus = FINISHED;  
            }
            errornum += job.NumberOfErrors;
            bj.NumberOfErrors=job.NumberOfErrors;
            bj.isCompleted = true;
            
            jobs.add(bj);    
            
        }
        return jobs;
        
    }
    
    public PageReference StartBactJob() {
        //execute RecordTypeAccessFinder batch
      //  if(!test.isRunningTest()){
            runOver=false;
            nowDateTime=system.now();
            system.debug('nowDateTime:'+nowDateTime);
            system.debug('AccountsIds:'+AccountsIds);
            List<String> accountsToProccess = String.isBlank(AccountsIds) ? new List<String>() : AccountsIds.replaceAll(' ', '').split(',')  ;
            ContractUpdateServiceAvailabilityBatch ContractUpdate = new ContractUpdateServiceAvailabilityBatch(accountsToProccess);
            this.batchId = Database.executeBatch(ContractUpdate,100);  
            system.debug('************batchid:'+batchid);
      //  }
        batchStatus = PROCESSING;
        return null;
    }
    
    public PageReference updateProgress() {
        count++;
        if(batchStatus == FINISHED) {
            message = 'COMPLETED';
        }
        return null;
    }
    public class BatchJob{
        public AsyncApexJob aj {get;set;}
        public Integer Percent {get;set;}
        //public String Job_Type {get;set;}
        public String Class_Name {get;set;}
        public Boolean isCompleted {get;set;}
        public Integer NumberOfErrors {get;set;}
        public BatchJob(){}     
    }
    
}