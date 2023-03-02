@isTest 
private class CaseActionButtonsLayout_Ctrl_Test {

	@isTest
	private static void test1() {
		Utils.CodeOff = true;
		Account a = TestObjectCreator.CreateAccount();
		insert a;

		Case c = TestObjectCreator.CreateCase(a);
		insert c;

		CaseActionButtonsLayout_Ctrl.loadData(c.Id);
		CaseActionButtonsLayout_Ctrl.closeCase(c);
	}
}