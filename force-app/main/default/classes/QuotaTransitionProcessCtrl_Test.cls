@IsTest
public class QuotaTransitionProcessCtrl_Test  {
	@IsTest
	public static void quotaTraTest1(){
		Profile profileId = [SELECT Id FROM Profile LIMIT 1];

		User rsm = new User();
		rsm.Username = 'test1User@gamil.com';
		rsm.LastName = 'LastTest';
		rsm.Email = 'test1User@gmail.com';
		rsm.Alias = 'userAlia';
		rsm.TimeZoneSidKey = 'Asia/Jerusalem';
		rsm.LocaleSidKey = 'iw_IL';
		rsm.EmailEncodingKey = 'UTF-8';
		rsm.ProfileId = profileId.Id;
		rsm.LanguageLocaleKey = 'en_US';
		rsm.EmployeeNumber = '419';

		insert rsm;

		TBH__c tbh = new TBH__c();
		tbh.name = 'tbhTest';
		insert tbh;
		
		Quota_Planning__c qp = new Quota_Planning__c();
		qp.Name = 'test1';
		qp.RSM__c = rsm.Id;
		qp.Q1_NB_Target_ACV__c = 4000;
		qp.Q2_NB_Target_ACV__c = 5800;
		qp.Q3_NB_Target_ACV__c = 6240;
		qp.Q4_NB_Target_ACV__c = 1000;
		qp.Q1_Upsell_Target_ACV__c = 52000;
		qp.Q2_Upsell_Target_ACV__c = 600;
		qp.Q3_Upsell_Target_ACV__c = 9000;
		qp.Q4_Upsell_Target_ACV__c = 38245;
		qp.sub_region__c = 'APAC ANZ';
		qp.Region__c = 'EMEA';
		insert qp;

		Quota_Planning__c qp2 = new Quota_Planning__c();
		qp2.Name = 'test2';
		qp2.TBH__c = tbh.Id;
		qp2.Q1_NB_Target_ACV__c = 6000;
		qp2.Q2_NB_Target_ACV__c = 8245;
		qp2.Q3_NB_Target_ACV__c = 1859;
		qp2.Q4_NB_Target_ACV__c = 2345;
		qp2.Q1_Upsell_Target_ACV__c = 64023;
		qp2.Q2_Upsell_Target_ACV__c = 985;
		qp2.Q3_Upsell_Target_ACV__c = 1054;
		qp2.Q4_Upsell_Target_ACV__c = 7856;
		qp2.sub_region__c = 'APAC ANZ';
		qp2.Region__c = 'EMEA';
		insert qp2;

		Map<String, Object> quotaMess = new Map<String, Object>();
		Map<String, Object> quotaObj = new Map<String, Object>();
		quotaObj.put('targetId','a6f25000000K2EJAA0');
		quotaObj.put('sourceId','a6f25000000K2BPAA0');
		quotaObj.put('lastTargetAmount',0);
		quotaObj.put('lastSourceAmount',4248);
		quotaObj.put('targetRecord','Marcia Keren  - 2023 - P0099');
		quotaObj.put('sourceRecord','chen test1  - 2023 - TEST 213');
		quotaObj.put('fieldNameChanged','Q1 NB');
		quotaObj.put('newSourceAmount',4148);
		quotaObj.put('newTargetAmount',100);
		quotaObj.put('moneyPassed',100);
		quotaObj.put('title','Quota Transfer');
		
		quotaMess.put('comment','rteyt');
		quotaMess.put('Q1NB', quotaObj);

		QuotaTransitionProcessCtrl.init(qp.Id);
		QuotaTransitionProcessCtrl.updateQuotaPlanning(quotaMess, qp, qp2);

	}
}