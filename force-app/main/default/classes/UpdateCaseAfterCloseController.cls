public without sharing class UpdateCaseAfterCloseController {
    
    public static void updateStatusCase(sObject objRecord){
        Id objId = objRecord.Id;
        String objType = String.valueOf(objId.getsobjecttype());
        List <Fields_to_Update__mdt> fieldsList = [SELECT Id, API_Field_Name__c, Field_value__c, Object_API__c FROM Fields_to_Update__mdt
                                                  WHERE Object_API__c = :objType];
        for(Fields_to_Update__mdt fieldName : fieldsList){
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(fieldName.Object_API__c);
            Schema.DescribeSObjectResult objectDesc = objectType.getDescribe();
            Schema.DescribeFieldResult fieldDesc = objectDesc.fields.getMap().get(fieldName.API_Field_Name__c).getDescribe();
            objRecord.put(fieldName.API_Field_Name__c, updateFieldType(fieldDesc, fieldName.Field_value__c));
        }
        update objRecord;
    }
    
    private static Object updateFieldType(Schema.DescribeFieldResult fieldDesc, String fieldValue){
        if(fieldDesc.getType() == Schema.DisplayType.Integer){
            return Integer.valueOf(fieldValue);
        } else if(fieldDesc.getType() == Schema.DisplayType.Boolean){
            return Boolean.valueOf(fieldValue);
        } else if(fieldDesc.getType() == Schema.DisplayType.DOUBLE){
            return Decimal.valueOf(fieldValue);
        }
        return fieldValue;
    }
}