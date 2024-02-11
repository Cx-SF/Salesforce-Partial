public class ContactPersonaUpdates_Batch implements Database.Batchable<sObject>,Database.Stateful {
    public Map<Id, Account> accountMap4Check = new Map<Id, Account>();
    public List<Contact> contactList = new List<Contact>();
    public Database.QueryLocator start(Database.BatchableContext BC){
        List<Contact> contactList = [Select id, Accountid from Contact where Contact_Persona_Updated__c = True And AccountId != null And Inactive__c = FALSE ];
        System.debug('Rafa - contactList: ' + contactList);
        Set<Id> accountIdList = new Set<Id>();
        for(contact con : contactList) if(!accountIdList.contains(con.AccountId)) accountIdList.add(con.accountId);

        System.debug('Rafa - accountIdList: ' + accountIdList);
        String query = 'Select id, accountId, CX_Champion__c, CX_Influencer__c, Cx_CISO__c, Cx_Head_of_AppSec__c, Cx_Head_of_Development__c, CX_Solution_Owner__c, CX_Dev_Champion__c, CX_Economic_Buyer__c from contact where accountId in : accountIdList';



        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contact> scope){
        Map<Id, Account> accountMap4Update = new Map<Id, Account>();
		Map<Id, Contact> contactMap4Update = new Map<Id, Contact>();
        for(contact con : scope){
            if(!accountMap4Check.containsKey(con.AccountId)){
                Account acc = new Account();
                acc.id = con.accountId;
                acc.Champion__c = con.CX_Champion__c;
                acc.Influencer__c = con.CX_Influencer__c;
                acc.CISO__c= con.Cx_CISO__c;
                acc.Head_of_AppSec__c= con.Cx_Head_of_AppSec__c;
                acc.Head_of_Development__c= con.Cx_Head_of_Development__c;
                acc.CX_Solution_Owner__c = con.CX_Solution_Owner__c;
                acc.CX_Dev_Champion__c = con.CX_Dev_Champion__c;
                acc.CX_Economic_Buyer__c = con.CX_Economic_Buyer__c;

				/*acc.id = con.accountId;
				acc.Champion_New__c = con.CX_Champion__c;
				acc.Influencer_New__c = con.CX_Influencer__c;
				acc.CISO__c = con.Cx_CISO__c;
				acc.Head_of_AppSec__c = con.Cx_Head_of_AppSec__c;
				acc.Head_of_Development__c = con.Cx_Head_of_Development__c;
				acc.Solution_Owner_New__c = con.CX_Solution_Owner__c;
				acc.Dev_Champion_New__c = con.CX_Dev_Champion__c;
				acc.Economic_Buyer_New__c = con.CX_Economic_Buyer__c;*/

                accountMap4Update.put(con.accountId, acc);
                accountMap4Check.put(con.accountId, acc);
            }else{
                Account acc = accountMap4Check.get(con.AccountId);
                if(con.CX_Champion__c) acc.Champion__c = con.CX_Champion__c;
                if(con.CX_Influencer__c) acc.Influencer__c = con.CX_Influencer__c;
                if(con.Cx_CISO__c) acc.CISO__c= con.Cx_CISO__c;
                if(con.Cx_Head_of_AppSec__c) acc.Head_of_AppSec__c= con.Cx_Head_of_AppSec__c;
                if(con.Cx_Head_of_Development__c) acc.Head_of_Development__c= con.Cx_Head_of_Development__c;
                if(con.CX_Solution_Owner__c) acc.CX_Solution_Owner__c = con.CX_Solution_Owner__c;
                if(con.CX_Dev_Champion__c) acc.CX_Dev_Champion__c = con.CX_Dev_Champion__c;
                if(con.CX_Economic_Buyer__c) acc.CX_Economic_Buyer__c = con.CX_Economic_Buyer__c;

				/*if(con.CX_Champion__c) acc.Champion_New__c = con.CX_Champion__c;
                if(con.CX_Influencer__c) acc.Influencer_New__c = con.CX_Influencer__c;
                if(con.Cx_CISO__c) acc.CISO__c= con.Cx_CISO__c;
                if(con.Cx_Head_of_AppSec__c) acc.Head_of_AppSec__c= con.Cx_Head_of_AppSec__c;
                if(con.Cx_Head_of_Development__c) acc.Head_of_Development__c= con.Cx_Head_of_Development__c;
                if(con.CX_Solution_Owner__c) acc.Solution_Owner_New__c = con.CX_Solution_Owner__c;
                if(con.CX_Dev_Champion__c) acc.Dev_Champion_New__c = con.CX_Dev_Champion__c;
                if(con.CX_Economic_Buyer__c) acc.Economic_Buyer_New__c = con.CX_Economic_Buyer__c;*/


                accountMap4Update.put(con.accountId, acc);
                accountMap4Check.put(con.accountId, acc);
            }

			con.Contact_Persona_Updated__c = false;
			contactMap4Update.put(con.Id, con);
        }

        if(!contactMap4Update.isEmpty()) update contactMap4Update.values();

        System.debug('accountMap4Update.size(): ' + accountMap4Update.size());
		Utils.CodeOff = true;
        if(accountMap4Update.size() > 0) {update accountMap4Update.values(); accountMap4Update.clear();}
		Utils.CodeOff = false;
    }

    public void finish(Database.BatchableContext BC){
        System.debug('Rafa - finish ContactPersonaUpdates_Batch');
    }
}