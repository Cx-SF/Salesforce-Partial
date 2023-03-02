public class PlatformEventService {

    public static Set<String> currentSessionEvents = new Set<String>() ;

    public static Boolean thisEventAlreadyExist(String eventString){
        Boolean returnState = currentSessionEvents.contains(eventString);
        System.debug(eventString+' exist = '+returnState);
        currentSessionEvents.add(eventString);
        return returnState;
    }

    public static void publishEvents (Map<Id,Map<String,String>> CasesMap) {
        List<Case_Modification__e> events = new List<Case_Modification__e>();
        for (Id IdCase : CasesMap.keySet()) {

            Map<String, String> CurrentCaseMap = new Map<String, String>();
            CurrentCaseMap = CasesMap.get(IdCase);
            String eventType = CurrentCaseMap.get('Type');

            if (thisEventAlreadyExist(IdCase + eventType) == false) {

                events.add(new Case_Modification__e(
                        CaseId__c = IdCase,
                        Local_DateTime__c = CurrentCaseMap.get('LocalDateTime'),
                        Modified_By_User__c = CurrentCaseMap.get('ModifiedByUser'),
                        Event_Type__c = eventType
                ));
            }
        }

        EventBus.publish(events);

    }


    public static void publishCaseUpdateNotificationEvents_fromCase(List<Case> updatedCases) {
        Map<Id,Map<String,String>> CasesMap = new Map<Id,Map<String,String>>();
        Map<String,String> CurrentCase = new Map<String,String>();

        for (Case mCase : updatedCases) {
            CurrentCase.clear();
            CurrentCase.put('Type','Case');
            CurrentCase.put('Status','In Proggres');
            CurrentCase.put('LocalDateTime',''+Datetime.now());
            CurrentCase.put('ModifiedByUser',UserInfo.getName());

            CasesMap.put(mCase.Id,CurrentCase);
        }

        publishEvents(CasesMap);
    }

    public static void publishCaseUpdateNotificationEvents_fromCaseComment(List<CaseComment> ListCaseComments) {
        Map<Id,Map<String,String>> CasesMap = new Map<Id,Map<String,String>>();
        Map<String,String> CurrentCase = new Map<String,String>();

        for (CaseComment cComment : ListCaseComments) {
            CurrentCase.clear();
            CurrentCase.put('Type','Comment');
            CurrentCase.put('LocalDateTime',''+Datetime.now());
            CurrentCase.put('ModifiedByUser',UserInfo.getName());

            CasesMap.put(cComment.ParentId,CurrentCase);
        }

        publishEvents(CasesMap);
    }

    public static void publishCaseUpdateNotificationEvents_fromEmail(List<EmailMessage> ListEmails) {
        Map<Id,Map<String,String>> CasesMap = new Map<Id,Map<String,String>>();
        Map<String,String> CurrentCase = new Map<String,String>();

        for (EmailMessage email : ListEmails) {

            CurrentCase.clear();
            CurrentCase.put('Type','Email');
            CurrentCase.put('LocalDateTime',''+Datetime.now());
            CurrentCase.put('ModifiedByUser',UserInfo.getName());

            CasesMap.put(email.ParentId,CurrentCase);
        }

        publishEvents(CasesMap);
    }

}