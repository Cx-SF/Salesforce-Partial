global class EntitlementProcessScheduled implements Schedulable {
        //Test Class: EntitlementProcessScheduledTest
    global void execute(SchedulableContext sc) {
       List<String> accIds = new List<String>();
       ContractUpdateServiceAvailabilityBatch ContractUpdate = new ContractUpdateServiceAvailabilityBatch(accIds);
       Database.executeBatch(ContractUpdate,100);  
    }
}