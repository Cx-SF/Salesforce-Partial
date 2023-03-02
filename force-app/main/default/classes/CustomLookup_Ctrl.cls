public without sharing class CustomLookup_Ctrl {
    /**
     * Returns JSON of list of ResultWrapper to Lex Components
     * @objectName - Name of SObject
     * @fld_API_Text - API name of field to display to user while searching
     * @fld_API_Val - API name of field to be returned by Lookup COmponent
     * @lim   - Total number of record to be returned
     * @fld_API_Search - API name of field to be searched
     * @searchText - text to be searched
     * */
    @AuraEnabled (cacheable=true)
    public static String searchDB(String objectName, String fld_API_Text, String fld_API_Val,Integer lim,String fld_API_Search,String searchText, String query_literal, 
								  String field_API_text_to_add, String multi_API_text_to_add, String additionalMode, object additionalList){
        
        searchText='\'%' + String.escapeSingleQuotes(searchText.trim()) + '%\'';

		Set<String> fieldsSet = new Set<String>();

        if(multi_API_text_to_add != null && multi_API_text_to_add != '') fieldsSet.addAll(multi_API_text_to_add.split(','));
		if(field_API_text_to_add != null && field_API_text_to_add != '') fieldsSet.add(field_API_text_to_add);

        String query =  'SELECT ' + fld_API_Text + ', ' + fld_API_Val ;
        
        //query += ', ' + field_API_text_to_add;
		System.debug('#SV# Fields to show in Lookup: '+fieldsSet);
        if(fieldsSet != null && !fieldsSet.isEmpty()){
			for(String fld : fieldsSet){
				query += ', ' + fld;
			}
		}
        query += ' FROM ' + objectName;
        query += ' WHERE ' + fld_API_Search+' LIKE ' + searchText;
        
        if(query_literal != null && query_literal != ''){
        	query += query_literal;
        }

		if (String.isNotBlank(additionalMode) && additionalMode.containsIgnoreCase('RECTRICT') && additionalList != null){
			List <Id> lid = (List <Id>)JSON.deserialize(JSON.serialize(additionalList), List <Id>.class);
			System.debug('iCloudius - additionalList:\n' + JSON.serializePretty(additionalList));
			if (lid != null && !lid.isEmpty()) query += ' AND Id NOT IN :lid';
		}

		query += ' LIMIT '+lim;
        
        system.debug('iCloudius - Searching: ' + query);
        
        List<sObject> sobjList = Database.query(query);
        List<ResultWrapper> lstRet = new List<ResultWrapper>();
        
        for(SObject s : sobjList){
            ResultWrapper obj = new ResultWrapper();
            obj.objName = objectName;
            obj.text = String.valueOf(s.get(fld_API_Text)) ;
            if(field_API_text_to_add != null && field_API_text_to_add != '' && s.get(field_API_text_to_add) != null && s.get(field_API_text_to_add) != ''){
				obj.text = obj.text + ' | ' + String.valueOf(s.get(field_API_text_to_add)) ;
            }
			else if(multi_API_text_to_add != null && multi_API_text_to_add != ''){
				for(String fld : fieldsSet){
					if(fld.contains('.')){
						List<String> tempList = fld.split('\\.');
						if(tempList != null && !tempList.isEmpty() && tempList.size() > 1){
							obj.text += ' | ' + String.valueOf(s.getSObject(tempList[0]).get(tempList[1]));
						}
					}
					else obj.text += ' | ' + String.valueOf(s.get(fld));
				}
			}
            obj.val = String.valueOf(s.get(fld_API_Val))  ;
            lstRet.add(obj);
        } 
         return JSON.serialize(lstRet) ;
    }
    
    public class ResultWrapper{
        public String objName {get;set;}
        public String text{get;set;}
        public String val{get;set;}
    }
}