public class QuoteLineItemHandler {
    private static List<Id> getOliIds(List<QuoteLineItem> qlis) {
        List<String> serializedQlis = JSON.serialize(qlis).split('"attributes"');
        serializedQlis.remove(0);
        
        List<Id> oliIds = new List<Id>();
        for (String qli : serializedQlis)
            try {
                oliIds.add(qli.split('"OpportunityLineItemId"')[1].split('"')[1]);
            } catch (Exception e) {
                oliIds.add(null);
            }
        
        return oliIds;
    }

    public static void onInsert(List<QuoteLineItem> qlis) {
        List<Id> oliIds = getOliIds(qlis);
        //if ((new List<Id>((new Set<Id>(oliIds))))[0] == null) return;
    
        Map<Id, OpportunityLineItem> oliById = new Map<Id, OpportunityLineItem>([SELECT Id, Languages__c, Duration__c, Duration_Type__c FROM OpportunityLineItem WHERE Id IN :oliIds]);
        
        Integer i = 0;
        for (QuoteLineItem qli : qlis) {
            OpportunityLineItem oli = oliById.get(oliIds[i]);
            if (oli != null) {
                qli.Opp_Line_Item_ID__c = oli.Id;
                qli.Languages__c = oli.Languages__c;
                qli.Duration__c = oli.Duration__c;
                qli.Duration_Type__c = oli.Duration_Type__c;
            }
            i++;
        }
    }
    /*    
    public static void onUpdate(List<QuoteLineItem> qlis, Map<Id, QuoteLineItem> OqliById) {
        List<Id> oliIds = getOliIds(qlis);
        //if ((new List<Id>((new Set<Id>(oliIds))))[0] == null) return;

        Map<Id, OpportunityLineItem> oliById = new Map<Id, OpportunityLineItem>([SELECT Id FROM OpportunityLineItem WHERE Id IN :oliIds]);
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        
        //Integer i = 0;
        //for (QuoteLineItem qli : qlis) {
        //    if (qli.Pull_Updates__c) {
        //        OpportunityLineItem oli = oliById.get(oliIds[i]);
        //        if (oli != null) {
        //            qli.Opp_Line_Item_ID__c = oli.Id;
        //            qli.Languages__c = oli.Languages__c;
        //            qli.Duration__c = oli.Duration__c;
        //            qli.Duration_Type__c = oli.Duration_Type__c;
        //        }
        //        qli.Pull_Updates__c = false;
        //    } else {
        //        OpportunityLineItem oli = oliById.get(oliIds[i]);
        //        if (oli != null) {
        //            oli.Pull_Updates__c = false;
        //            olis.add(oli);
        //        }
        //    }
        //    i++;
        //}
        
        Integer i = 0;
        for (QuoteLineItem qli : qlis) {
            if (!qli.Disable_Update_Trigger__c && !OqliById.get(qli.Id).Disable_Update_Trigger__c) {
                OpportunityLineItem oli = oliById.get(oliIds[i]);
                if (oli != null) {
                    oli.Quote_Line_Item_ID__c = qli.Id;
                    oli.Languages__c = qli.Languages__c;
                    oli.Duration__c = qli.Duration__c;
                    oli.Duration_Type__c = qli.Duration_Type__c;
                    oli.Disable_Update_Trigger__c = true;
                    olis.add(oli);
                }
            } else
                qli.Disable_Update_Trigger__c = false;
            i++;
        }
        
        update olis;
    }
    
    public static void afterUpdate(List<QuoteLineItem> qqlis) {
        Set<Id> qliIds = new Map<Id, QuoteLineItem>(qqlis).keySet();
        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE Id IN :qliIds AND Disable_Update_Trigger__c=true];
        for (QuoteLineItem qli : qlis)
            qli.Disable_Update_Trigger__c = false;
        update qlis;
    }
    */
}