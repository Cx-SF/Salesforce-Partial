public without sharing class Healthcheck_LaunchCloneFlow {
  static public void Healthcheck_LaunchCloneFlow (list<CSM__c> newHCs, map<Id,CSM__c> oldHCs){
        system.debug('Naama in class');
        list<CSM__c> relevantHCs=new list<CSM__c>();
        for (CSM__c hc: newHCs)
        {
            if ((oldHCs==null && (hc.isClone() || hc.Solution_Suggestions__c =='testClass')) || (oldHCs!=null && hc.CX_Cloned_Record__c!=oldHCs.get(hc.Id).CX_Cloned_Record__c && hc.CX_Cloned_Record__c == true))
            {
                relevantHCs.add(hc);
            }
        }
        
        system.debug('Naama relevantHCs: '+relevantHCs);
        
        if (relevantHCs.isEmpty())
            return;
        
        try{
            for(CSM__c hc: relevantHCs)
            {
                Map<String, String> params = new Map<String, String>();
                params.put('NewHealthcheckID', hc.Id);
                params.put('recordID', hc.Record_ID__c);
                system.debug('Naama params: '+params);
                Flow.Interview.Clone_Healthcheck_Products flow = new Flow.Interview.Clone_Healthcheck_Products(params);
                flow.start();
                system.debug('Naama flow started');
            }
        }catch(Exception e){
                ErrorMailSender.sendEmail('Error in Healthcheck_LaunchCloneFlow',e.getMessage()+'<br/>Line: '+e.getLineNumber()+'<br/>'+e.getStackTraceString(),new list<String>{System.Label.toAddressesForLicenseGenerationApexErrors});
        }
    }
}