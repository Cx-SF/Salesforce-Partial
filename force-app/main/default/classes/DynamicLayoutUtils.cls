public class DynamicLayoutUtils {
    
    /******************************************************************************
    Name: DynamicLayoutUtils.apxc
    Description: Apex class for DynamicLayoutDialog lightning component common utils
    
    Change History:
    
    Name			Date			Comments
    -------------------------------------------------------------------------------
    Alex Levchenko 	27-Mar-2019		Initial version
    
    *******************************************************************************/    

    public DynamicLayoutUtils() {}
    
    public static HttpCalloutMock mock = null;
    
    public static String getApexSessionId() {
      	String sessionId = '';
        PageReference reportPage = Page.SessionId;
        String vfContent = '';
        if (Test.isRunningTest()) {
            vfContent = 'Start_Of_Session_Id' + UserInfo.getSessionId() + 'End_Of_Session_Id';
        } else { vfContent = reportPage.getContent().toString();
        }
        Integer startP = vfContent.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
        endP = vfContent.indexOf('End_Of_Session_Id');
        sessionId = vfContent.substring(startP, endP);
        return sessionId;  
    }
    
    public static String getBaseURL() {
        String baseURL = null;
        String urlTypeName = (Site.getSiteType() != null) ? 'Service Community Base URL' : 'Salesforce Base URL';
        Environment_URLs__mdt[] mdUrls = ([Select URL_Value__c From Environment_URLs__mdt Where URL_Type__c = :urlTypeName]);
        if (mdUrls.size() > 0) {
            baseURL = mdUrls[0].URL_Value__c;
        } else {
            baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        }
        return baseURL;
    }
    
    public static String doRest(String endPoint, String method) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + getApexSessionId());
        req.setTimeout(60000);
        req.setEndpoint(endPoint);
        req.setMethod(method);
        if (Test.isRunningTest() && (mock != null)) {
            return mock.respond(req).getBody();
        } else {
            HttpResponse resp = http.send(req);
            return resp.getBody();
        }
    }
    
    public static String toolingAPI(String query) {
        //String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return doRest(getBaseURL() + '/services/data/v41.0/tooling/query?q='+ (query.replace(' ', '+')), 'GET');
    }
    
    /*
    public static String replaceSoqlBindVariables(String query) {
        String result = query;
        String[] queryWords = query.split('\\s+');
        for (String word : queryWords) {
            if (word.startsWith(':')) {
                String bindName = word.toUpperCase();
                switch on bindName 
                { 
                    when ':USERID' {
                        result = result.replace(word, '\'' + UserInfo.getUserId() + '\'');
                    }
                    when ':USERTYPE' {
                        result = result.replace(word, '\'' + UserInfo.getUserType() + '\'');
                    }
                    when ':USEREMAIL' {
                        result = result.replace(word, '\'' + UserInfo.getUserEmail() + '\'');
                    }
                }
            }
        }
        return result;
    }
	*/
    
    public static List<String> getSoqlQueryColumns(String query) {
        List<String> result = new List<String>();
        String[] queryWords = query.split('\\s+');
        boolean parse = false;
        for (String word : queryWords) {
            if (word.equalsIgnoreCase('FROM')) {
                parse = false;
            }
            if (parse) {
                if (word.indexOf(',') > 0) {
                    String[] columns = word.split(',');
                    for (String col : columns) {
                        result.add(col.toUpperCase());
                    }
                } else {
                    String col = word.replaceAll(',', '');
                    result.add(col.toUpperCase());
                }
            }
            if (word.equalsIgnoreCase('SELECT')) {
                parse = true;
            }
        }
        return result;
    }
    
    private static String CONTACTID =getContactId();
    private static String getContactId(){
        String USERID = UserInfo.getUserId();
        return [select contactid from user where id = :USERID][0].contactid ;
    }
    
    private static String PROFILENAME =getProfileName();
    private static String getProfileName(){
        String USERID = UserInfo.getUserId();
        return [select Dy_ProfileName__c from user where id = :USERID][0].id ;
    }
    
    public static void setRecordFieldCustomDefaultValue(Object_Field_Dependency__mdt metadata, LayoutField field) {
        String USERID = UserInfo.getUserId();
        String USERTYPE = UserInfo.getUserType();
        String USEREMAIL = UserInfo.getUserEmail();
 
        String defaultValueSource = (UserInfo.getUserType().equals('Standard')) ? metadata.Field_Internal_Default_Value__c : metadata.Field_External_Default_Value__c;
        if (defaultValueSource != null && !defaultValueSource.equals('')) {
            Integer queryStartIdx = defaultValueSource.indexOf('[');
            if (queryStartIdx == 0) {
                Integer queryEndIdx = defaultValueSource.indexOf(']', queryStartIdx);
                if (queryEndIdx > 0) {
                    String query = defaultValueSource.substring(queryStartIdx + 1, queryEndIdx) + ' LIMIT 1';
                    //query = replaceSoqlBindVariables(query) + ' LIMIT 1';
                    List<String> columns = getSoqlQueryColumns(query);
                    if (columns.size() != 1) {
                        field.setDefaultValue(field.getFieldApiName() + ': More than one column in default query');
                        field.setDefaultValueStatus('INVALID');
                    } else {
                        try {
                            String col = columns[0];
                            List<sObject> sobj = Database.query(query);
                            if (sobj.size() > 0) {
                            	field.setDefaultValue(String.valueOf(sobj[0].get(col)));
                            	field.setDefaultValueStatus('VALID');
                            }
                        } catch(System.QueryException e) {
                            System.debug(e);
                            field.setDefaultValue(field.getFieldApiName() + ': Error in default query: ' + e.getMessage());
                            field.setDefaultValueStatus('INVALID');
                        }
                    }
                } else {
                    field.setDefaultValue(field.getFieldApiName() + ': Missing query closing tag ]');
                    field.setDefaultValueStatus('INVALID');
                }
            } else if (queryStartIdx > 0) {
                field.setDefaultValue(field.getFieldApiName() + ': Cannot merge constants with queries for default values');
                field.setDefaultValueStatus('INVALID');
            } else {
                field.setDefaultValue(defaultValueSource);
                field.setDefaultValueStatus('VALID');
            }
        }
    }
    
    public static void setAutosuggestFieldValue(LayoutField field, String recordId) {
        String query = 'Select ' + field.getFieldApiName() + ' From ' + field.getObjectApiName() + ' Where Id = :recordId';
        try {
            List<sObject> sobj = Database.query(query);
            if (sobj.size() > 0) {
                field.setFieldValue(String.valueOf(sobj[0].get(field.getFieldApiName())));
            } 
        } catch(System.QueryException e) {
                System.debug(e);
                field.setFieldValue(null);
        }
    }
    
    public static String getObjectInfo(String sObjectApiName) {
        //String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        //String baseURL = 'https://checkmarx-uat.cs110.force.com';
        String uiApiResource = '/services/data/v45.0/ui-api/object-info/' + sObjectApiName;
        return doRest(getBaseURL() + uiApiResource, 'GET');
    }
    
    public static String getObjectLabel(String sObjectApiName) {
        return Schema.getGlobalDescribe().get(sObjectApiName).getDescribe().getLabel();
    }
    
    public static String getPicklistValuesByRecordType(String sObjectApiName, String recordTypeId) {
        //String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        //String baseURL = 'https://checkmarx-uat.cs110.force.com';
        String uiApiResource = '/services/data/v45.0/ui-api/object-info/' + sObjectApiName + '/picklist-values';
        if (recordTypeId != null && recordTypeId != '') {
            uiApiResource = uiApiResource + '/' + recordTypeId;
        }
        return doRest(getBaseURL() + uiApiResource, 'GET');
    }
    
    public static List<RecordType> getRecordTypes(String sObjectName) {
        return [Select Name, Id From RecordType Where SobjectType = :sObjectName];
    }
    
    public static String getRecordLayoutMetadata(String sObjectApiName, String recordTypeId, String mode) {
        //String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        //String baseURL = 'https://checkmarx-uat.cs110.force.com';
        String uiApiResource = '/services/data/v45.0/ui-api/layout/' + sObjectApiName;
        String layoutMode = 'View';
        if (mode.equals('EDIT')) {
            layoutMode = 'Edit';
        } else if (mode.equals('NEW')) {
            layoutMode = 'Create';
        }
		uiApiResource = uiApiResource + '?mode=' + layoutMode;
        if (recordTypeId != null && recordTypeId != '') {
            uiApiResource = uiApiResource + '&recordTypeId=' + recordTypeId;
        }
        return doRest(getBaseURL() + uiApiResource, 'GET');
    }

    public static String getRecordTypeId(String sObjectName, String recordId) {
        String recordTypeId = null;
        List<RecordType> recordTypes = Database.query('Select Id FROM RecordType WHERE SobjectType = :sObjectName');
        if (recordTypes.size() > 0) {
            List<sObject> sobjList = Database.query('SELECT RecordTypeId FROM ' + sObjectName + ' WHERE Id = :recordId');
            recordTypeId = (String)sobjList[0].get('RecordTypeId');
        }
        if (recordTypeId == null) {
            recordTypeId = getDefaultRecordTypeId(sObjectName);
        }
        return recordTypeId;
    }
    
    public static String getRecordTypeName(String recordTypeId) {
        String name = null;
        List<RecordType> rts = [Select Name FROM RecordType WHERE Id = :recordTypeId];
        if (rts.size() > 0) {
            name = rts[0].Name;
        }
        return name;
    }
    
    public static String getDefaultRecordTypeId(String sObjectName) {
        String result = null;
        Schema.DescribeSObjectResult dsr = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) {
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRecordType = rti;
                result = rti.getRecordTypeId();
                break;
            }
        }
        return result;
    }
    
    public static String getSiteType() {
        return Site.getSiteType();
    }
    
    public static boolean deleteAttachment(String documentId) {
        ContentDocument[] cds = [SELECT Id FROM ContentDocument Where Id = :documentId];
        
        System.debug('Attachments size = ' + cds.size());
        
        if (cds.size() > 0) {
            delete cds;
            return true;
        }
        return false;
    }
   
       
    public static Map<String, LayoutField> getObjectFieldsMetadata(String sObjectName, String recordId) {
        Map<String, LayoutField> objectFields = new Map<String, LayoutField>();
        List<Object_Field_Dependency__mdt> dynamicFields = [SELECT Field_API_Name__c, 
																   conditional_required__c,
                                                            	   Field_Display_Condition__c,
                                                            	   Field_Internal_Default_Value__c,
                                                            	   Field_External_Default_Value__c,
                                                            	   Use_Autosuggest__c,
                                                            	   Required__c
                                                       		  FROM Object_Field_Dependency__mdt
                                                      		 WHERE Object_Name__c = :sObjectName];
        Map<String, Object_Field_Dependency__mdt> dynamicFieldsMap = new Map<String, Object_Field_Dependency__mdt>();
        for (Object_Field_Dependency__mdt f : dynamicFields) {
        	dynamicFieldsMap.put(f.Field_API_Name__c, f);
        }
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        for (Schema.SObjectField ft : fieldMap.values()) {
            Schema.DescribeFieldResult fd = ft.getDescribe();
            LayoutField field = new LayoutField();
            field.setObjectApiName(sObjectName);
            field.setFieldApiName(fd.getName());
            String dataType = String.ValueOf(fd.getType());
            field.setDataType(dataType);
            field.setReferenceObject(fd.getRelationshipName());
            field.setIsAccessible(Boolean.ValueOf(fd.isAccessible()));
            field.setHelpText(fd.getInlineHelpText());
            if (field.isAccessible()) {
                Object_Field_Dependency__mdt f = dynamicFieldsMap.get(fd.getName());
                if (f != null) {
                    field.isRequired=f.Required__c;
                    field.setDisplayCondition(f.Field_Display_Condition__c);
					field.setConditionalRequired(f.conditional_required__c);
                    boolean isAutosuggest = (dataType.equals('PICKLIST') && Boolean.ValueOf(f.Use_Autosuggest__c)) ? true : false;
                    field.setUseAutosuggest(isAutosuggest);
                    setRecordFieldCustomDefaultValue(f, field);
                    if (isAutosuggest && recordId != null) {
                        setAutosuggestFieldValue(field, recordId);
                    }
                }
                objectFields.put(fd.getName(), field);
            }  
        }
        return objectFields;
    }
    
    private static Id getContactIdByEmail(String email) {
        Id result = null;
        if (email == null || String.isBlank(email)) {
            return result;
        }
        List<Contact> contacts = [
            SELECT Id
              FROM Contact
             WHERE Email = :email
        ];
        if (!contacts.isEmpty()) {
            result = contacts[0].Id;
        }
        return result;
    }
    
    public static Map<String, Object> getMetadata(String sObjectName, String recordTypeId, String mode, String recordId, String accountId) {
        Map<String, Object> result = new Map<String, Object>();
        result.put('SiteType', getSiteType());
        result.put('ObjectLabel', getObjectLabel(sObjectName));
        result.put('RecordTypeName', getRecordTypeName(recordTypeId));
        result.put('ObjectFieldsMetadata', JSON.serialize(getObjectFieldsMetadata(sObjectName, recordId)));
        result.put('LayoutMetadata', getRecordLayoutMetadata(sObjectName, recordTypeId, mode));
        result.put('PicklistValues', getPicklistValuesByRecordType(sObjectName, recordTypeId));
        result.put('RecordTypes', JSON.serialize(getRecordTypes(sObjectName)));
        if (accountId != null) {
            result.put('ContactId', getContactIdByEmail(UserInfo.getUserEmail()));
        }
        return result;
    }

}