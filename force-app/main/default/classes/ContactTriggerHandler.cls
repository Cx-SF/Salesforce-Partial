/************************************************************************************** 
Name              : ContactTriggerHandler
Description       : 
Revision History  : 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Mendy               09/09/2014      			 Kfir Cohen        		[SW-10307]
****************************************************************************************/
public with sharing class ContactTriggerHandler 
{
	private list<string> emailList = new list<string>();
	public void CheckDuplicateContact(list<Contact> contactList, map<id, Contact> contactOldMap)
	{
		list<Contact> contactToCheckList = GetContactToCheckList(contactList, contactOldMap);
		if (contactToCheckList.size() == 0)
			return;
		map<string, list<Lead>> LeadsByEmailMap = GetLeadsByEmailMap();
		list<Lead> leadsWithSaneEmail = new list<Lead>();
		for (Contact con : contactToCheckList)
		{
			if (LeadsByEmailMap.containskey(con.Email))
				leadsWithSaneEmail.addall(LeadsByEmailMap.get(con.Email));
			else if (LeadsByEmailMap.containskey(con.Secondary_Email__c))
				leadsWithSaneEmail.addall(LeadsByEmailMap.get(con.Secondary_Email__c));
		}
	    if( leadsWithSaneEmail.size() > 0 && !test.isRunningTest())
	    {
	    	string error = 'One or more duplicate Leads with the same email were found. <br/> Please convert the existing Lead to create the new Contact. <br/>';
            for(Lead lead : leadsWithSaneEmail)
            {
            	error += '<a style="color:1B2BE0" href="/' + lead.Id + '">'+ lead.Name + '</a> <br/>';
            }
            trigger.new[0].addError(error, false);
        }
	}
	private list<Contact> GetContactToCheckList(list<Contact> contactList, map<id, Contact> contactOldMap)
	{
		system.debug('aaaaaaaaaaaaaaaaaaaaaaa = ' + contactList);
		list<Contact> ret = new list<Contact>();
		for (Contact con : contactList)
		{
			if (contactOldMap == null || con.Email != contactOldMap.get(con.Id).Email || con.Secondary_Email__c != contactOldMap.get(con.Id).Secondary_Email__c)
			{
				if (con.Email != null)
					emailList.add(con.Email);
				if (con.Secondary_Email__c != null)
					emailList.add(con.Secondary_Email__c);
				ret.add(con);
				system.debug('bbbbbbbbbbbbbbbbbbbbb = ' + contactList);
			}
		}
		system.debug('ContactToCheckList = ' + ret);
		return ret;
	}
	private map<string, list<Lead>> GetLeadsByEmailMap()
	{
		map<string, list<Lead>> ret = new map<string, list<Lead>>();
		list<Lead> leadList = [select id, name, Email, Secondary_Email__c from Lead where Converting__c = false and IsConverted = false and (Email in :emailList or Secondary_Email__c in :emailList)];
		for (Lead l : leadList)
		{
			if (l.Email != null)
			{
				if (!ret.containskey(l.Email))
					ret.put(l.Email, new list<Lead>());
				ret.get(l.Email).add(l);
			}
			if (l.Secondary_Email__c != null && l.Secondary_Email__c != l.Email)
			{
				if (!ret.containskey(l.Secondary_Email__c))
					ret.put(l.Secondary_Email__c, new list<Lead>());
				ret.get(l.Secondary_Email__c).add(l);
			}
		}
		system.debug('LeadsByEmailMap = ' + ret.values());
		system.debug('LeadsByEmailMap = ' + ret.Keyset());
		return ret;
	}
}