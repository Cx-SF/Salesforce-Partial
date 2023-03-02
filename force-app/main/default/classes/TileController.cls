public with sharing class TileController {

	@AuraEnabled
	public static Map<String,Integer> getListViewSizes(List<ListViewWrapper> lstviews) {
		System.debug(lstviews);
		Map<String,Integer> countMap = new Map<String, Integer>();
		for (ListViewWrapper lvw : lstviews) {
			countMap.put(lvw.id, ApexUtil.countRecordsOfListView(lvw.id, lvw.objType));
		}
		return countMap;
	}

	public class ListViewWrapper{
		@AuraEnabled
		public String id { get; set; }
		
		@AuraEnabled
		public String objType { get; set; }
	}
}