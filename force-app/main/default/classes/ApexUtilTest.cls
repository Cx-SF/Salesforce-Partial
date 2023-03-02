@isTest
private class ApexUtilTest {
	
	@isTest static void testGetDependendFields() {
		Map<String, List<Schema.PicklistEntry>> dependentStates = ApexUtil.getFieldDependencies('Contact','MailingCountryCode','MailingStateCode');
		System.assertNotEquals(null, dependentStates);
	}
	@isTest static void testListViewsSize(){
		ListView[] views = [SELECT id, SObjectType FROM ListView WHERE SObjectType = 'Case'];
		ApexUtil.countRecordsOfListView(views[0].id,'Case');
	}
    @isTest static void otherTests()
    {
        ApexUtil.enableLog();
        ApexUtil.log('Hello', 'World');
        Case c1 = new Case();
        Map<String, Sobject> m = new Map<String,Sobject>();
        m.put(c1.id, c1);        
        ApexUtil.log('Hello', 'Case', m);
        ApexUtil.log('Hello', 'Case', m, 10);
        Map<String, object> m1 = new Map<String,object>();
        m1.put(c1.id, c1);        
        ApexUtil.log('Hello', 'Case', m1);
        ApexUtil.log('Hello', 'Case', m1, 10);        
        List<Object> l = new List<Object>();
        l.add(c1);
        ApexUtil.log('Hello', 'Case', l);
        ApexUtil.log('Hello', 'Case', l, 10);        
        Set<Object> s = new Set<Object>();
        s.add(c1);
        ApexUtil.log('Hello', 'Case', s);
        ApexUtil.log('Hello', 'Case', s, 10);                
        
        ApexUtil.getCodeLine();
        ApexUtil.disableLog();
    }
	
	
}