/*
Date: 02/02/2023
Developer Name: Refael Dabush
Version : 1.0
Class functionality: Transmits information to LWC "QuotaTransitionProcess" and save the received updates to the relevant Quota_Planning__c's 
*/

// Transmits Quota_Planning__c information to LWC "QuotaTransitionProcess"
public class QuotaTransitionProcessCtrl  {
	@AuraEnabled
	public static Map<String, Object> init(id quotaPlannigId){
		System.debug('quotaPlannigId: ' + quotaPlannigId);
		// get the current Quota_Planning (the on from the page)
		List<Quota_Planning__c> currentQuotaPlanning = [select Id, Name, Active__c, rsm_positionId__c, sub_region__c, Region__c, RSM__c,RSM__r.name, TBH__c, TBH__r.name, Target_Year__c, Q1_NB_Target_ACV__c, Q2_NB_Target_ACV__c, Q3_NB_Target_ACV__c, Q4_NB_Target_ACV__c, Q1_Upsell_Target_ACV__c, Q2_Upsell_Target_ACV__c, Q3_Upsell_Target_ACV__c, Q4_Upsell_Target_ACV__c, Q1_Expected_Renewal_ACV__c, Q2_Expected_Renewal_ACV__c, Q3_Expected_Renewal_ACV__c, Q4_Expected_Renewal_ACV__c, Q1_Renewal_Target_ACV__c, Q2_Renewal_Target_ACV__c, Q3_Renewal_Target_ACV__c, Q4_Renewal_Target_ACV__c, Sales_Planning_Role_del__c, Region_Retention_Factor__c  FROM Quota_Planning__c where id =: quotaPlannigId];

		// get all the Quota Planning thet active and from this Year
		Map<String, Object> resOut = new Map<String, Object>();
		resOut.put('Succses', true);
		String todayYear = String.valueOf(System.today().year());
		List<Quota_Planning__c> quotePlanning = [SELECT Id, Name, Active__c, rsm_positionId__c, sub_region__c, Region__c, RSM__c, RSM__r.name, TBH__c, TBH__r.name, Target_Year__c, Q1_NB_Target_ACV__c, Q2_NB_Target_ACV__c, Q3_NB_Target_ACV__c, Q4_NB_Target_ACV__c, Q1_Upsell_Target_ACV__c, Q2_Upsell_Target_ACV__c, Q3_Upsell_Target_ACV__c, Q4_Upsell_Target_ACV__c, Q1_Expected_Renewal_ACV__c, Q2_Expected_Renewal_ACV__c, Q3_Expected_Renewal_ACV__c, Q4_Expected_Renewal_ACV__c, Q1_Renewal_Target_ACV__c, Q2_Renewal_Target_ACV__c, Q3_Renewal_Target_ACV__c, Q4_Renewal_Target_ACV__c, Sales_Planning_Role_del__c, Region_Retention_Factor__c  FROM Quota_Planning__c where active__c = true and Target_Year__c =: todayYear and id !=: quotaPlannigId];

		Map<String, String> rsmMap = new Map<String, String>();
		Map<String, String> tbhMap = new Map<String, String>();
		Map<String, String> rsmPositionIdMap = new Map<String, String>();

		// Crate three maps for sending to QuotaTransitionProcess to the filter fields

		for(Quota_Planning__c qp : quotePlanning){
			System.debug('qp.RSM__c: ' + qp.RSM__c);
			System.debug('qp.RSM_PositionId__c: ' + qp.RSM_PositionId__c);
			if(qp.RSM__c != null) rsmMap.put(qp.RSM__c, qp.RSM__r.Name);
			if(qp.TBH__c != null) tbhMap.put(qp.TBH__c, qp.TBH__r.Name);
			if(qp.rsm_positionId__c != null) rsmPositionIdMap.put(qp.rsm_positionId__c, qp.rsm_positionId__c);
		}

		if(quotePlanning.isEmpty()) {resOut.put('Succses', false); resOut.put('error', 'There are no active recourds');}
		System.debug('map: ' + tbhMap);
		resOut.put('rsmList', rsmMap);
		resOut.put('tbhList', tbhMap);
		resOut.put('rsmPositionIdList', rsmPositionIdMap);
		resOut.put('quotePlanning', quotePlanning);
		resOut.put('currentQuotaPlanning', currentQuotaPlanning[0]);
		System.debug('Init resOut: ' + JSON.serialize(resOut));
		return resOut;
	}

