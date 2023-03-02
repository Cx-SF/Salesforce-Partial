public without sharing class Ctrl_DownloadCenter  {
    @AuraEnabled
    public static Map <String, Object> getInitialData(Id objId){
        Map <String, Object> mso = new Map <String, Object>();
        mso.put('availableProducts', getProducts());
		mso.put('running_user', getRunningUser());
		mso.put('available_accounts', getAvailableAccounts());
        
        System.debug('iCloudius - Initial Data:\n' + JSON.serializePretty(mso));
        return mso;
    }

	@AuraEnabled
    public static Map <String, Object> getVersionsAndPlugIns(String product){
        Map <String, Object> mso = new Map <String, Object>();
        mso.put('versions', getProductVersions(product));
        mso.put('plugins', getPlugins(product));
		mso.put('services', getServices(product));

        System.debug('iCloudius - Initial Data:\n' + JSON.serializePretty(mso));
        return mso;
    }

	@AuraEnabled
	public static List <Map <String, String>> getAvailableAccounts(){
		List <Map <String, String>> res = new List <Map <String, String>>();
		List <Map <String, String>> temp = new List <Map <String, String>>();
		List <String> ls = new List <String>();
		Set <String> ss = new Set <String>();
		Integer grace = 0;
		List <Grace_Period_days__mdt> lmd = [SELECT Id, Number_Of_Days__c FROM Grace_Period_days__mdt WHERE Number_Of_Days__c != null];
		if (lmd != null && !lmd.isEmpty()) grace = (Integer)lmd[0].Number_Of_Days__c;
		System.debug('iCloudius - Grace period: ' + grace);
		Date ReqendDate = Date.today().addDays(grace*-1);
		List <User> lu = [SELECT Id, Name, AccountId, Account.Name FROM User WHERE Id =:UserInfo.getUserId()];
		if (lu != null && !lu.isEmpty() && lu[0].AccountId != null){
			List <Contract> lc = [SELECT Id, AccountId, Account.Name FROM Contract WHERE Partner_Account__c = :lu[0].AccountId AND EndDate >= :ReqendDate ORDER BY Account.Name];
			if (lc != null && !lc.isEmpty()) for (Contract c: lc) if (!ss.contains(c.Account.Name)){ res.add(new Map <String, String> { 'label' => c.Account.Name, 'value' => c.AccountId }); ss.add(c.Account.Name); }
			res.add(new Map <String, String> { 'label' => lu[0].Account.Name, 'value' => lu[0].AccountId });
		}

		System.debug('iCloudius - Available Accounts found:\n' + JSON.serializePretty(res));
		return res;
	}

	public static User getRunningUser(){
		User u = null;
		List <User> lu = [SELECT Id, Name, UserType, ProfileId, Profile.Name, AccountId, Account.Type, Account.CX_Block_Account_from_Download_Center__c FROM User WHERE Id =:UserInfo.getUserId()];
		if (lu != null && !lu.isEmpty()) u = lu[0];
		System.debug('iCloudius - Running User:\n' + JSON.serializePretty(u));
		return u;
	}

	public static Map <String, Object> getDLSetting(){
		Map <String, Object> mso = new Map <String, Object>();
		Map <String, Download_Center__c> csmap = Download_Center__c.getall();
		String endPoint = Test.isRunningTest() ? 'test' : csmap.get('Setting').Base_endpoint__c;
		String apiKey = Test.isRunningTest() ? 'test' : csmap.get('Setting').API_Key__c;
		mso.put('endpoint', endPoint);
		mso.put('key', apiKey);
		return mso;
	}

    public static List <Product_Version__c> getProductVersions(String product){
        List <Product_Version__c> lpv = [SELECT Active__c, Content_Pack__c, Download_URL__c, Hotfix_URL__c, Id, Last_Updated_Date__c, Latest_Version__c, Version_Release_Notes__c, 
                                                Linux_Engine__c, Name, Product__c, Version_Number__c, Version_Description__c, SHA256__c, 
												Hotfix_Number__c, Hotfix_Release_Notes__c, Hotfix_SHA256__c, Hotfix_Latest_updated_date__c, Hotfix_Description__c, 
												Content_Pack_Number__c, Content_Pack_Release_Notes__c, Content_Pack_SHA256__c, Content_Pack_Latest_updated_date__c, Content_Pack_Description__c, 
												Linux_Engine_Number__c, Linux_Engine_Release_Notes__c, Linux_Engine_SHA256__c, Linux_Engine_Latest_updated_date__c, Linux_Engine_Description__c, 
												General_Notes__c, Version_Linux__c, Version_Linux_Release_Notes__c, Version_Linux_SHA256__c, Version_Linux_Latest_updated_date__c, 
												Version_Linux_Number__c, Version_Linux_Description__c, Product_Name_Text__c, Engine_Pack__c, Engine_Pack_Number__c, Engine_Pack_Release_Notes__c, 
												Engine_Pack_SHA256__c, Engine_Pack_Latest_updated_date__c, Engine_Pack_Description__c, Order__c 
                                         FROM Product_Version__c WHERE Product__c = :product AND Active__c = true ORDER BY Order__c DESC nulls last LIMIT 3];
        System.debug('iCloudius - Found product versions:\n' + JSON.serializePretty(lpv));
        return lpv;
    }

    public static List <Plug_In__c> getPlugins(String product){
        List <Plug_In__c> lp = [SELECT Active__c, Download_URL__c, Global__c, Id, Name, Plug_In_Version__c, Product__c, Release_Notes__c, Description__c, Plugin_Latest_updated_date__c 
                                        FROM Plug_In__c WHERE (Product__c = :product OR Global__c = true) AND Active__c = true ORDER BY Order__c];
        System.debug('iCloudius - Found plugins:\n' + JSON.serializePretty(lp));
        return lp;
    }

	public static List <Service__c> getServices(String product){
        List <Service__c> ls = [SELECT Active__c, Download_URL__c, Id, Name, Service_Version__c, Product__c, Release_Notes__c, Description__c, Service_Latest_Updated_Date__c 
                                        FROM Service__c WHERE Product__c = :product AND Active__c = true ORDER BY Order__c];
        System.debug('iCloudius - Found services:\n' + JSON.serializePretty(ls));
        return ls;
    }

    public static String getProducts(){
		List <ProductWrap> lpw = new List <ProductWrap>();
		List <ContentDocumentLink> lcd = null;
		List <ContentVersion> lc = null;
		Map <Id, Id> productId2cvId = new Map <Id, Id>();
		Set <Id> setId = new Set <Id>();
		List <Download_Center_Product__c> lp = [SELECT Id, Product__c, Description__c FROM Download_Center_Product__c WHERE IsActive__c = true ORDER BY Order__c];
		System.debug('iCloudius - Download Center Products found:\n' + JSON.serializePretty(lp));

		if (lp != null && !lp.isEmpty()) for (Download_Center_Product__c p: lp) setId.add(p.Id);

		if(!setId.isEmpty()) lcd = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :setId];
		System.debug('iCloudius - Found related files:\n' + JSON.serializePretty(lcd));

		setId.clear();
		if (lcd != null && !lcd.isEmpty()) for (ContentDocumentLink c: lcd) { setId.add(c.ContentDocumentId); productId2cvId.put(c.LinkedEntityId, c.ContentDocumentId); }

		if(!setId.isEmpty()) lc = [SELECT ContentDocumentId, Id, Title FROM ContentVersion WHERE ContentDocumentId IN :setId AND IsLatest = true];
		System.debug('iCloudius - Found Content version:\n' + JSON.serializePretty(lc));
		
		if (lc != null && !lc.isEmpty()) for (ContentVersion cv: lc){
			for (Id pId: productId2cvId.keySet()){
				if (cv.ContentDocumentId == productId2cvId.get(pId)){
					productId2cvId.put(pId, cv.Id);
					break;
				}
			}
		}
		System.debug('iCloudius - productId2cvId:\n' + JSON.serializePretty(productId2cvId));

		if (lp != null && !lp.isEmpty()){
			for (Download_Center_Product__c p: lp){
				ProductWrap pw = new ProductWrap(p.Id, p.Product__c, p.Description__c);
				if (productId2cvId.containsKey(p.Id) && productId2cvId.get(p.Id) != null) pw.imgId = productId2cvId.get(p.Id);
				System.debug('iCLoudius - Adding product:\n' + JSON.serializePretty(pw));
				lpw.add(pw);
			}
		}

		return JSON.serialize(lpw);
    }

	@AuraEnabled
	public static String getDLURL(Map <String, Object> dlObj){
		String fileName = (String)dlObj.get('file_name');
		String res = '';
		Map <String, Object> mso = getDLSetting();
		String endPoint = (String)mso.get('endpoint');
		String apiKey = (String)mso.get('key');
		endPoint+= fileName;

		System.debug('iCloudius - Final EP: ' + endPoint);

		HttpRequest req = new HttpRequest();
		HttpResponse resp = new HttpResponse();
		Http h = new Http();
		req.setEndpoint(endPoint);
		req.setHeader('x-api-key', apiKey);
		req.setMethod('GET');
		if (!Test.isRunningTest()) resp = h.send(req);
		if (!Test.isRunningTest()) res = resp.getBody();

		List <User> lu = [SELECT Id, Name, ContactId, AccountId, Account.CSM__c, Account.Technical_Account_Manager__c FROM User WHERE Id = :UserInfo.getUserId()];

		Download__c dl = new Download__c();
		if (lu[0].AccountId != null) dl.Account__c = lu[0].AccountId;
		if (lu[0].ContactId != null) dl.Contact__c = lu[0].ContactId;
		if (lu[0].AccountId != null && lu[0].Account.CSM__c != null) dl.CSM__c = lu[0].Account.CSM__c;
		if (lu[0].AccountId != null && lu[0].Account.Technical_Account_Manager__c != null) dl.TAM__c = lu[0].Account.Technical_Account_Manager__c;
		dl.Download_Date_Time__c = Datetime.now();
		dl.Product__c = (String)dlObj.get('prod');
		dl.Component__c = (String)dlObj.get('cmp');
		if (dlObj.containsKey('ver')) dl.Version_Number__c = (String)dlObj.get('ver');
		if (dlObj.containsKey('hotfix_number')) dl.Hotfix_Number__c = (String)dlObj.get('hotfix_number');
		if (dlObj.containsKey('linux_engine_number')) dl.Linux_Engine_Number__c = (String)dlObj.get('linux_engine_number');
		if (dlObj.containsKey('content_pack_number')) dl.Content_Pack_Number__c = (String)dlObj.get('content_pack_number');
		if (dlObj.containsKey('plugin_ver')) dl.PlugIn_Version__c = (String)dlObj.get('plugin_ver');
		if (dlObj.containsKey('plugin_name')) dl.Plugin_Name__c = (String)dlObj.get('plugin_name');
		if (dlObj.containsKey('enginepack_number')) dl.Engine_Pack_Number__c = (String)dlObj.get('enginepack_number');
		if (dlObj.containsKey('selected_account') && lu[0].AccountId != null && (Id)dlObj.get('selected_account') != lu[0].AccountId) dl.CX_End_Customer__c = (Id)dlObj.get('selected_account');
		if (dlObj.containsKey('service_ver')) dl.Service_Version__c = (String)dlObj.get('service_ver');
		if (dlObj.containsKey('service_name')) dl.Service_Name__c = (String)dlObj.get('service_name');
		
		if (resp.getStatusCode() != 200){
			dl.Status__c = 'Error';
			dl.Error_Details__c = res.left(32000);
		} else {
			dl.Status__c = 'Ok';
		}
		
		insert dl;
		System.debug('iCloudius - Download Obj:\n' + JSON.serializePretty(dl));

		System.debug('iCloudius - Download URL: ' + res);
		return res;
	}

	public class ProductWrap {
		public Id pId { get; set; }
		public String pName { get; set; }
		public String pDesc { get; set; }
		public String imgId { get; set { imgId = value; imgURL = '/sfc/servlet.shepherd/version/download/' + value; } }
		public String imgURL { get; set; }

		public ProductWrap (){}
		public ProductWrap (Id pId, String pName, String pDesc){
			this.pId = pId;
			this.pName = pName;
			this.pDesc = pDesc;
		}
	}
}