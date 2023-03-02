/************************************************************************************** 
Name              : NewOpp
Description       : Controller for VF New Opportunity
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Irit                 29/07/2013              Itay Sinvani                [SW-5728]
****************************************************************************************/

public with sharing class NewOpp 
{
    public Boolean bBack{get;set;}  
    public Contact con {get;set;}
    
    public NewOpp(ApexPages.StandardController controller) 
    {
        try{
        
            //The following line is added to fix a VF bug with AJAX on IE8 and IE9
            Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=8');
        
            String conId = Apexpages.currentPage().getParameters().get('conid');
            //If the contact is no specified then  we cannot continue.
            if(conId=='' || conId ==null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Opportunities can only be created from a contact record or upon lead conversion.'));
                bBack = true;                
            }
            else
            {            
                List<Contact> conList = [SELECT Id,Name, AccountId FROM Contact WHERE Id = :conId];
                //If no contact was found, then we cannot continue.
                if(!conList.isEmpty())
                {
                    con = conList[0];
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No Contacts found with Id: ' + conId));
                    bBack = true;
                }
            }
        }catch(Exception e)
        {
            ErrorFound(e);
        }

    }
    
    public void ErrorFound(Exception e){
        String  errorMsg = e.getMessage();
        errorMsg += '\nStack Trace:' + e.getStackTraceString();
        errorMsg += '\nLine Number:' + e.getLineNumber();
        errorMsg += '\nException Type:' + e.getTypeName();            
        System.debug('errorMsg: ' + errorMsg);
                        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }
}