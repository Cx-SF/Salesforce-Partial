@isTest(SeeAllData=true)
public with sharing class DynamicLayoutDialogTest {
	
    public class ExampleCalloutMock implements HttpCalloutMock{
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{AccountId: {appearanceOrder: null, dataType: "REFERENCE",defaultValue: "0010E00000SEFtSQAX",defaultValueStatus: "VALID",displayCondition: null,fieldApiName: "AccountId",fieldValue: null,helpText: null,isAccessible: true,label: null,objectApiName: "Case",picklistValues: null,referenceObject: "Account",useAutosuggest: false,}}');
            return res;
        }
    }    
    
    static testMethod void testGetMetadata() 
	{
		
     //   List<Case> cases = [SELECT Id, AccountId, RecordTypeId FROM Case Order By CreatedDate Desc];
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        List<Case> testCases = new List<Case>();
        
        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i));
            testCases.add(new Case (Subject = 'TestCase'+i));
        }
        insert testAccts;
        insert testCases;
        
        Case c = testCases[0];
        
        DynamicLayoutUtils.mock = new ExampleCalloutMock();
        
		Test.StartTest();        
        String metadataView 		= DynamicLayoutDialog.getMetadata('Case', null, 'VIEW', c.Id, c.AccountId);
  		Test.StopTest();
	}
    
     static testMethod void testGetMoreMetadata() 
	{
		
       // Create common test accounts
        List<Account> testAccts = new List<Account>();
        List<Case> testCases = new List<Case>();
        
        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i));
            testCases.add(new Case (Subject = 'TestCase'+i));
        }
        insert testAccts;
        insert testCases;
        
        Case c = testCases[0];
        
        DynamicLayoutUtils.mock = new ExampleCalloutMock();
        
        
		Test.StartTest();        
        String recordTypeId 		= DynamicLayoutDialog.getRecordTypeId('Case', c.Id);
        String metadataNew 			= DynamicLayoutDialog.getMetadata('Case', c.RecordTypeId, 'NEW', null, null);
      
        String recordType = DynamicLayoutUtils.getDefaultRecordTypeId('Case');
  
    	Test.StopTest();
	}
    
    static testmethod void testAttachments()
    {
        DynamicLayoutDialog.deleteAttachment(null);
        DynamicLayoutDialog.deleteContentAttachment(null);
    }
    static testmethod void testLayoutField()
    {
        LayoutField field1, field2;
        String objectName = 'Case';
        List<LayoutField> recFields = new List<LayoutField>();
        List<Object_Field_Dependency__mdt> fields = [SELECT Label, Object_Name__c, Field_API_Name__c, Field_Display_Condition__c
                                                     FROM Object_Field_Dependency__mdt
                                                     WHERE Object_Name__c = :objectName];
        for (Object_Field_Dependency__mdt f : fields) {
            field1 = new LayoutField();
            field2 = new LayoutField(f.Object_Name__c, f.Field_API_Name__c);
            field1.setLabel(f.Label);
            field1.setObjectApiName(f.Object_Name__c);
            field1.setFieldApiName(f.Field_API_Name__c);
            field1.setDisplayCondition(f.Field_Display_Condition__c);
            field1.setAppearanceOrder(null);
            field1.setPicklistValues(null);
        }
        String label = field1.getLabel();
        Integer appearanceOrder = field1.getAppearanceOrder();
        String displayCondition = field1.getDisplayCondition();
        String dataType = field1.getDataType();
        String referenceObject = field1.getReferenceObject();
        List<String> picklistValues = field1.getPicklistValues();
        String helpText = field1.getHelpText();
        String defaultValue = field1.getDefaultValue();
        String fieldValue = field1.getFieldValue();
        String defaultValueStatus = field1.getDefaultValueStatus();
        Boolean useAutosuggest = field1.isUseAutosuggest();
      //  String DefaultRecordTypeId 	= DynamicLayoutUtils.getDefaultRecordTypeId('Case');
		
    }
    
     @isTest
    private static void getParentProductAreaCustomMetadata(){       
      
        Test.startTest();
             List<Parent_Product_Area__mdt> PPA = new List<Parent_Product_Area__mdt>();
             PPA =  DynamicLayoutDialog.getParentProductAreaCustomMetadata();                           
             System.assertEquals(10, PPA.size());              
        Test.stopTest();

    }     
    
    @isTest
    private static void getApiForKnowledgeSearchCustomMetadata(){       
      
        Test.startTest();
             List<API_For_Knowledge_Search__mdt> AFKS = new List<API_For_Knowledge_Search__mdt>();
             AFKS =  DynamicLayoutDialog.getApiForKnowledgeSearchCustomMetadata();                           
             //System.assertEquals(2, AFKS.size());              
        Test.stopTest();

    }      
}