/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_PS_EntitlementTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_PS_EntitlementTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new PS_Entitlement__c());
    }
}