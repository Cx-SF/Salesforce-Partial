public with sharing class CostomerOverviewAvvountPO_ctrl  {
	@AuraEnabled
	public static Map <String, Object> initComponent(Id POId) {
		System.debug('TSR - Sales Order Id: ' + POId);
		Map <String, Object> results = new Map <String, Object>();
		Id accId = null;

		List<Account_Planning__c> AccList = [SELECT Id, name, Account__c 
										  FROM Account_Planning__c where Id = :POId];

		System.debug('TSR - query results: ' + AccList[0]);
		
		if (AccList != null && !AccList.isEmpty()) {
			accId = AccList[0].Account__c;
		}

		results.put('AccId' ,accId);

		return (results);

	}
}