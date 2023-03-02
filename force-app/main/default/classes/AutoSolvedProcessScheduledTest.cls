@isTest
public class AutoSolvedProcessScheduledTest {
    @isTest
    static void methodScheduledTest(){
         String CRON_EXP = '0 0 0 3 9 ? 2022';
         String jobId = System.schedule('testBasicScheduledApex',
      		    CRON_EXP, 
         new AutoSolvedProcessScheduled());
    }
}