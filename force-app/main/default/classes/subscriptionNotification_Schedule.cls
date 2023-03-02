global class subscriptionNotification_Schedule implements Schedulable {
    public static String CRON_EXP = '0 0 0 3 9 ? 2022'; //Used for test class only

    global void execute(SchedulableContext sc) {
        system.debug('iCloudius - subscriptionNotification_Schedule - START ');
        
        subscriptionNotification_Batch theBatch = new subscriptionNotification_Batch ();
        id idBatch = Database.executeBatch(theBatch);
    }
}