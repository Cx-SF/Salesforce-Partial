@isTest 
private class Ctrl_DownloadCenter_TEST {

	@isTest
	private static void testName() {
		Ctrl_DownloadCenter.getInitialData(null);
		Ctrl_DownloadCenter.getVersionsAndPlugIns(null);
		Ctrl_DownloadCenter.getAvailableAccounts();
		Ctrl_DownloadCenter.ProductWrap pr = new Ctrl_DownloadCenter.ProductWrap();
		pr = new Ctrl_DownloadCenter.ProductWrap(null, null, null);
		Ctrl_DownloadCenter.getDLURL(new Map <String, Object>{ 'file_name' => '' });
	}
}