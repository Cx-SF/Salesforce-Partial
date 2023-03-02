/************************************************************************************** 
Name              : ZendeskTicketTriggersHendler
Description       : Handler to deal with all the triggers on Zendesk__Zendesk_Ticket__c object
Revision History  : -
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Dana Furman               02/06/2014          Kfir                   [SW-09176]
****************************************************************************************/
public with sharing class ZendeskTicketTriggersHendler {
    
    public ZendeskTicketTriggersHendler() {}

    /*public void RelatedZendeskTicketsToOrganizations(List<Zendesk__Zendesk_Ticket__c> ZendeskTicketLst, Map<Id,Zendesk__Zendesk_Ticket__c> newZendeskTicketsMap, Map<Id,Zendesk__Zendesk_Ticket__c> oldZendeskTicketsMap)
    {

        List<Zendesk__Zendesk_Ticket__c> ZendeskTicketLst2Update = new List<Zendesk__Zendesk_Ticket__c>();
        List<Zendesk__Zendesk_Ticket__c> ZendeskTicketLst2Email = new List<Zendesk__Zendesk_Ticket__c>();
        map<Zendesk__Zendesk_Ticket__c , id> ContactsInZendeskTicket = new map<Zendesk__Zendesk_Ticket__c , id>();
        
        for(Zendesk__Zendesk_Ticket__c zt : ZendeskTicketLst)
        {
            system.debug('zt.Zendesk__Requester__c: ' + zt.Zendesk__Requester__c);
            if(zt.Zendesk__Requester__c != null)
                ContactsInZendeskTicket.put(zt , zt.Zendesk__Requester__c);
        }
        
        List<contact> contactsList = [select id, accountID from contact where id in :ContactsInZendeskTicket.values()];
        MAP<id,id> conatctAndAccountsMap = new MAP<id,id>();
        
        for(Contact con : contactsList )
        {
            system.debug('con.accountId: ' + con.accountId);
            conatctAndAccountsMap.put(con.id, con.accountId);        
        }
        
          
        for(Zendesk__Zendesk_Ticket__c zt : ZendeskTicketLst)
        {
            system.debug('zt: ' + zt);
            system.debug('zt.Zendesk__Requester__r.AccountId: ' + conatctAndAccountsMap.get(zt.Zendesk__Requester__c));
            
            if (zt.Zendesk__Organization__c == null)
            {
                system.debug('zt.Zendesk__Organization__c: ' + zt.Zendesk__Organization__c);
                if(zt.Zendesk__Requester__c != null)
                {
                    system.debug('zt.Zendesk__Requester__c: ' + zt.Zendesk__Requester__c);
                    if(conatctAndAccountsMap.get(zt.Zendesk__Requester__c) != null )
                        {         
                            zt.Zendesk__Organization__c  = conatctAndAccountsMap.get(zt.Zendesk__Requester__c);
                        }
                    else
                        ZendeskTicketLst2Email.add(zt); 
                } 
            }   
        }

            
        if(!ZendeskTicketLst2Email.isempty())
        {
            String emailDomain ; 
            map<Zendesk__Zendesk_Ticket__c, String> ZendeskTicketToemailsDomains = new map<Zendesk__Zendesk_Ticket__c, String>() ; 
            for(Zendesk__Zendesk_Ticket__c zt1 : ZendeskTicketLst2Email)
            {
                system.debug('zt1.Zendesk_Requester_email__c: ' + zt1.Zendesk_Requester_email__c);
                if (zt1.Zendesk_Requester_email__c != null && !String.isBlank(zt1.Zendesk_Requester_email__c))
                {
                    emailDomain = getDomain(zt1.Zendesk_Requester_email__c).toUpperCase() ; 
                    if (emailDomain != null)
                    {
                        system.debug('The email Domain: ' + emailDomain);
                        ZendeskTicketToemailsDomains.put(zt1, emailDomain) ; 
                    }
                }   
            }
            
           if(ZendeskTicketToemailsDomains.size() > 0) 
            {
                //TO DO - 1. change to domain and not email.   2. add domain to contact
                List<Contact> contacts = [SELECT id, Domain__c FROM Contact WHERE Domain__c IN : ZendeskTicketToemailsDomains.values() Order By CreatedDate];
                map<String , Contact> contact2Domain  = new map<String , Contact>();
                
                for(Contact con : contacts)
                { 
                    if(!contact2Domain.containskey(con.Domain__c)) //to have contact for each domain
                        contact2Domain.put(con.Domain__c , con);                    
                }
                    
                for(Zendesk__Zendesk_Ticket__c zt2 : ZendeskTicketToemailsDomains.keyset())
                {
                    system.debug('ZendeskTicketToemailsDomains.get(zt2): ' + ZendeskTicketToemailsDomains.get(zt2));
                    if(contact2Domain.containsKey(ZendeskTicketToemailsDomains.get(zt2)))
                        {
                             zt2.Zendesk__Organization__c  = contact2Domain.get(ZendeskTicketToemailsDomains.get(zt2)).accountId;
                         }
                }
            }  
        }
    }
    
    
    /**************************************************************************************
    Description       : Helper method to split the domain
    ***************************************************************************************/
    /*public String getDomain(String emailAdd)
    {
        try
        {
            if (emailAdd.indexOf('@') > 0)
            {
                String StartFromAtSign = emailAdd.substring(emailAdd.indexOf('@') + 1, emailAdd.length() ) ;
                /*
                if (StartFromAtSign.lastIndexOfIgnoreCase('.') > 0)
                {
                    system.debug(StartFromAtSign.substring(0,StartFromAtSign.lastIndexOfIgnoreCase('.')));
                    return StartFromAtSign.substring(0,StartFromAtSign.lastIndexOfIgnoreCase('.')) ; 
                } 
                */
                /*if(StartFromAtSign != null)
                    return StartFromAtSign;
            }
            return null ; 
        }
        catch(Exception ex)
        {
            return null ; 
        } 

    }*/

}