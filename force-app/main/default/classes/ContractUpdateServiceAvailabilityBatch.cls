global class ContractUpdateServiceAvailabilityBatch implements Database.Batchable<sObject>,Database.Stateful{
    //Test Class: EntitlementProcessControllerTest
    global List<EntitlementProcessErrorHandling.SaveResultClass> updateContrcatListError=new List<EntitlementProcessErrorHandling.SaveResultClass>();
    global List<String> accountsToProccess = new List<String>();

    public ContractUpdateServiceAvailabilityBatch(List<String> accountsToProccess){
        this.accountsToProccess = accountsToProccess;
    }

    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        List<Grace_Period_days__mdt> Grace_Period_days=[select Number_Of_Days__c FROM Grace_Period_days__mdt limit 1];
        DateTime dT = system.today().addDays((Integer.valueOf(Grace_Period_days[0].Number_Of_Days__c))*-1);
        String currentDateWithPerioddays =dT.format('yyyy-MM-dd');
        
        string query='select id,accountId, CreatedDate,EndDate,Service_Availability__c';
        query+=',(select SBQQ__Contract__c,SBQQ__Contract__r.AccountId,SBQQ__Product__c,SBQQ__Product__r.WDCx_Product_Classification__c,SBQQ__Product__r.Service_Availability__c from SBQQ__Subscriptions__r) from contract where endDate>='+currentDateWithPerioddays;
        //AND Id IN :accountsToProccess -only for testing
        if(accountsToProccess != null && accountsToProccess.size()>0)
        	query+=' AND accountId IN: accountsToProccess';
 
        return Database.getQueryLocator(query);
        //return Database.getQueryLocator('select id,accountId, CreatedDate,EndDate,Service_Availability__c,(select SBQQ__Contract__c,SBQQ__Contract__r.AccountId,SBQQ__Product__c,SBQQ__Product__r.WDCx_Product_Classification__c,SBQQ__Product__r.Service_Availability__c from SBQQ__Subscriptions__r) from contract where endDate>=TODAY AND CreatedDate<=TODAY');
        //AND contractnumber in(\'00000217\',\'00001990\',\'00002083\',\'00002300\')
        //AND Status='Activated'
    }
    
    global void execute(Database.BatchableContext BC, List<Contract> scope){
        
        Map<String,Decimal> ServiceAvailabilityMap=new Map<String,Decimal>();
        for(Service_Availability__mdt sam:[select Label,Order__c from Service_Availability__mdt]){
            if (!(ServiceAvailabilityMap.containsKey(sam.Label))) {
                ServiceAvailabilityMap.put(sam.Label, sam.Order__c);
            }
        }        
        
        for(Contract cont:scope){           
            string serviceAvailability=[select Label,Order__c from Service_Availability__mdt order by Order__c desc limit 1].label;           
            for(SBQQ__Subscription__c sub:cont.SBQQ__Subscriptions__r)
            {
                string productServiceAvailability=sub.SBQQ__Product__r.Service_Availability__c;
                if(sub.SBQQ__Product__r.WDCx_Product_Classification__c=='Service Package' && productServiceAvailability!=null){                   
                    if(ServiceAvailabilityMap.get(serviceAvailability)>ServiceAvailabilityMap.get(productServiceAvailability))
                        serviceAvailability=productServiceAvailability; 
                }  
            }
            
            cont.Service_Availability__c=serviceAvailability; 
        }
        if(scope.size()>0){
            Database.SaveResult[]  updateContractResult= Database.update(scope, false);
            updateContrcatListError.addAll(EntitlementProcessErrorHandling.setErrorList(updateContractResult,scope));
        }
        
    }
    global void finish(Database.BatchableContext BC){
        EntitlementsProcessActiveContractBatch EntBatch = new EntitlementsProcessActiveContractBatch(accountsToProccess);
        string batchId = Database.executeBatch(EntBatch,100);
        if(updateContrcatListError.size()>0)
            EntitlementProcessErrorHandling.sendEmail('Contract', updateContrcatListError,'ContractUpdateServiceAvailabilityBatch');
    }
}