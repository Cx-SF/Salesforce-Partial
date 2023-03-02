global class AutoSolvedProcessScheduled implements Schedulable {
        //Test Class: 
    global void execute(SchedulableContext sc) {
	   AutoSolvedProcessBatch TBatch = new AutoSolvedProcessBatch();
       string batchId = Database.executeBatch(TBatch,100);
    }
}