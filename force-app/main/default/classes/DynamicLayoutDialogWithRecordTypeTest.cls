@isTest
public with sharing class DynamicLayoutDialogWithRecordTypeTest {
	@isTest
	public static void getAvailibleRecordTypesTestVF () {
		DynamicLayoutDialogWithRecordTypeCtrl.getAvailibleRecordTypes('Case', true);
	}

	@isTest
	public static void getAvailibleRecordTypesTest () {
		DynamicLayoutDialogWithRecordTypeCtrl.getAvailibleRecordTypes('Case', false);
	}
}