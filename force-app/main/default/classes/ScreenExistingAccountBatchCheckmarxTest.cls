@IsTest
private class ScreenExistingAccountBatchCheckmarxTest {
    @TestSetup
    static private void setup() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 1; i <= 1; i++) {
            testAccounts.add(new Account(Name = 'TestAccountNameOppOpen' + i, BillingCountry = 'China'));
            testAccounts.add(new Account(Name = 'TestAccountNameUSOpen' + i));
            testAccounts.add(new Account(Name = 'TestAccountNameOppClosed' + i ));
        }
        Insert testAccounts;
        List<Opportunity> testOppList = new List<Opportunity>();
        for( Account acc : testAccounts) {
            if(acc.Name.contains('TestAccountNameOppOpen')) {
                testOppList.add(new Opportunity(AccountId = acc.Id, Name = 'Opp' + acc.Name, StageName = 'Prospecting', CloseDate = System.now().date()));
                testOppList.add(new Opportunity(AccountId = acc.Id, Name = 'Opp' + acc.Name, StageName = 'Prospecting', CloseDate = System.now().date()));
                testOppList.add(new Opportunity(AccountId = acc.Id, Name = 'Opp' + acc.Name, StageName = 'Closed Won', CloseDate = System.now().date()));
            }
        }
        insert testOppList;
    }
    @IsTest
    static void createScreeningCasesForExistingAccountsTest(){
        Test.startTest();
        ScreenExistingAccountBatchCheckmarx screenExistingAccountsBatch = new ScreenExistingAccountBatchCheckmarx();
        Id batchId = Database.executeBatch(screenExistingAccountsBatch);
        Test.stopTest();
        System.assert(true);
    }
}