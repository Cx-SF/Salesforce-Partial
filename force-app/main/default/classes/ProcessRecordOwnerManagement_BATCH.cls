global class ProcessRecordOwnerManagement_BATCH implements Database.Batchable<SObject>,database.stateful {
    
    global ProcessRecordOwnerManagement_BATCH() {}
    global ProcessRecordOwnerManagement_BATCH (id rid){recid = rid;}
    global ProcessRecordOwnerManagement_BATCH (id tempjob, id rid){receivedjobid = tempjob; recid = rid;}
        
  
    public static string jobid = null;
    public static map <id,Opportunity> Opp4Update = new map <id,Opportunity>();
    public static map <id,Account> Acc4Update = new map <id,Account>();
    public static map <id,SBQQ__Quote__c> Quote4Update = new map <id,SBQQ__Quote__c>();
    public static map <id,Contract> Contract4Update = new map <id,Contract>();
    
    public static string failedstatus = 'Failure';
    
    public static string htmllinebreak = '<br/>';
    
    public id recid {get;set;}
    
    public id receivedjobid {get;set;}
    
    public static map <id,Records_Owner_Management__c[]> IdToROM = new map <id,Records_Owner_Management__c[]>();
  
    global Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('iCloudius - ProcessRecordOwnerManagement_BATCH- Start');
        system.debug('TESTING recid is '+recid);
        system.debug('TESTING receivedjobid is '+receivedjobid);
       
        String q = '';
        q += 'SELECT Id,name, account__c,opportunity__c,new_owner__c,new_owner__r.name,new_owner__r.isactive,status__c,opportunity__r.name,account__r.name FROM Records_Owner_Management__c';
        if (!test.isrunningtest()) q+=' WHERE Status__c=\'In Progress\' AND (Account__c!=NULL OR Opportunity__c!=NULL)';
        if (recid!=null) q+=' AND id =: recid';
        if (jobid!=null) q+=' AND Batch_Id__c =:receivedjobid';
        if (Test.isRunningTest()) q += ' LIMIT 1';
        
        System.debug('iCloudius - ProcessRecordOwnerManagement_BATCH- q: ' + q);

        return Database.getQueryLocator(q);
    }


    global void execute(Database.BatchableContext context, List<Records_Owner_Management__c> scope) 
    {
        jobid = context.getJobId();
        
        ProcessROM (scope);
        
        utils.CodeOff = true;
        
        HandleDMLs();
        
        update scope;
        utils.CodeOff = false;
    }
    
    public static map <id,Opportunity> OppMap = new map <Id,Opportunity>();
    
    public static void HandleDMLs ()
    {
        utils.CodeOff = true;
        
        system.debug('TESTING Acc4Update is '+Acc4Update.size());
        if (Acc4Update.size()>0) { HandleDML (Acc4Update); Acc4Update.clear();}
        
        system.debug('TESTING Opp4Update is '+Opp4Update.size());
        if (Opp4Update.size()>0) {HandleDML (Opp4Update); Opp4Update.clear();}
        
        system.debug('TESTING Quote4Update is '+Quote4Update.size());
        if (Quote4Update.size()>0) { HandleDML (Quote4Update); Quote4Update.clear();}
        
        system.debug('TESTING Contract4Update is '+Contract4Update.size());
        if (Contract4Update.size()>0) { HandleDML (Contract4Update); Contract4Update.clear();}
        
        
        utils.CodeOff = false;
    }
    

    
    public static void HandleDML (map <id,sobject> ObjMap)
    {
        Database.SaveResult[] results = Database.update(ObjMap.values(), false);
      
        for(Integer i = 0, size = results.size(); i < size; i++)
        {
            id rid = results[i].getid();
            list <Records_Owner_Management__c> temp = new list <Records_Owner_Management__c>();
            if (IdToROM.containsKey (rid)) temp = IdToRom.get (rid);
            system.debug('TESTING temp is '+temp);
            
            for (Records_Owner_Management__c rom : temp)
            {
                if(results[i].isSuccess() && rom.status__c!=failedstatus) rom.status__c = 'Success';
                
                string errormsg = '';
                boolean HasError = false;
                if(!results[i].isSuccess()){HasError = true; database.error[] errors = results[i].geterrors();    system.debug('TESTING errors is '+errors);  for (database.error err : errors) errormsg+=err.getmessage()+'\n';}
                
                system.debug('TESTING HasError is '+HasError);
                system.debug('TESTING errormsg is '+Errormsg);
                
                if (HasError){rom.status__c = failedstatus; rom.error_message__c = errormsg;}
            } 
            
        }
    }
    
    public static void ProcessROM (list <Records_Owner_Management__c> scope)
    {
        list <id> oppids = new list <id>();
        for (Records_Owner_Management__c rom : scope) if (rom.opportunity__c!=null) oppids.add (rom.opportunity__c);
        
        system.debug('TESTING oppids size is '+oppids.size());
        list <Opportunity> Olist = new list <Opportunity>();
        if (oppids.size()>0) Olist = [select id,stagename,SBQQ__AmendedContract__c,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.active__c,SBQQ__AmendedContract__r.active__c, 
                                      (select id,ownerid from SBQQ__Quotes2__r WHERE SBQQ__Status__c=:'Draft') from Opportunity where id=:oppids];
        if (Olist.size()>0) OppMap.putall (OList);

        for (Records_Owner_Management__c rom : scope) ProcessROM (rom);
    }
    
    public static void ProcessROM (Records_Owner_Management__c rom)
    {
        boolean ShouldUpdate = rom.New_Owner__c!=null && rom.new_owner__r.isactive;
        system.debug ('TESTING ShouldUpdate is '+ShouldUpdate);
        
        if (ShouldUpdate) rom.batch_id__c = jobid;
        
        Account a = null;
        if (rom.account__c!=null) a = new account (id = rom.account__c);
        if (a!=null && ShouldUpdate){a.ownerid = rom.new_owner__c; a.override_validations__c = datetime.now(); Acc4Update.put(a.id,a); list <Records_Owner_Management__c> temp = new list <Records_Owner_Management__c>(); if(IdToROM.containsKey (a.id)) temp = IdToRom.get (a.id); temp.add (rom); IdToRom.put (a.id,temp);}
        
        Opportunity o = null;
        if (rom.opportunity__c!=null) o = new Opportunity (id = rom.opportunity__c);
        if (o!=null && ShouldUpdate){o.ownerid = rom.new_owner__c; o.override_validations__c = datetime.now(); Opp4Update.put(o.id,o); list <Records_Owner_Management__c> temp = new list <Records_Owner_Management__c>(); if(IdToROM.containsKey (o.id)) temp = IdToRom.get (o.id); temp.add (rom); IdToRom.put (o.id,temp);}
        
        Opportunity oData = null;
        if (o!=null && OppMap.containsKey (o.id)) oData = OppMap.get (o.id);
        system.debug('TESTING oData is '+oData);
        if (o!=null && ShouldUpdate && oData!=null && oData.SBQQ__Quotes2__r.size()>0) for (SBQQ__Quote__c q : oData.SBQQ__Quotes2__r){q.ownerid = rom.new_owner__c; Quote4Update.put(q.id,q); list <Records_Owner_Management__c> temp = new list <Records_Owner_Management__c>(); if(IdToROM.containsKey (q.id)) temp = IdToRom.get (q.id); temp.add (rom); IdToRom.put (q.id,temp);}
        
        if (oData!=null && oData.SBQQ__AmendedContract__c!=null && oData.SBQQ__AmendedContract__r.active__c){Contract c = new Contract (id = oData.SBQQ__AmendedContract__c); c.ownerid = rom.new_owner__c; Contract4Update.put (c.id,c);}
        if (oData!=null && oData.SBQQ__RenewedContract__c!=null && oData.SBQQ__RenewedContract__r.active__c){Contract c = new Contract (id = oData.SBQQ__RenewedContract__c); c.ownerid = rom.new_owner__c; Contract4Update.put (c.id,c);}
    }
    
	public static map <id,Messaging.SingleEmailMessage> Emailperuse = new map <id,Messaging.SingleEmailMessage>();
    public static set <id> HasErrors = new set <id>();
    public static set <id> HasSuccess = new set <id>();
    
    global void finish(Database.BatchableContext context) 
    {
        jobid = context.getJobId();
        system.debug('TESTING Finish started. jobid is '+jobid);
        
        string q = 'Select id,name,createdbyid,createdby.isactive,status__c,Error_Message__c,Batch_Id__c,';
        q+='New_Owner__c,new_owner__r.name,Opportunity__c,account__c,Opportunity__r.name,account__r.name,opportunity__r.accountid,opportunity__r.account.name';
        q+=' FROM Records_Owner_Management__c';
        //if (!test.isrunningtest()) q+=' WHERE status__c=\''+failedstatus+'\' AND Batch_Id__c =: Jobid';
        if (!test.isrunningtest()) q+=' WHERE Batch_Id__c =: Jobid';
        
        system.debug('TESTING q is '+q);
        
        if (jobid!=null)
        {
            AsyncApexJob apj = [select id,TotalJobItems,JobItemsProcessed,NumberOfErrors from AsyncApexJob where id=:jobid];
            system.debug('TESTING apj is '+apj);
            
            list <Records_Owner_Management__c> AllROM = database.query (q);
            
            list <Records_Owner_Management__c> FailedRom = new list <Records_Owner_Management__c>();
            list <Records_Owner_Management__c> SuccessROM = new list <Records_Owner_Management__c>();
            for (Records_Owner_Management__c r : AllRom) if (r.status__c==failedstatus) FailedRom.add (r); else SuccessROM.add (r);
            
            if (FailedRom!=null) system.debug('TESTING FailedRom size is '+FailedRom.size()); else system.debug('TESTING Failed rom is '+FailedRom);
            if (SuccessROM!=null) system.debug('TESTING SuccessROM size is '+SuccessROM.size()); else system.debug('TESTING SuccessROM rom is '+SuccessROM);
            
            list <Messaging.SingleEmailMessage> emails = new list <Messaging.SingleEmailMessage>();
          
            
            
            
            
            for (Records_Owner_Management__c rom : FailedRom)
            {
                system.debug('TESTING adding Failed rom to email, rom is '+rom);
                Messaging.SingleEmailMessage em = AddROMToEmail (rom, apj,FailedRom.size(),SuccessRom.size());
            }
            
            for (Records_Owner_Management__c rom : SuccessRom)
            {
                system.debug('TESTING adding rom to email, rom is '+rom);
                Messaging.SingleEmailMessage em = AddROMToEmail (rom, apj,FailedRom.size(),SuccessRom.size());
            }
            
            system.debug('TESTING EmailPerUse is '+EmailPerUse.size());
            if (EmailPerUse.size()>0) for (Messaging.SingleEmailMessage em : EmailPerUse.values()) emails.add (em);
            
            if (!test.isrunningtest() && emails.size()>0) Messaging.SendEmailResult[] emailres = Messaging.sendEmail(emails);
        }
        
    }
    
    public static Messaging.SingleEmailMessage AddROMToEmail (Records_Owner_Management__c rom,AsyncApexJob apj, integer totalfailed, integer totalsuccess)
    {
        system.debug('TESTING AddROMToEmail rom is '+rom);
        boolean IsFailed = rom!=null && rom.status__c!=null && rom.status__c==failedstatus;
        system.debug('TESTING IsFailed is '+IsFailed);
        
        id uid = rom.createdbyid;
        Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();
        if (EmailperUse.containskey(uid)) em = EmailperUse.get (uid); else em = CreateEmailShell(rom,apj,totalfailed,totalsuccess);
        
        string body = em.getplaintextbody();
        string htmlbody = em.gethtmlbody();
        
        string oppname = '';
        id oppid = null;
        string accname = '';
        id accid = null;
        if (rom.opportunity__c!=null){ oppname = rom.opportunity__r.name; oppid = rom.opportunity__c; if (rom.opportunity__r.accountid!=null){accname = rom.opportunity__r.account.name;accid = rom.opportunity__r.accountid;}}
        if (rom.account__c!=null) {accname = rom.account__r.name; accid = rom.account__c;}
        
        system.debug('TESTING oppid is '+oppid);
        system.debug('TESTING accid is '+accid);
        
        string errorstring = 'Failed Transfer records: ';
        string successstring = htmllinebreak+'Successesfully Transferred records: ';
        if (rom!=null && rom.status__c!=null && rom.status__c==failedstatus && !HasErrors.contains (uid)){body+=errorstring+'\n';htmlbody+=errorstring+htmllinebreak;HasErrors.add (uid);}
        
        if ((rom!=null && rom.status__c!=null && rom.status__c==failedstatus) || test.isrunningtest())
        { 
            body+=rom.id+' : '+rom.Error_Message__c+'\n'; 
            htmlbody +=CreateLinkFromRecord (rom.id,rom.name)+' | ';
            if (accid!=null) htmlbody +=CreateLinkFromRecord (accid,accname)+' | ';
            if (oppid!=null) htmlbody +='Opp:'+CreateLinkFromRecord (oppid,oppname)+' | ';
            htmlbody+=rom.error_message__c+htmllinebreak;
    	}
    
        if (rom!=null && rom.status__c!=null && rom.status__c!=failedstatus && !HasSuccess.contains (uid)){body+=successstring+'\n';htmlbody+=successstring+htmllinebreak;HasSuccess.add (uid);}
        
        if (rom!=null && rom.status__c!=null && rom.status__c!=failedstatus)
        { 
            body+=rom.id+'\n'; 
            htmlbody +=CreateLinkFromRecord (rom.id,rom.name)+' | ';
            if (accid!=null) htmlbody +=CreateLinkFromRecord (accid,accname)+' | ';
            if (oppid!=null) htmlbody +='Opp:'+CreateLinkFromRecord (oppid,oppname)+' | ';
            htmlbody+='New Owner: '+rom.New_Owner__r.name;
            htmlbody+=htmllinebreak;
        }
        
        em.setPlainTextBody (body);  
        em.sethtmlbody (htmlbody);
        
        EmailperUse.put (uid,em);
        
        return em;
    }
    
    public static string CreateLinkFromRecord (id rid,string label)
    {
        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
        return '<a href='+baseUrl+'/'+rid+'>'+label+'</a>';
    }
    
    public static messaging.SingleEMailMessage CreateEmailShell (Records_Owner_Management__c rom, AsyncApexJob apj, integer totalerrors, integer totalsuccess)
    {
        Messaging.SingleEmailMessage e = new Messaging.SingleEmailMessage();
        string subject = 'Record Ownership Request – Transfers completed';
      
        string totalrecs = 'Unknown';
        if (apj!=null) totalrecs = string.valueof (apj.TotalJobItems);
      	
        
        string body = 'Batch ref ID: '+apj.id+'\n';
        body+='Total Items: '+(totalerrors+totalsuccess)+'\n';
        body += 'Total Success: '+totalsuccess+'\n';
        body+='Total Failed: '+totalerrors+'\n\n';
        
        string htmlbody = body.replace('\n',htmllinebreak);
        
        e.setsubject (Subject);
        e.setPlainTextBody (body);
        e.sethtmlbody (htmlbody);
        e.setsaveAsActivity  (False);
      
      // if (DefaultOrgWide!=null) e.setOrgWideEmailAddressId(DefaultOrgWide.id);
      
        id recipientid = null;
        if (rom!=null && rom.createdby.isactive) recipientid = rom.createdbyid;
      
        list <string> toAddress = new list <string>();
        if (recipientid!=null) ToAddress.add (recipientid);
        system.debug('TESTING ToAddres is '+ToAddress);
        e.setToAddresses (ToAddress);
      
        return e;
    }
}