global class OppWon_SCHEDULE implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        System.debug('iCloudius - OppWon_SCHEDULE - execute');

        OppWon_BATCH theBatch = new OppWon_BATCH();
        Id jobId = Database.executeBatch(theBatch,1);

        System.debug('iCloudius - OppWon_SCHEDULE - jobId: ' + jobId);
    }
}

/*
String CRON_EXP = '0 0 0,3,6,12,15,21 * * ?';
OppWon_SCHEDULE sch = new  OppWon_SCHEDULE   ();
system.schedule('OpportunityWonProcesses', CRON_EXP, sch);
*/