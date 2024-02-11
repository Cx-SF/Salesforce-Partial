global class ContactPersonaUpdates_SCHEDULE implements Schedulable {
	
	public static String CRON_EXP = '0 0 0 3 9 ? 2024'; //Used for test class only

    global void execute(SchedulableContext sc) {
        system.debug('Rafa - ContactPersonaUpdates_SCHEDULE - START ');
        
        ContactPersonaUpdates_Batch theBatch = new ContactPersonaUpdates_Batch();
        id idBatch = Database.executeBatch(theBatch);
    }

}