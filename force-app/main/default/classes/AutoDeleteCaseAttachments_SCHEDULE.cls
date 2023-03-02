global class AutoDeleteCaseAttachments_SCHEDULE implements Schedulable {
    
    public static String CRON_EXP = '0 0 0 3 9 ? 2022'; //Used for test class only

    global void execute(SchedulableContext sc) {
        system.debug('iCloudius - AutoDeleteCaseAttachments_SCHEDULE - START ');
        
        AutoDeleteCaseAttachments_BATCH theBatch = new AutoDeleteCaseAttachments_BATCH ();
        id idBatch = Database.executeBatch(theBatch);
    }
}