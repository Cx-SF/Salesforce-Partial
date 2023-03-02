public with sharing class AutoSolvedProcessBatch implements Database.Batchable<sObject>{
   
    public  String  Query;
    public Messaging.SingleEmailMessage [] emailList;
    public List<FeedItem> feedItemList;
    public Map<Id,sObject> toUpdate;
    
    public Set<Id> caseIds = new Set<Id>();//for testing
    public Set<Id> ExcludeRTIds = new Set<Id>();//ee:added
    public set<String> ExcludeRTNames = new set<String>();
    public set<Id> RtIds = new set<Id>();

    public AutoSolvedProcessBatch(Set<Id> cIds) {//for testing
		caseIds = cIds;//for testing
    }
    public AutoSolvedProcessBatch() {}

    public Database.QueryLocator start(Database.BatchableContext BC){
        //Map<Id,Auto_Solved_Process_Exclude_RecordType__mdt> mapASPERT = new Map<Id,Auto_Solved_Process_Exclude_RecordType__mdt>([SELECT Id FROM Auto_Solved_Process_Exclude_RecordType__mdt]);

        //ExcludeRTIds = mapASPERT.keySet();
        //System.System.debug('ExcludeRTIds :'+ExcludeRTIds);

        //Map<Id,recordtype> mapExcludeRT = new Map<Id,recordtype>([SELECT Id FROM recordtype WHERE Name IN :ExcludeRTIds]);
        //system.debug('mapExcludeRT :'+mapExcludeRT);

        for(Auto_Solved_Process_Exclude_RecordType__mdt ExcludeRT : [SELECT RecordTypeName__c FROM Auto_Solved_Process_Exclude_RecordType__mdt]){
            ExcludeRTNames.add(ExcludeRT.RecordTypeName__c);
        }
        system.debug('ExcludeRTNames :' +ExcludeRTNames);

        Map<Id,RecordType > mapRT = new Map<Id,RecordType >([SELECT id FROM RecordType WHERE DeveloperName IN :ExcludeRTNames AND SobjectType='Case']);

        RtIds = mapRT.keySet();
        system.debug('RtIds :' +RtIds);


        //AND RecordTypeId NOT IN :rtIds //ee:added
        String selectFields = getSelectFields();
        Query = 'SELECT '+ selectFields  + 'FROM Case WHERE On_Hold__c = false and Status != \'Closed\' and RecordTypeId NOT IN :RtIds ';
        if(caseIds.size()>0){
            Query += ' AND  Id IN: caseIds ';//FOR TEST  
        }
        System.debug('MS**Query '+Query);
        System.debug('MS**caseIds '+caseIds);
        System.debug('Database.query(Query) '+Database.query(Query));

        return Database.getQueryLocator(Query);
    }

    public String getSelectFields(){
        String selectFields = 'Id,ContactId,Is_auto_closed__c	,OwnerId,Account_CSM__c,  ';
        List<String> fields = new List<String>();
        //add Email fields
        selectFields += 'ContactEmail,SuppliedEmail,CSM_Email__c,Account_CSM_Email__c,CreatedBy.Email,Account_ISR_Email__c,Account_RSM_Email__c,Account_SDR_Email__c,Account_SE_Email__c,Account_TAM_Email__c,Business_Owner_Email__c,Owner_Manager_Email__c, ';
        selectFields += ' Status,  Status_Change_Date__c  ';//date field
        return selectFields;
    }
    
    public void execute(Database.BatchableContext BC, List<Case> scope){
        system.debug('ee:scope '+scope);
        emailList = new List<Messaging.SingleEmailMessage>(); 
        toUpdate = new Map<Id,sObject>();
        feedItemList = new List<FeedItem>() ;
  
        List<Auto_solved_process_Entry_criteria__mdt> entryCriteriaes = [SELECT Days_number__c,New_Status_Value__c,Label, 
                                                                                (SELECT TemplateId__c , Recipients_Email_Field__c, From_Email_Name__c,From_Email_Address__c,Type__c,New_Status_Value_To_Update__c,Post_Body__c ,CSM_Email_Field__c                                                                              
                                                                                FROM Auto_solved_process_actions__r )
                                                                            FROM Auto_solved_process_Entry_criteria__mdt] ;    
        for(Case obj : scope){//run on records
            Date dateField = (Date)obj.get('Status_Change_Date__c');
            for(Auto_solved_process_Entry_criteria__mdt entryCriteria :entryCriteriaes ){// run on Criteriaes
                Date dateReminder = dateField != null ? dateField.addDays(Integer.ValueOf(entryCriteria.Days_number__c)) : null;  
                if(obj.Status == entryCriteria.New_Status_Value__c &&  dateReminder != null  && dateReminder == Date.today()){
                    checkDayAndDoAction(dateReminder,entryCriteria.Auto_solved_process_actions__r,obj);//if today = dateReminder ans status = metaData value, run on action
                }
            }
        }

        if(toUpdate.size() > 0 ){
            System.debug('MS**BEFORE  toUpdate '+toUpdate);
            update toUpdate.values();
        }
        if(emailList.size() > 0 && !Test.isRunningTest()){
            System.debug('MS**emailList '+emailList);
            Messaging.SendEmailResult[] results =  Messaging.sendEmail(emailList);
            System.debug('MS**results '+results);

        }
        if(feedItemList.size()>0){
            System.debug('MS**feedItemList '+feedItemList);
            insert feedItemList;
        }
    }
  
    public void checkDayAndDoAction(Date dateReimder,List<Auto_solved_process_actions__mdt> actions, sObject obj){
        if(dateReimder == Date.today()){
            for(Auto_solved_process_actions__mdt action :actions){//run on action 
                if(action.Type__c =='Email Alert'){
                    Object recipient = obj.get(action.Recipients_Email_Field__c);
                    System.debug('recipient '+recipient);
                    if(recipient != null){
                        createEmail(action,obj);
                        chatterpost(action,obj);
                    }
                } else if(action.Type__c =='Field Update'){
                    fieldUpdate(action,obj);
                }
            }
        }
    }

    public void createEmail(Auto_solved_process_actions__mdt action, sObject obj){
        OrgWideEmailAddress[] owea = [select Id,DisplayName from OrgWideEmailAddress 
                                        where Address =: action.From_Email_Address__c 
                                        OR DisplayName  =: action.From_Email_Name__c];
                
        Messaging.SingleEmailMessage mail = buildEmailMessage(action,obj);

        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }else{
            mail.setSenderDisplayName(action.From_Email_Name__c);
        }
        emailList.add(mail);
    }

    private Messaging.SingleEmailMessage buildEmailMessage(Auto_solved_process_actions__mdt action, sObject obj){
        Messaging.SingleEmailMessage ret = new Messaging.SingleEmailMessage();
        Case case2 = (Case)obj;
        Id contactId = (Id)obj.get('ContactId');
        Id caseId = (Id)obj.get('Id');
        
        List<String> addresses = new List<String>();
        String  recipient;
        String  recipientCSM;
        if(action.Recipients_Email_Field__c == 'CreatedBy.Email'){
            recipient = case2.CreatedBy.Email;
        }

        recipient = (String) obj.get(action.Recipients_Email_Field__c);
        addresses.add(recipient);

        if (action.CSM_Email_Field__c != null){
            recipientCSM = (String) obj.get(action.CSM_Email_Field__c);
            if(recipientCSM!=null){
                addresses.add(recipientCSM);
            }
        }

        ret.setToAddresses(addresses);

        if((contactId != null) )
           
           //&&(action.Recipients_Email_Field__c=='ContactEmail')){//&&(action.Recipients_Email_Field__c != 'CSM_Email__c'))
         {
            ret.setTargetObjectId(contactId);
            ret.setTemplateId(action.TemplateId__c);
            ret.setWhatId(caseId);
            system.debug('setTargetObjectId');
        } else {
            EmailTemplate templ = [SELECT Id, HTMLValue, Subject FROM EmailTemplate WHERE Id = :action.TemplateId__c];

            List<Messaging.RenderEmailTemplateBodyResult> res = Messaging.renderEmailTemplate(UserInfo.getUserId(), caseId, new List<String> {templ.HTMLValue, templ.subject});
            List<Messaging.RenderEmailTemplateError> err =res[0].getErrors();
            system.debug('res+'+res);
            system.debug('err+'+err);
            ret.setSubject(res[1].getMergedBody());
            ret.setHtmlBody(res[0].getMergedBody());


             system.debug('without setTargetObjectId');
        }
        System.debug('---createEmail--\n MS**mail '+ret);
        return ret;
    }
    
    public void chatterpost(Auto_solved_process_actions__mdt action, sObject obj){
        FeedItem  post = new FeedItem();
		post.ParentId = (ID)obj.get('Id');
        String body = action.Post_Body__c;
        if(action.Post_Body__c.contains('CSM')){
            body += ' '+(String)obj.get('Account_CSM__c');
        }
		post.Body = body;
        feedItemList.add(post);
        System.debug('MS**post '+post);
    }

    public void fieldUpdate(Auto_solved_process_actions__mdt action, sObject obj){
        if(obj.get('Status') != 'Solved' || (obj.get('Status') == 'Solved' && obj.get('Is_auto_closed__c') == true)){
            if(!toUpdate.containsKey(obj.Id)){
           		toUpdate.put(obj.Id,obj);
        	}
        	toUpdate.get(obj.Id).put('Status', action.New_Status_Value_To_Update__c);
            if(action.New_Status_Value_To_Update__c == 'Solved'){
                toUpdate.get(obj.Id).put('Is_auto_closed__c', true);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){
    }
}