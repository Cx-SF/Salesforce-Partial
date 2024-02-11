public with sharing class LeadTriggerHandler 
{
	public static Map <Id, Lead> OldMap = new Map <Id, Lead>();
	public static String event;

	public static Map <Id, Opportunity> OppMap = new Map <Id, Opportunity>();

	public static void GenData(List <Lead> LLead){
		Set <Id> setId = new Set <Id>();
		for (Lead l: LLead){
			if (l.ConvertedOpportunityId != null) setId.add(l.ConvertedOpportunityId);
		}

		if (!setId.isEmpty()){
			List <Opportunity> lo = [SELECT Id, StageName FROM Opportunity WHERE Id IN:setId];
			if (lo != null && !lo.isEmpty()) OppMap.putAll(lo);
		}
	}

	public static void blockConversionDuoToOppStage(Lead l){
		l.addError('A deal registration can only be approved and added to an existing opportunity if the opportunity is in stage "stage zero prospecting".');
	}

	public static Boolean blockConversionDuoToOppStageREQ(Lead l){
		Boolean tmp = false, b = false;
		if (event == 'Update' && l.IsConverted && !OldMap.get(l.Id).IsConverted && l.ConvertedOpportunityId != null && l.RecordTypeId == '0123z0000003S8iAAE' ) tmp = true;
		if(tmp && OppMap.containsKey(l.ConvertedOpportunityId) && OppMap.get(l.ConvertedOpportunityId).StageName != 'Requirements Definition') b = true;
		System.debug('iCloudius - blockConversionDuoToOppStageREQ: ' + b);
		return b;
	}

	public static void blockConversionDuoToOppStage(List <Lead> LLead){
		for (Lead l: LLead) if (blockConversionDuoToOppStageREQ(l)) blockConversionDuoToOppStage(l);
	}

	public static void HandleBefore(List <Lead> LLead, Map <Id, Lead> OldTriggerMap, String evt){
		System.debug('iCloudius - LeadTriggerHandler - HandleBefore ' + evt);
		if (OldTriggerMap != null) OldMap = OldTriggerMap;
		if (evt != null) event = evt;
		GenData(LLead);
		blockConversionDuoToOppStage(LLead);
	}

	public static void GenDataAfter(List <Lead> LLead){
	}

	public static void HandleAfter(List <Lead> LLead){
		System.debug('iCloudius - LeadTriggerHandler - HandleBefore ' + event);
		GenDataAfter(LLead);
	}

/*
    public void leadCampaignTeamMemberCreation(List<Lead> leadLst, Map<Id,Lead> newLeadMap, Map<Id,Lead> oldLeadMap)
    {
		map<ID,ID> leadID_To_CustomPrimaryCampaignId = new map<ID,ID>() ;
		map<Id,Id> leadId_OldCampaingId = new Map<Id,Id>();
		List<CampaignMember> oldCampaignMembers = new List<CampaignMember>();
		List<CampaignMember> campaignMembersToDelete = new List<CampaignMember>();
		map<Id,Id> leadId_NewCampaingId = new Map<Id,Id>();
		List<CampaignMember> existingCampaignMembers = new List<CampaignMember>();

		for (Lead lead : leadLst)
		{
			system.debug('11111111111111111111111111111111' + (Trigger.isUpdate && lead.Custom_Primary_Campaign__c != null && lead.Custom_Primary_Campaign__c != oldLeadMap.get(lead.id).Custom_Primary_Campaign__c));
			if ((Trigger.isInsert && lead.Custom_Primary_Campaign__c != null) || 
				(Trigger.isUpdate && ( (lead.Custom_Primary_Campaign__c != null && lead.Custom_Primary_Campaign__c != oldLeadMap.get(lead.id).Custom_Primary_Campaign__c) || (lead.Custom_Primary_Campaign__c == null && oldLeadMap.get(lead.id).Custom_Primary_Campaign__c!=null)  ) ) )

			{
				if(lead.Custom_Primary_Campaign__c != null)
				{
					leadID_To_CustomPrimaryCampaignId.put(lead.Id,lead.Custom_Primary_Campaign__c) ;
				}
				if(Trigger.isUpdate && oldLeadMap.get(lead.id).Custom_Primary_Campaign__c != null)
				{
					leadId_OldCampaingId.put(lead.Id,oldLeadMap.get(lead.id).Custom_Primary_Campaign__c);
				}
				
			}
			
		}
		system.debug('leadID_To_CustomPrimaryCampaignId1' + leadID_To_CustomPrimaryCampaignId);
		
		system.debug('leadId_OldCampaingId1' + leadId_OldCampaingId);
		
		if(leadId_OldCampaingId != null && leadId_OldCampaingId.size() > 0)
		{
			system.debug('leadId_OldCampaingId.keySet()1' + leadId_OldCampaingId.keySet());
			system.debug('leadId_OldCampaingId.values()1' + leadId_OldCampaingId.values());
			
			oldCampaignMembers = [Select Id,LeadId,CampaignId From CampaignMember where LeadId in : leadId_OldCampaingId.keySet() and  CampaignId in : leadId_OldCampaingId.values()];
			system.debug('oldCampaignMembers1' + oldCampaignMembers);
			
			if(oldCampaignMembers != null && oldCampaignMembers.size()>0)
			{
				for (CampaignMember cm : oldCampaignMembers)
				{
					system.debug('cm.LeadId1'  + cm.LeadId);
					system.debug('leadId_OldCampaingId.containsKey(cm.LeadId)1 ' + leadId_OldCampaingId.containsKey(cm.LeadId));
					system.debug('leadId_OldCampaingId.get(cm.LeadId)1 ' + leadId_OldCampaingId.get(cm.LeadId));
					system.debug('cm.CampaignId1' + cm.CampaignId);
					//system.debug('leadId_OldCampaingId.get(cm.LeadId) == cm.CampaignId1 ' + leadId_OldCampaingId.get(cm.LeadId) == cm.CampaignId);
					
					if(leadId_OldCampaingId.containsKey(cm.LeadId))
					{
						Id tmp = leadId_OldCampaingId.get(cm.LeadId);
						if(tmp == cm.CampaignId){
							campaignMembersToDelete.add(cm);
						}
					}
				}
			}
		}
		if(campaignMembersToDelete !=null && campaignMembersToDelete.size()>0)
		{
			system.debug('campaignMembersToDelete1' + campaignMembersToDelete);
			try
			{
				delete campaignMembersToDelete;
			}
			catch(Exception ex)
			{
				system.debug('Error in campaignMembersToDelete');
				system.debug('Exception is ' + ex);
				throw ex;
			}
		}
		
		
		if (leadID_To_CustomPrimaryCampaignId != null && leadID_To_CustomPrimaryCampaignId.size() > 0)
		{
	    	Map<Id,List<Id>> leadId_CampaignIds = new Map<Id,List<Id>>();
	    	existingCampaignMembers = [Select Id,LeadId,CampaignId From CampaignMember where LeadId in : leadID_To_CustomPrimaryCampaignId.keySet() and  CampaignId in : leadID_To_CustomPrimaryCampaignId.values()];
	    	
	    	system.debug('existingCampaignMembers1' + existingCampaignMembers);
	    	if(existingCampaignMembers !=null && existingCampaignMembers.size()>0)
	    	{
	    		for( CampaignMember cm : existingCampaignMembers)
	    		{
	    			if(leadId_CampaignIds.containsKey(cm.LeadId))
	    			{
	    				leadId_CampaignIds.get(cm.LeadId).add(cm.CampaignId);
	    			}
	    			else
	    			{
	    				List<Id> cmIds = new List<Id>{cm.CampaignId};
	    				leadId_CampaignIds.put(cm.LeadId, cmIds);
	    			}
	    		}
	    	}
	    	system.debug('leadId_CampaignIds1 '+ leadId_CampaignIds);
	    	List<CampaignMember> insCMs = new List<CampaignMember>() ;  

	    	map<ID, Lead> leadsCMmap = new map<ID, Lead>([Select l.Id, (Select Id, CampaignId From CampaignMembers) 
														  From Lead l 
														  Where l.Id IN : leadID_To_CustomPrimaryCampaignId.keySet()]) ;
			system.debug('leadsCMmap1' + leadsCMmap);
	    	
	    	for (ID leadID : leadID_To_CustomPrimaryCampaignId.keySet())
	    	{
	    	system.debug('leadID1' + leadID);
	    	system.debug('Trigger.isUpdate = ' + Trigger.isUpdate);
	    	system.debug('leadsCMmap != null = ' + leadsCMmap != null);
	    	system.debug('leadsCMmap.get(leadID).CampaignMembers != null = ' + leadsCMmap.get(leadID).CampaignMembers != null);
	    	system.debug('leadsCMmap.get(leadID).CampaignMembers.size() > 0 = ' + leadsCMmap.get(leadID).CampaignMembers.size());
		    	/*if (!(Trigger.isUpdate && leadsCMmap != null && 
		    		  leadsCMmap.get(leadID).CampaignMembers != null && 
		    		  leadsCMmap.get(leadID).CampaignMembers.size() > 0))*/
		    	// New If changed by Mendy
		    	
		    	//check if already exist: */
		    	/*Boolean exist = false;
		    	system.debug('leadId_CampaignIds.containsKey(leadID)1 ' + leadId_CampaignIds.containsKey(leadID));
		    	
		    	if(leadId_CampaignIds.containsKey(leadID))
		    	{
		    		system.debug('leadId_CampaignIds.get(leadID)1 ' + leadId_CampaignIds.get(leadID));
		    		for(Id cmId : leadId_CampaignIds.get(leadID))
		    		{
		    			if(cmId == leadID_To_CustomPrimaryCampaignId.get(leadID))
		    			{
		    				exist = true;
		    				break;
		    			}
		    		}
		    	}	
		    	 
		    	if (leadsCMmap != null && leadsCMmap.get(leadID).CampaignMembers != null && !exist)
		    	{
	    			insCMs.add(new CampaignMember(LeadId=leadID, campaignId = leadID_To_CustomPrimaryCampaignId.get(leadID))) ;
		    	}
		    	 
	    	}
	    	
	    	
	    	system.debug('insCMs = ' + insCMs);
	    	if (insCMs != null && insCMs.size() > 0)
	    	{
	    		insert insCMs ; 
	    	}
		}
    }*/
    
    /*
    public void leadAutoCampaignAssigment_AfterInsertUpdate(List<Lead> leadLst, Map<Id,Lead> newLeadMap, Map<Id,Lead> oldLeadMap)
    {
    	set<ID> initialLeadsids = new set<ID>() ; 
		for (Lead lead : leadLst)
		{
			if (lead.Automatically_Assign_Campaign__c)
			{
				initialLeadsids.add(lead.Id) ; 
			}
		}
		
		if (initialLeadsids != null && initialLeadsids.size() > 0)
		{
	    	map<ID, Lead> leadsCMmap = new map<ID, Lead>([Select l.Id, (Select Id, CampaignId From CampaignMembers) 
														  From Lead l 
														  Where l.Id IN : initialLeadsids]) ;										  
		  	
	    	// prepare list of leads ids needs to be evaluated after no campaing members been founded
	    	map<ID,Lead> leadsWithoutCampaingsIds_map = new map<ID,Lead>() ; 
			for (Lead lead : leadLst)
			{
				if (leadsCMmap.get(lead.Id) != null)
				{
					if (leadsCMmap.get(lead.Id).CampaignMembers == null || leadsCMmap.get(lead.Id).CampaignMembers.size() == 0)
					{
						leadsWithoutCampaingsIds_map.put(lead.Id, lead) ; 
					}
				}
			}

			if (leadsWithoutCampaingsIds_map != null && leadsWithoutCampaingsIds_map.size() > 0)
			{
		    	// List of variables
		    	List<CampaignMember> insCMs = new List<CampaignMember>() ; 
		    	Integer entryNumber ; 
		    	Lead_To_Campaing_Assigment__c tmpCS ;
		    	Boolean criteriaFound ; 
		    	Map<String, Schema.SObjectField> leadsFields = Schema.SObjectType.Lead.fields.getMap();
		    	
				for (Lead lead : leadsWithoutCampaingsIds_map.values())
				{
					if (leadsCMmap.get(lead.Id) != null)
					{
						if (leadsCMmap.get(lead.Id).CampaignMembers == null || leadsCMmap.get(lead.Id).CampaignMembers.size() == 0)
						{
							criteriaFound = false ;
							entryNumber = 1 ; 
							
							while (!criteriaFound)
							{
								tmpCS = Lead_To_Campaing_Assigment__c.getValues(String.valueOf(entryNumber));
					        	if (tmpCS != null)
					        	{
					        		criteriaFound = evaluateCriteria(newLeadMap.get(lead.Id), tmpCS, leadsFields) ; 
					        		if (criteriaFound)
					        		{
					        			insCMs.add(new CampaignMember(leadId = lead.id, campaignId = tmpCS.Campaign_ID__c)) ; 
					        			break ; 
					        		}	
					        		entryNumber++ ; 
					        	}
					        	else
					        	{
					        		// no more entries
					        		break ; 
					        	}
							}
						}
					}
				}
				
				if (insCMs != null && insCMs.size() > 0)
				{
					insert insCMs ; 
				}
			}
		}
    }

    public Boolean evaluateCriteria(Lead lead, Lead_To_Campaing_Assigment__c tmpCS, Map<String, Schema.SObjectField> leadsFields)
    {
    	String fieldType = getFieldSOAPType(tmpCS.Field_API_Name__c, leadsFields) ; 
    	if (lead.get(tmpCS.Field_API_Name__c) != null)
    	{
	    	String fieldValue = String.valueOf(lead.get(tmpCS.Field_API_Name__c)) ; 
	    	
	    	if (fieldType == 'STRING')
	    	{
	    		if (tmpCS.Operator__c.toUpperCase() == 'EQUALS')
	    		{
	    			return fieldValue.equalsIgnoreCase(tmpCS.Field_API_Value__c) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'NOT-EQUALS')
	    		{
	    			return !(fieldValue.equalsIgnoreCase(tmpCS.Field_API_Value__c)) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'CONTAINS')
	    		{
	    			return fieldValue.toUpperCase().contains(tmpCS.Field_API_Value__c.toUpperCase()) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'NOT-CONTAINS')
	    		{
	    			return !(fieldValue.toUpperCase().contains(tmpCS.Field_API_Value__c.toUpperCase())) ;
	    		}
	    	}
	    	else if (fieldType == 'DOUBLE' || fieldType == 'INTEGER')
	    	{
	    		if (tmpCS.Operator__c.toUpperCase() == 'EQUALS')
	    		{
	    			return Decimal.valueOf(fieldValue) == Decimal.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'NOT-EQUALS')
	    		{
	    			return Decimal.valueOf(fieldValue) != Decimal.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'GREATER')
	    		{
	    			return Decimal.valueOf(fieldValue) > Decimal.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'LESS')
	    		{
	    			return Decimal.valueOf(fieldValue) < Decimal.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'GREATER-EQUALS')
	    		{
	    			return Decimal.valueOf(fieldValue) >= Decimal.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    		else if (tmpCS.Operator__c.toUpperCase() == 'LESS-EQUALS')
	    		{
	    			return Decimal.valueOf(fieldValue) <= Decimal.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    	}
	    	else if (fieldType == 'BOOLEAN')
	    	{
	    		if (tmpCS.Operator__c.toUpperCase() == 'EQUALS')
	    		{
	    			return Boolean.valueOf(fieldValue) == Boolean.valueOf(tmpCS.Field_API_Value__c) ;
	    		}
	    	}
	    	else if (fieldType == 'DATE')
	    	{
	    		List<String> splitDateVals = String.valueOf(tmpCS.Field_API_Value__c).split('-') ;

	    		if (splitDateVals != null && splitDateVals.size() == 3)
	    		{ 
		    		Date valueDate = date.newinstance(Integer.valueOf(splitDateVals[2]), Integer.valueOf(splitDateVals[1]), Integer.valueOf(splitDateVals[0])) ; 

		    		if (tmpCS.Operator__c.toUpperCase() == 'EQUALS')
		    		{
		    			return Date.valueOf(fieldValue) == valueDate ;
		    		}
		    		else if (tmpCS.Operator__c.toUpperCase() == 'NOT-EQUALS')
		    		{
		    			return Date.valueOf(fieldValue) != valueDate ;
		    		}
		    		else if (tmpCS.Operator__c.toUpperCase() == 'GREATER')
		    		{
		    			return Date.valueOf(fieldValue) > valueDate ;
		    		}
		    		else if (tmpCS.Operator__c.toUpperCase() == 'LESS')
		    		{
		    			return Date.valueOf(fieldValue) < valueDate ;
		    		}
		    		else if (tmpCS.Operator__c.toUpperCase() == 'GREATER-EQUALS')
		    		{
		    			return Date.valueOf(fieldValue) >= valueDate ;
		    		}
		    		else if (tmpCS.Operator__c.toUpperCase() == 'LESS-EQUALS')
		    		{
		    			return Date.valueOf(fieldValue) <= valueDate ;
		    		}
	    		}
	    	}
    	}
    	
    	return false ; 
    }
    
    public String getFieldSOAPType(String fieldAPI, Map<String, Schema.SObjectField> leadsFields)
    {
		if (leadsFields.get(fieldAPI) != null)
		{
			Schema.DescribeFieldResult f = leadsFields.get(fieldAPI).getDescribe();
			String typeCapital = String.valueof(f.getSoapType()).toUpperCase() ; 
			
			if (typeCapital == 'STRING'  || 
				typeCapital == 'DOUBLE' || typeCapital == 'INTEGER' || 
				typeCapital == 'BOOLEAN' || 
				typeCapital == 'DATE')
			{
				return typeCapital ; 
			}
			else
			{
				return null ; 
			} 
		}
		else
		{
			return null ;
		} 
    }
    */
    
// ----------------------------------------------------------------------------------------------------------------    
// -------------------------------------------- TEST METHOD -------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------------        
    //Test Method
   private static testMethod void LeadTriggerHandler()
    {
    	ClsObjectCreator cls = new ClsObjectCreator();

		Campaign cm = new Campaign(Name = 'Test Camp', StartDate = Date.today());
		insert cm ; 
		
		Campaign cm2 = new Campaign(Name = 'Test Camp2', StartDate = Date.today());
		insert cm2 ; 

		Lead lead = cls.returnLead('Test01@test.com');
		lead.Custom_Primary_Campaign__c = cm.id ; 
		insert lead ; 
		
		Lead lead1 = cls.returnLead('Test02@test.com');
		insert lead1 ;
		
		//lead1.Custom_Primary_Campaign__c = cm.id ; 
		lead1.Description = 'test';
		update lead1 ; 
		
		//lead1.Custom_Primary_Campaign__c = cm2.Id;
		//update lead1;
		
		//lead.Custom_Primary_Campaign__c = null ;
		//update lead; 
		
		
    }
}