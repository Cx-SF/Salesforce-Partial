public class OpportunityLineItemHandler {
    private static List<Id> getQliIds(List<OpportunityLineItem> olis) {
        List<String> serializedOlis = JSON.serialize(olis).split('"attributes"');
        serializedOlis.remove(0);

        List<Id> qliIds = new List<Id>();
        for (String oli : serializedOlis)
            try {
                qliIds.add(oli.split('"QuoteLineItemId"')[1].split('"')[1]);
            } catch (Exception e) {
                qliIds.add(null);
            }
        
        return qliIds;
    }

    public static void onInsert(List<OpportunityLineItem> olis) {
        List<Id> qliIds = getQliIds(olis);
        //if ((new List<Id>((new Set<Id>(qliIds))))[0] == null) return;
                        
        Map<Id, QuoteLineItem> qliById = new Map<Id, QuoteLineItem>([SELECT Id, Languages__c, Duration__c, Duration_Type__c FROM QuoteLineItem WHERE Id IN :qliIds]);
        
        Integer i = 0;
        for (OpportunityLineItem oli : olis) {
            QuoteLineItem qli = qliById.get(qliIds[i]);
            if (qli != null) {
                oli.Quote_Line_Item_ID__c = qli.Id;
                oli.Languages__c = qli.Languages__c;
                oli.Duration__c = qli.Duration__c;
                oli.Duration_Type__c = qli.Duration_Type__c;
            }
            i++;
        }
    }
    
    public static void afterInsert(List<OpportunityLineItem> olis) {
        List<Id> qliIds = getQliIds(olis);
        Map<Id, QuoteLineItem> qliById = new Map<Id, QuoteLineItem>([SELECT Id, Languages__c, Duration__c, Duration_Type__c FROM QuoteLineItem WHERE Id IN :qliIds]);
        Integer i = 0;
        for (OpportunityLineItem oli : olis) {
            QuoteLineItem qli = qliById.get(qliIds[i]);
            if (qli != null)
                qli.Opp_Line_Item_ID__c = oli.Id;
            i++;
        }
        update qliById.values();
    }
    
    /*
    public static void onUpdate(List<OpportunityLineItem> olis, Map<Id, OpportunityLineItem> OoliById) {
        List<Id> qliIds = getQliIds(olis);
        //if ((new List<Id>((new Set<Id>(qliIds))))[0] == null) return;

        Map<Id, QuoteLineItem> qliById = new Map<Id, QuoteLineItem>([SELECT Id FROM QuoteLineItem WHERE Id IN :qliIds]);
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();

        //Integer i = 0;
        //for (OpportunityLineItem oli : olis) {
        //    if (oli.Pull_Updates__c) {
        //        QuoteLineItem qli = qliById.get(qliIds[i]);
        //        if (qli != null) {
        //            oli.Quote_Line_Item_ID__c = qli.Id;
        //            oli.Languages__c = qli.Languages__c;
        //            oli.Duration__c = qli.Duration__c;
        //            oli.Duration_Type__c = qli.Duration_Type__c;
        //        }
        //        oli.Pull_Updates__c = false;
        //    } else {
        //        QuoteLineItem qli = qliById.get(qliIds[i]);
        //        if (qli != null) {
        //            qli.Pull_Updates__c = false;
        //            qlis.add(qli);
        //        }
        //    }
        //    i++;
        //}
        
        Integer i = 0;
        for (OpportunityLineItem oli : olis) {
            if (!oli.Disable_Update_Trigger__c && !OoliById.get(oli.Id).Disable_Update_Trigger__c) {
                QuoteLineItem qli = qliById.get(qliIds[i]);
                if (qli != null) {
                    qli.Opp_Line_Item_ID__c = oli.Id;
                    qli.Languages__c = oli.Languages__c;
                    qli.Duration__c = oli.Duration__c;
                    qli.Duration_Type__c = oli.Duration_Type__c;
                    qli.Disable_Update_Trigger__c = true;
                    qlis.add(qli);
                }
            } else
                oli.Disable_Update_Trigger__c = false;
            i++;
        }
        
        update qlis;
    }
    
    public static void afterUpdate(List<OpportunityLineItem> oolis) {
        Set<Id> oliIds = new Map<Id, OpportunityLineItem>(oolis).keySet();
        List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE Id IN :oliIds AND Disable_Update_Trigger__c=true];
        for (OpportunityLineItem oli : olis)
            oli.Disable_Update_Trigger__c = false;
        update olis;
    }
    */
}