	@AuraEnabled
	public static Map<String, Object> updateQuotaPlanning(Map<String, Object> quotaMess, Quota_Planning__c quotaSource, Quota_Planning__c quotaTarget){
		System.debug('quotaMess: ' + JSON.serializePretty(quotaMess));
		String sourceId;
		String targetId;
		Map<String, Object> resOut = new Map<String, Object>();
		resOut.put('Succses', true);
		List<Quota_Planning__c> quotaPlanningList = new List<Quota_Planning__c>();
		quotaPlanningList.add(quotaSource);
		quotaPlanningList.add(quotaTarget);
		List<ContentNote> noteListSource = new List<ContentNote>();
		List<ContentNote> noteListTarget = new List<ContentNote>();
		for(String mess : quotaMess.keySet()){
			ContentNote noteSource = new ContentNote();
			ContentNote noteTarget = new ContentNote();
			
			if(mess != 'comment'){
				Map<String, Object> messMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(quotaMess.get(mess)));
				sourceId = String.valueOf(messMap.get('sourceId'));
				targetId = String.valueOf(messMap.get('targetId'));
				String today = String.valueOf(Date.today()).removeEnd(' 00:00:00');
				String textforSource = today + ' ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' transferred ' + messMap.get('moneyPassed') + ' from ' + messMap.get('fieldNameChanged') + ' ' + messMap.get('sourceRecord') + ' to ' + messMap.get('targetRecord') + ' (quota amount was changed from ' + messMap.get('lastSourceAmount') + ' to ' + messMap.get('newSourceAmount')+')\n' + ' Notes: ' + quotaMess.get('comment');
				String textforTarget = today + ' ' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + ' transferred ' + messMap.get('moneyPassed') + ' from ' + messMap.get('fieldNameChanged') + ' ' + messMap.get('sourceRecord') + ' to ' + messMap.get('targetRecord') + ' (quota amount was changed from ' + messMap.get('lastTargetAmount') + ' to ' + messMap.get('newTargetAmount')+')\n' + ' Notes: ' + quotaMess.get('comment');

				noteSource.Title = String.valueOf(messMap.get('title'));
				noteSource.Content = Blob.valueOf(textforSource);
				noteListSource.add(noteSource);

				noteTarget.Title = String.valueOf(messMap.get('title'));
				noteTarget.Content = Blob.valueOf(textforTarget);
				noteListTarget.add(noteTarget);
			}
		}
		System.debug('quotaPlanningList: ' + quotaPlanningList);
		try{
			update quotaPlanningList;
			insert noteListSource;
			insert noteListTarget;
			List<ContentDocumentLink> cdlSourceList = new List<ContentDocumentLink>();
			List<ContentDocumentLink> cdlTargetList = new List<ContentDocumentLink>();
			for(ContentNote conN : noteListSource){
				ContentDocumentLink cdl = new ContentDocumentLink();
				cdl.ContentDocumentId = conN.id;
				cdl.LinkedEntityId = sourceId;
				//cdl.ShareType = 'C';
				//cdl.Visibility = 'AllUsers';
				cdlSourceList.add(cdl);
			}

			for(ContentNote conN : noteListTarget){
				ContentDocumentLink cdl = new ContentDocumentLink();
				cdl.ContentDocumentId = conN.id;
				cdl.LinkedEntityId  = targetId;
				//cdl.ShareType = 'C';
				//cdl.Visibility = 'AllUsers';
				cdlTargetList.add(cdl);
			}
			insert cdlSourceList;
			insert cdlTargetList;
		}catch(DmlException  e){
			resOut.put('Succses', false);
			resOut.put('Error', e.getMessage());
			System.debug('Rafa - DmlException: ' + e.getStackTraceString());
		}
		return resOut;
	}

}