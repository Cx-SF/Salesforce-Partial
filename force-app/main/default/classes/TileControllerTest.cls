@isTest
private class TileControllerTest {
	
	@isTest static void covaregeTest() {
		List<TileController.ListViewWrapper> wrappers = new List<TileController.ListViewWrapper>();
		TileController.ListViewWrapper wp1 = new TileController.ListViewWrapper();
		wp1.id = '';
		wp1.objType = 'Case';
		wrappers.add(wp1);
		ListView[] views = [SELECT id, SObjectType FROM ListView WHERE SObjectType = 'Case'];
		TileController.ListViewWrapper wp2 = new TileController.ListViewWrapper();
		wp2.id = views[0].id;
		wp2.objType = 'Case';
		wrappers.add(wp2);
		TileController.ListViewWrapper wp3 = new TileController.ListViewWrapper();
		wp3.id = views[0].id;
		wp3.objType = 'Cases';
		wrappers.add(wp3);
		TileController.getListViewSizes(wrappers);
	}
	
}