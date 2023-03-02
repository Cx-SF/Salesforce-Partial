global class ProductSearchPlugin_cls implements SBQQ.ProductSearchPlugin {
    
    //Created by MH 06/08/19
    //Test Class:ProductSearchPluginTest_cls
    global String getAdditionalSearchFilters(SObject quote, Map<String,Object> fieldValuesMap){
        String additionalFilter = NULL;

        List<User> currentUserNFR=[select id from user where id=:UserInfo.getUserId() and (profile.name in('System Administrator','Sales Operations') or NFR_Available__c = True)]; 
        
        if(currentUserNFR.size()==0){
            additionalFilter = '(Product2.WDCX_Product_Category__c!=\'NFR\') and (Product2.ProductCode!=\'CRD-NOACV\') and (Product2.ProductCode!=\'BLK\') and (Product2.WDCX_Product_Category__c!=\'Russian Market\')';}
       
        //List<User> currentUserCloud=[select id from user where id=:UserInfo.getUserId() and (profile.name in('System Administrator','Sales Operations') or WDCX_CXOD_Available__c = True)];   
       // if(currentUserCloud.size()==0){
          //  additionalFilter = '(Product2.WDCX_Product_View_Aggregation__c!=\'Cloud Products\')';}
       
        return additionalFilter;
    }
    global String getAdditionalSuggestFilters(SObject quote, Map<String,Object> fieldValuesMap){
        return null;
    }
    global Object getFilterDefaultValue(SObject quote, String fieldName){
        return null;
    }
    global Object getInputDefaultValue(SObject quote, String fieldName){
        return null;
    }
    global Boolean isFilterHidden(SObject quote, String fieldName){
        return false;
    }
    global Boolean isInputHidden(SObject quote, String fieldName){
        return false;
    }
    global Boolean isSearchCustom(SObject quote, Map<String,Object> fieldValuesMap){
        return false;
    }
    global Boolean isSuggestCustom(SObject quote, Map<String,Object> fieldValuesMap){
        return false;
    }
    global List<PricebookEntry> search(SObject quote, Map<String,Object> fieldValuesMap){
        return null;
    }
    global List<PricebookEntry> suggest(SObject quote, Map<String,Object> fieldValuesMap){
        return null;
    }
    
}