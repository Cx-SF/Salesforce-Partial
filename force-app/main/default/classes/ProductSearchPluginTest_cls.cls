@isTest
public class ProductSearchPluginTest_cls {
    
    private static testMethod void testOverview(){
        SBQQ__Quote__c q=new SBQQ__Quote__c();
        insert q;
        String fieldName='Name';
        
        Map<String,Object> fieldValuesMap=new Map<String,Object>();
        fieldValuesMap.put('Name', q);
        fieldValuesMap.put('SBQQ__Type__c', q);
        
        ProductSearchPlugin_cls searchPlugin = new ProductSearchPlugin_cls();
        searchPlugin.getAdditionalSearchFilters(q, fieldValuesMap);
        searchPlugin.getAdditionalSuggestFilters(q, fieldValuesMap);
        searchPlugin.getFilterDefaultValue(q, fieldName);
        searchPlugin.getInputDefaultValue(q, fieldName);
        searchPlugin.isFilterHidden(q, fieldName);
        searchPlugin.isInputHidden(q, fieldName);
        searchPlugin.isSearchCustom(q, fieldValuesMap);
        searchPlugin.isSuggestCustom(q, fieldValuesMap);
        searchPlugin.search(q, fieldValuesMap);
        searchPlugin.suggest(q, fieldValuesMap);
        
    }
}