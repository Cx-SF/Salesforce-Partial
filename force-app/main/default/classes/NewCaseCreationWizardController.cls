public with sharing class NewCaseCreationWizardController {
	
    @AuraEnabled
    public static String getMetadata() {
        Map<String, Object> result = new Map<String, Object>();
        String userType = UserInfo.getUserType();
        Id defaultRecordTypeId = getDefaultRecordTypeId('Case');
        Id generalRecordTypeId = defaultRecordTypeId;
        // Id caseDeflectionRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Deflection').getRecordTypeId();
        List<sortablegrid__SDG__c> sdgs = [Select sortablegrid__Filter__c From sortablegrid__SDG__c Where Name = 'Case Record Types'];
        String caseTypesFilter = null;
        if (sdgs.size() > 0) {
            caseTypesFilter = sdgs[0].sortablegrid__Filter__c;
        }
        String query = '';
        if (userType.equals('Standard')) {
            query = 'Select Name, Id From RecordType Where SobjectType = \'Case\'';
        } else {
            if (caseTypesFilter != null) {
                query = 'Select Name, Id From RecordType Where (' + caseTypesFilter + ') Or (SobjectType = \'Case\' And Name = \'General\')';
            } else {
                query = 'Select Name, Id From RecordType Where SobjectType = \'Case\' And Name in (\'CxIAST\', \'CxOSA\', \'CXSAST\', \'General\')';
            }
        }
        List<RecordType> recordTypes = Database.query(query);
        RecordType defaultRecordType = new RecordType();
        RecordType generalRecordType = new RecordType();
        if (recordTypes.size() > 0) {
            for (RecordType rt : recordTypes) {
                if (rt.Id == defaultRecordTypeId) {
                    defaultRecordType = rt;
                }
                if (rt.Name == 'General') {
                    generalRecordType = rt;
                    generalRecordTypeId = rt.Id;
                }
            }
            Integer index = recordTypes.indexOf(defaultRecordType);
            recordTypes.remove(index);
			recordTypes.add(0, defaultRecordType);
            index = recordTypes.indexOf(generalRecordType);
            recordTypes.remove(index);
            result.put('RecordTypes', JSON.serialize(recordTypes));
        }
        result.put('DefaultRecordTypeId', defaultRecordTypeId);
        result.put('GeneralRecordTypeId', generalRecordTypeId);
        // result.put('CaseDeflectionRecordTypeId', caseDeflectionRecordTypeId);
        result.put('UserType', userType);
		result.put('available_accounts', Ctrl_DownloadCenter.getAvailableAccounts());
		result.put('running_user', Ctrl_DownloadCenter.getRunningUser());
		System.debug('iCloudius - Metadata:\n' + JSON.serializePretty(result));
        return JSON.serialize(result);
    }
    
    @AuraEnabled
    public static Knowledge__kav[] fetchArticles(String searchKeyWord) {
        String searchInput = String.escapeSingleQuotes(searchKeyWord);
        return [FIND :searchInput IN ALL FIELDS RETURNING Knowledge__kav(Id,KnowledgeArticleId,LastModifiedDate,ArticleNumber,Title,Summary,Problem__c,IsDeleted,Resolution__c,VersionNumber, Article_URL__c Where IsLatestVersion = true And IsVisibleInCsp = true)][0];
    }

	@AuraEnabled
    public static Id createNewCase(Case newCase) {
        Id caseId = null;
        try {
            if (newCase != null) {
                insert newCase;
                caseId = newCase.Id;
            }
        } catch (Exception e) {
            System.debug(e);
        }
        return caseId;
    }
    
    @AuraEnabled
    public static Id createNewCaseWithArticle(Case newcase, Id articleId) {
        Id caseArticleId = null;
        List<Object_Field_Dependency__mdt> metadata = [SELECT Object_Name__c,
                                                       		  Field_API_Name__c, 
                                                              Field_Internal_Default_Value__c,
                                                              Field_External_Default_Value__c,
                                                              Use_Autosuggest__c
                                                       	 FROM Object_Field_Dependency__mdt
                                                     	WHERE Object_Name__c = 'Case' And Field_API_Name__c In ('AccountId', 'ContactId')];
        if (metadata.size() > 0) {
            for (Object_Field_Dependency__mdt md : metadata) {
                LayoutField field = new LayoutField();
                field.setObjectApiName(md.Object_Name__c);
            	field.setFieldApiName(md.Field_API_Name__c);
                DynamicLayoutUtils.setRecordFieldCustomDefaultValue(md, field);
                if (field.getDefaultValueStatus() == 'VALID') {
                    newCase.put(field.getFieldApiName(), field.getDefaultValue());
                }
            }
        }
        Id caseId = createNewCase(newcase);
        
        /*
        Id rtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Deflection').getRecordTypeId();
        
        System.debug('RECORD TYPE LIRON'+rtId);
        
        if (caseId != null) {
             try {
                 Id knowledgeArticleId = ([Select KnowledgeArticleId From Knowledge__kav Where Id = :articleId])[0].KnowledgeArticleId;
                 CaseArticle ca = new CaseArticle();
                 ca.CaseId = caseId;
                 ca.KnowledgeArticleId = knowledgeArticleId;
                 ca.case.recordTypeId = rtId;
                 insert ca;
                 caseArticleId = ca.Id;
             } catch (Exception e) {
                 System.debug(e);
             }
        }
        return caseArticleId;
		*/
        return null;
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
    
    
    ///////////////////////////////////////////////////
    
    @AuraEnabled
    public static List<ConnectApi.managedTopic> getManagedTopics(){
		ConnectAPI.ManagedTopicCollection mTopics = ConnectAPI.ManagedTopics.getManagedTopics('0DB3z000000TO58GAG', ConnectApi.ManagedTopicType.Featured, 2);
        return mTopics.managedTopics;
    }     
}