public class GenerateLicense_Controller {
	License__c theLic;
	public Boolean closeWindow {get;set;}
	public String response {get;set;}
	public String HID {get;set;}
	
    public GenerateLicense_Controller(ApexPages.StandardController controller) {
    	closeWindow = false;
		theLic = (License__c) controller.getRecord();
    }
	
	public void SaveHID( ){
		try{
			theLic.HID__c = HID;
			update theLic;
		}catch(Exception e){
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
	}
	
	public void doAction(){
		if(Apexpages.currentPage().getParameters().containsKey('hid')){
			hid = Apexpages.currentPage().getParameters().get('hid');
			Id licId = Apexpages.currentPage().getParameters().get('id');
			Boolean upd = false;
			
			for( License__c l : [SELECT HID__c FROM License__c WHERE Id = :licId LIMIT 1] ){
				if( l.HID__c == null || l.HID__c == ''){
					upd = true;
				}
			}
			
			if( upd ){
				update new License__c(Id = licId, HID__c = hid);
			}
		}
	}
	
	public void Process(){
		if(!closeWindow){
			
			response = LicenseWS.SendPost(theLic.Id, Userinfo.getUserId());
			response = response.replaceAll('\n','\\\\n');
			
			system.debug('response:' + response);
		}
		closeWindow = true;
	}
	
	static testmethod void Test01(){
		
		ClsObjectCreator cls = new ClsObjectCreator();

		Account acc1 = cls.returnAccount('TestGeneratelicCont');
        insert acc1;
        
        Opportunity opp1 = new Opportunity(Name='Test', StageName = 'Demo', CloseDate = system.today());
        insert opp1;
        
        License__c lic1 = new License__c(Name='Test', Account__c=acc1.Id, Opportunity__c=opp1.Id, HID__c = '1', Days_To_Expire__c = 0, Region__c = 'America', Number_of_Engines__c = 1, 
                                        Number_of_Admin_users__c = 1,   Number_of_Auditors__c = 1, Number_of_Scanners__c = 1, Number_of_Reviewers__c = 1, Comments__c = 'Test', 
                                        Maximum_lines_of_code__c = 1, Languages__c = 'Test', Expiration_Type__c = '+14', Expiration_Date__c = system.today(), Delivered_By__c = 'NotProvided');
        insert new List<License__c>{lic1};
		
		ApexPages.StandardController sc = new ApexPages.StandardController(lic1); 
        GenerateLicense_Controller controller = new GenerateLicense_Controller(sc);
		
		controller.Process();
	}
}