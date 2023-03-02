/************************************************************************************** 
Name                : vf_productionLicenses 
Description         : -
Related components  : -

Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1.  Dana                 21/05/2014                Kfir Cohen            [SW-08901] - updated the existing code
2.  Hanit                19/02/2015                Kfir Cohen            [SW-12362] - updated the existing code
****************************************************************************************/
public with sharing class vf_productionLicenses 
{
    public License__c license {get; set;}
    public License__c Numberoflicenses {get; set;}
    private Id oppId;
    private Id quoteId;
    private POC_Default_Values__c licenseDV;
    public String oppDesc {get;set;}
    public String refresh { get; set; }
    public String radioValue {get; set;}
    public List<SelectOption> licenseOption {get; set;}
    public String selectedLicense {get; set;}
    public Integer firstPhase {get; set;}
    public String isMultiPeriodLicenseItem  {get; set;}
    public Boolean error  {get; set;}
    
    public List<SelectOption> getIsMultiPeriodLicenseItemsitems() 
    {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('No','No')); 
        options.add(new SelectOption('Yes','Yes'));         
        return options;  
    }
    
    public void dummyisMultiPeriodLicenseItems()
    {
        system.debug( Logginglevel.WARN ,'isMultiPeriodLicenseItem: ' + isMultiPeriodLicenseItem);
    }
    
    public vf_productionLicenses()
    {
        refresh = 'false';

        firstPhase = 0 ; 
        licenseOption = new List<SelectOption>() ;
        licenseOption.add(new SelectOption('Annual', 'Annual Term')) ;
        licenseOption.add(new SelectOption('1Year ', 'Less than 1-Year ')) ;
        licenseOption.add(new SelectOption('3Year', '3-Year Term')) ; 
        licenseOption.add(new SelectOption('5Year', '5-Year Term')) ; 
        //licenseOption.add(new SelectOption('Term License', 'Multi Term')) ; 
        licenseOption.add(new SelectOption('Perpetual', 'Perpetual')) ;
        licenseOption.add(new SelectOption('Service', 'No License')) ; 
        licenseOption.add(new SelectOption('Volume', 'Volume')) ;
        
        selectedLicense = 'Annual' ; 
        
        oppId = ApexPages.currentPage().getParameters().get('Id');
        
        if (ApexPages.currentPage().getParameters().containsKey('qtId'))
        {
            quoteId = ApexPages.currentPage().getParameters().get('qtId');
        }
        
        error = false ; 
        
        Opportunity opp = [Select Id, isClosed, stageName,Shipping_Contact_Name__c From Opportunity Where ID =:oppId limit 1] ;
        if (opp.IsClosed || (opp.stageName != null && opp.stageName == 'Submitted'))
        {
            error = true ;
        }
        else
        {
            license = new License__c(Opportunity__c = oppId, Name = 'VFPLicense', Delivered_By__c = 'NotProvided', status__c = 'Not Activated');
            Numberoflicenses = new License__c();
            Numberoflicenses.Number_of_Engines__c = 1;
            if(opp.Shipping_Contact_Name__c != null)
                Numberoflicenses.Issued_To__c = opp.Shipping_Contact_Name__c;
        } 
    }

    public PageReference submitService()
    {
        refresh = 'true' ; 
        return null ; 
    }
    
    public PageReference DoNext()
    {
        refresh = 'false';
        if(selectedLicense == null || selectedLicense == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select License Type'));
            return null ; 
        }
        else if (selectedLicense == 'Service')
        {
        }
        else if (selectedLicense == 'Annual')
        {
            license.Expiration_Date__c = system.today().addYears(1);
            license.Expiration_Type__c = 'Exact date' ; 
        }
        else if (selectedLicense == '3Year')
        {
            license.Expiration_Date__c = system.today().addYears(3);
            license.Expiration_Type__c = 'Exact date' ; 
        }
        else if (selectedLicense == '5Year')
        {
            license.Expiration_Date__c = system.today().addYears(5);
            license.Expiration_Type__c = 'Exact date' ; 
        }
        else if (selectedLicense == 'Perpetual')
        {
         //kfir
         //   license.Expiration_Date__c = system.today().addYears(2);
            license.Expiration_Type__c = 'Exact date' ; 
        }

        if(selectedLicense == 'Volume')
            firstPhase = 2 ; 
        else if(selectedLicense == 'Service' )
            firstPhase = 3 ;
        else    
            firstPhase = 1;
        
        return null ; 
    }

    public string getApprovalProcessURL()
    {
        return '/p/process/Submit?retURL=%2F' + oppId + '&id=' + oppId ; 
    }
    
    public PageReference DoSave()
    {
//kfir 29/05/2014
        //if(license.Expiration_Date__c == null)
        //{
          //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Expiration Date: You must enter a value'));
           // return null;
        //}

        if(Numberoflicenses.Issued_To__c == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Contact: You must enter a value'));
            return null;
        }
        
        
        try
        {   
            Integer numlic = Integer.valueof(Numberoflicenses.Number_of_Engines__c);
            
            Opportunity realOpp =  [SELECT Name, POCSendEmail__c,AccountId, Description, License_Counter__c 
                                    FROM Opportunity 
                                    WHERE Id = :oppId limit 1];
            
            if(realOpp.License_Counter__c == null)
            {
                realOpp.License_Counter__c = 0;
            }
                
            license.Account__c = realOpp.AccountId;

            if(oppDesc != NULL && oppDesc != '' && oppDesc != '\t' && oppDesc != '\n')
            {
                if(realOpp.Description == NULL)
                {
                    realOpp.Description = '';
                }
                
                realOpp.Description += ''+'\n' + String.valueof(Date.today()) + ', ' + UserInfo.getFirstName()  + ' ' + UserInfo.getLastName() + ':\n' + oppDesc;
            }
                
            license.Name = selectedLicense + ': ' + realOpp.Name;
            license.Type__c = selectedLicense ; 
            List<License__c> newlicenses = new List<License__c>();
            for(Integer i = 1 ;i <= numlic; i++)
            {
                realOpp.License_Counter__c = realOpp.License_Counter__c + 1;
                License__c templ = license.clone();
                templ.Name += ' - ' + String.valueOf(realOpp.License_Counter__c);
                newlicenses.add(templ);
            }
            
            if (newlicenses != null && !newlicenses.isEmpty())
            {
                insert newlicenses;
            }
            
            
            //realOpp.POCSendEmail__c = true; // in comment for issue - SW-08544
            realOpp.Tech_Status__c = 'POC';
            update realOpp;
                
            List<OpportunityContactRole> ContactRoles = [SELECT Id FROM OpportunityContactRole WHERE ContactId = :Numberoflicenses.Issued_To__c AND OpportunityId = :oppId];
            if(ContactRoles != null && ContactRoles.isEmpty())
            {
                OpportunityContactRole OCR = new OpportunityContactRole(ContactId = Numberoflicenses.Issued_To__c, OpportunityId = oppId);
                insert OCR;
            }
        }
        catch(Exception e)
        {
            String  errorMsg = e.getMessage();
            errorMsg += '\nStack Trace:' + e.getStackTraceString();
            errorMsg += '\nLine Number:' + e.getLineNumber();
            errorMsg += '\nException Type:' + e.getTypeName();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }

        refresh = 'true';
        return null;
    }
    
    public PageReference loadDefaultValuesBasic()
    {
        licenseDV = POC_Default_Values__c.getValues(selectedLicense + '_Basic'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesAdvanced()
    {
        licenseDV = POC_Default_Values__c.getInstance(selectedLicense + '_Advanced'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesCXEntry()
    {
        licenseDV = POC_Default_Values__c.getInstance('CXEntry'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesCXStarter()
    {
        licenseDV = POC_Default_Values__c.getInstance('CXStarter'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesCXAdvanced()
    {
        licenseDV = POC_Default_Values__c.getInstance('CXAdvanced'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesCXComprehensive()
    {
        licenseDV = POC_Default_Values__c.getInstance('CXComprehensive'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesCXSingle()
    {
        licenseDV = POC_Default_Values__c.getInstance('CXSingle'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesCXServer()
    {
        licenseDV = POC_Default_Values__c.getInstance('CXServer'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesScanAllYouCanSingle()
    {
        licenseDV = POC_Default_Values__c.getInstance('ScanAllYouCanSingle'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValuesScanAllYouCanMulti()
    {
        licenseDV = POC_Default_Values__c.getInstance('ScanAllYouCanMulti'); 
        return loadDefaultValues();
    }
    
    public PageReference loadDefaultValues2WeeksScan()
    {
        licenseDV = POC_Default_Values__c.getInstance('2WeeksScan'); 
        return loadDefaultValues();
    }   
    
    public PageReference loadDefaultValues10X2WeekScan()
    {
        licenseDV = POC_Default_Values__c.getInstance('10X2WeekScan'); 
        return loadDefaultValues();
    }  
    
    public PageReference loadDefaultValues()
    {
        try
        {
            license.Number_of_Engines__c     = licenseDV.Number_of_Engines__c;
            license.Number_of_Admin_users__c = licenseDV.Number_of_Admin_users__c;  
            license.Number_of_Auditors__c    = licenseDV.Number_of_Auditors__c;
            license.Number_of_Scanners__c    = licenseDV.Number_of_Scanners__c;
            license.Number_of_Reviewers__c   = licenseDV.Number_of_Reviewers__c;
            license.Maximum_lines_of_code__c = licenseDV.Maximum_lines_of_code__c;
            license.Number_of_Servers__c = licenseDV.Number_of_Servers__c;
            
            if(licenseDV.Languages__c == 'All')
            {
                Schema.DescribeFieldResult fieldResult = License__c.Languages__c.getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                license.Languages__c = '';
                for(Schema.PicklistEntry f : ple)
                {
                    license.Languages__c += f.getValue() + ';';
                }
            }
            else
            {
                license.Languages__c = licenseDV.Languages__c;
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()));
        }
        return null;
    }
}