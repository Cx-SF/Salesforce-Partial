/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Marketing_CostTest
{
    private static testmethod void testTrigger()
    {
        // Force the dlrs_Marketing_CostTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Marketing_Cost__c());
    }
}