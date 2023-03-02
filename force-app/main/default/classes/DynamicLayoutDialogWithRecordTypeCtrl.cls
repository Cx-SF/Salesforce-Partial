public with sharing class DynamicLayoutDialogWithRecordTypeCtrl {

    @AuraEnabled
    public static List<RecordTypeWrapper> getAvailibleRecordTypes(String sObjectName, Boolean fromVF) {
        System.debug('sObjectName: ' + sObjectName);
        System.debug('fromVF: ' + fromVF);
        List<RecordTypeWrapper> wrappers = new List<RecordTypeWrapper>();
        List<Dynamic_Available_Record_Type__mdt> dart ;
        if (fromVF){
             dart= [SELECT id, label,MasterLabel,QualifiedApiName FROM Dynamic_Available_Record_Type__mdt WHERE Object__c =:sObjectName AND Env__c = 'Classic'];
        } else {
             dart= [SELECT id, label,MasterLabel,QualifiedApiName FROM Dynamic_Available_Record_Type__mdt WHERE Object__c =:sObjectName AND Env__c = 'Lightning'];
        }
        List<String> names = new List<String>();
        for(Dynamic_Available_Record_Type__mdt rt : dart) {
            names.add(rt.label);
        }
        for(RecordType rt : [SELECT Id, Name FROM RecordType WHERE SobjectType = :sObjectName AND Name IN:names]) {
            wrappers.add(new RecordTypeWrapper(rt));
        }

        return wrappers;
    }

    public class RecordTypeWrapper {
        @AuraEnabled
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; }
        public RecordTypeWrapper (RecordType rt) {
            this.value = rt.id;
            this.label = rt.name;
        }
    }

}