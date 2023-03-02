public interface ITriggerHandler
{
    void BeforeInsert(List<SObject> triggerNew);

    //void BeforeUpdate(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap);

    //void BeforeDelete(List<SObject> triggerOld, Map<Id, SObject> triggerOldMap);
    void BeforeUpdate(List<SObject> triggerNew,  Map<Id, SObject> triggerOldMap); 

    void AfterInsert(List<SObject> triggerNew, Map<Id, SObject> triggerNewMap);

    void AfterUpdate(List<SObject> triggerNew, List<SObject> triggerOld, Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap);

    void AfterDelete(List<SObject> triggerOld, Map<Id, SObject> triggerOldMap);

    //void AfterUndelete(List<SObject> triggerNew, Map<Id, SObject> triggerNewMap);

    Boolean IsDisabled();
}