global class ProcessRecordOwnerManagement_SCHEDULE implements Schedulable {
     
    public static String CRON_EXP = '0 0 0 3 9 ? 2052'; //Used for test class only

    global void execute(SchedulableContext sc) {
        system.debug('iCloudius - ProcessRecordOwnerManagement_SCHEDULE - START ');
        
        ProcessRecordOwnerManagement_BATCH theBatch = new ProcessRecordOwnerManagement_BATCH ();
        id idBatch = Database.executeBatch(theBatch,1);
    }
}