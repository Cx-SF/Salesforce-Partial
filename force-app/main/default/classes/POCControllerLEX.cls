public with sharing class POCControllerLEX{

     
     //############################################################
     //  Data Members
     //############################################################
     
     // POC Controller

     
     // Session license instance
     public License__c license { get; set; }
     
     public License__c Numberoflicenses { get; set; }
     
     // Opportunity Id
     public Id oppId;
     
     // Custom setting for default values
     private POC_Default_Values__c licenseDV;
     
     
     //public Opportunity opp { get; set; }
     public String oppDesc {get;set;}
     
     public String refresh { get; set; }
     public String radioButton { get; set; }
     
     
     //############################################################
     //  Constructor
     //############################################################
    
     public POCControllerLEX (ApexPages.StandardController controller){
        refresh = 'false';
        radioButton='';
        // get Op Id
        oppId = ApexPages.currentPage().getParameters().get('Id');
        
        // creale basic license
        license = new License__c(Name = 'VFPLicense',
                                 Opportunity__c = oppId,
                                 Delivered_By__c = 'NotProvided', status__c = 'Not Activated');
        Numberoflicenses = new License__c();
        
        Numberoflicenses.Number_of_Engines__c = 1; 
        
        calcExpDate();            

    }
    
      public POCControllerLEX (){
        refresh = 'false';
        radioButton='';
        // get Op Id
        oppId = ApexPages.currentPage().getParameters().get('Id');
        
        // creale basic license
        license = new License__c(Name = 'VFPLicense',
                                 Opportunity__c = oppId,
                                 Delivered_By__c = 'NotProvided', status__c = 'Not Activated');
        Numberoflicenses = new License__c();
        
        Numberoflicenses.Number_of_Engines__c = 1; 
        
        calcExpDate();            

    }
    
    
    public PageReference DoSave(){
        if(license.Expiration_Date__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Expiration Date: You must enter a value'));
            return null;
        }
        if(Numberoflicenses.Issued_To__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Contact: You must enter a value'));
            return null;
        }
        
        
        
        Integer numlic = Integer.valueof(Numberoflicenses.Number_of_Engines__c);
        //if(numlic != 0){
            try{
                
                Opportunity realOpp = [SELECT Name, POCSendEmail__c,AccountId, Description, License_Counter__c FROM Opportunity WHERE Id = :oppId];
                if(realOpp.License_Counter__c == null){
                    realOpp.License_Counter__c = 0;
                }
                
                license.Account__c = realOpp.AccountId;
                
                if(license.OSA__c == 'Enabled')
                {
                    license.OSA_Trial_Expiration__c = license.Expiration_Date__c;
                }
                if(license.AppSec_Coach__c == 'Enabled')
                {
                    license.AppSec_Coach_Expiration__c = license.Expiration_Date__c;
                }
                
                // 27.1 comment
                if(oppDesc != NULL && oppDesc != '' && oppDesc != '\t' && oppDesc != '\n'){
                    if(realOpp.Description == NULL)
                        realOpp.Description = '';
                    realOpp.Description += ''+'\n' + String.valueof(Date.today()) + ', ' + UserInfo.getFirstName()  + ' ' + UserInfo.getLastName() + ':\n' + oppDesc;
                }
                
                // (11)1-2 //##############################
                license.Name = 'POC: ' + realOpp.Name;
                license.Type__c = 'POC' ; 
                //########### hance, i was changed from i=0 to i=1 #######################
                List<License__c> newlicenses = new List<License__c>();
                for(Integer i = 1 ;i <= numlic; i++){
                    realOpp.License_Counter__c = realOpp.License_Counter__c + 1;
                    License__c templ = license.clone();
                    // (11)2-2 //##############################
                    templ.Name += ' - ' + String.valueOf(realOpp.License_Counter__c);
                    //######################################
                    newlicenses.add(templ);
                }
                insert newlicenses;
                realOpp.POCSendEmail__c = true;
                
                // (10) //################################
                realOpp.Tech_Status__c = 'POC';
                //########################################
                
                update realOpp;
                
                List<OpportunityContactRole> ContactRoles = [SELECT Id FROM OpportunityContactRole WHERE ContactId = :Numberoflicenses.Issued_To__c AND OpportunityId = :oppId];
                if(ContactRoles.isEmpty()){
                    OpportunityContactRole OCR = new OpportunityContactRole(ContactId = Numberoflicenses.Issued_To__c, OpportunityId = oppId);
                    insert OCR;
                }
            }
            catch(Exception e){
                String  errorMsg = e.getMessage();
                errorMsg += '\nStack Trace:' + e.getStackTraceString();
                errorMsg += '\nLine Number:' + e.getLineNumber();
                errorMsg += '\nException Type:' + e.getTypeName();            
                System.debug('errorMsg: ' + errorMsg);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
            }
        //}
        refresh = 'true';
        
        PageReference pageRef = new PageReference('/'+oppId);
        pageRef.setRedirect(true);
        return pageRef; //Returns to the opp page
        //return null;
    }
    
    public PageReference calcExpDate(){
        if(radioButton=='+14'){
            license.Expiration_Date__c = Date.today().addDays(14);
            license.Expiration_Type__c = '+14';
        }    
        else{ 
            if(radioButton=='+30'){
                  license.Expiration_Date__c = Date.today().addDays(30);
                  license.Expiration_Type__c = '+30';
              }
              else{license.Expiration_Type__c = 'Exact date';}
        }       
        return null;
    }
    
    /*
    public PageReference OnCancel(){
        PageReference pageRef = new PageReference('/'+oppId);
        pageRef.setRedirect(true);
        return pageRef; //Returns to the opp page
    }
    */
    public String radioValue {get; set;}
    public PageReference calculateExpDate(){
        
        System.debug(System.Logginglevel.INFO, 'radioButton: ' + radioButton);
        if(radioButton=='+3'){
            license.Expiration_Date__c = Date.today().addDays(3);
            license.Expiration_Type__c = '+3';
        }else if(radioButton=='+7'){
            license.Expiration_Date__c = Date.today().addDays(7);
            license.Expiration_Type__c = '+7';
        }else if(radioButton=='+14'){
            license.Expiration_Date__c = Date.today().addDays(14);
            license.Expiration_Type__c = '+14';
        }else if(radioButton=='+30'){
            license.Expiration_Date__c = Date.today().addDays(30);
            license.Expiration_Type__c = '+30';
        }else{
            license.Expiration_Type__c = 'Exact date';
        }   
        return null;
    }
    
    public PageReference loadDefaultValuesBasic(){
        //licenseDV = POC_Default_Values__c.getInstance('Basic POC DV');
        licenseDV = POC_Default_Values__c.getValues('Basic POC DV'); 
        radioButton = licenseDV.Expiration_Date__c;
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesAdvanced(){
        licenseDV = POC_Default_Values__c.getInstance('Advanced POC DV');
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesSingle(){
        licenseDV = POC_Default_Values__c.getInstance('Single period production DV');
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesMulti(){
        licenseDV = POC_Default_Values__c.getInstance('Multi period production DV');
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValues(){
        try{
        
            // loading the default valuess
            license.Number_of_Engines__c     = licenseDV.Number_of_Engines__c;
            license.Number_of_Admin_users__c = licenseDV.Number_of_Admin_users__c;  
            license.Number_of_Auditors__c    = licenseDV.Number_of_Auditors__c;
            license.Number_of_Scanners__c    = licenseDV.Number_of_Scanners__c;
            license.Number_of_Reviewers__c   = licenseDV.Number_of_Reviewers__c;
            license.Maximum_lines_of_code__c = licenseDV.Maximum_lines_of_code__c;
            license.Projects__c        = licenseDV.Projects__c;
            
            if(licenseDV.Languages__c == 'All'){
                Schema.DescribeFieldResult fieldResult = License__c.Languages__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                license.Languages__c = '';
                for(Schema.PicklistEntry f : ple)
                {
                    license.Languages__c += f.getValue() + ';';
                }
            }
            else
                license.Languages__c = licenseDV.Languages__c;
            //
            radioButton = licenseDV.Expiration_Date__c;
            
            if(radioButton == '+1Y'){
                license.Expiration_Date__c = Date.today().addYears(1);
                radioButton = 'c';
            }
            else
                calcExpDate();
            
            System.debug('radioButton: ' + radioButton);
             
        }
        catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }
        return null;
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('+3','+3'));
        options.add(new SelectOption('+7','+7')); 
        options.add(new SelectOption('+14','+14')); 
        options.add(new SelectOption('+30','+30')); 
        options.add(new SelectOption('c','Other')); 
        return options; 
    }
    
    public List<String> getItems2() {
        List<String> options = new List<String>();
        options.add('+3');
        options.add('+7'); 
        options.add('+14');
        options.add('+30'); 
        options.add('c'); 
        return options; 
    }
    
    public Map<String, String> getItemsAndLabel() {
        Map<String,String> options = new Map<String,String>();
        options.put('+3','+3');
        options.put('+7','+7'); 
        options.put('+14','+14');
        options.put('+30','+30'); 
        options.put('c','Other'); 
        return options; 
    }
    
    
    @isTest (SeeAllData=true) static void Test01(){
        
        Contact con1 = new Contact(LastName='Test', MailingCountry = 'Albania');
        insert con1;
        
        Opportunity opp1 = new Opportunity(Name='Test',StageName ='Demo', CloseDate=system.today());
        insert opp1;
        
        PageReference pageRef = Page.POCControllerLEX;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('Id',opp1.Id);
        
        POCControllerLEX controller = new POCControllerLEX();
        controller.Numberoflicenses.Issued_To__c = con1.Id;
        controller.calcExpDate();
        controller.calculateExpDate();
        controller.loadDefaultValuesBasic();
        controller.loadDefaultValuesAdvanced();
        controller.loadDefaultValuesSingle();
        controller.loadDefaultValuesMulti();
        controller.loadDefaultValues();
        controller.DoSave();
        controller.getItems();
        controller.getItems2();
        controller.getItemsAndLabel();
        //controller.getIsMultiPeriodLicenseItemsitems();
        //controller.dummyisMultiPeriodLicenseItems();
    }
}