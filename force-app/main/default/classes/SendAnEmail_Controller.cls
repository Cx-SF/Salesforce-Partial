/************************************************************************************** 
Name              : SendAnEmail_Controller
Description       : Controller for VF SendAnEmail
Revision History  :-
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Irit                 07/07/2013              Itay Sinvani          [SW-5525]
****************************************************************************************/
public with sharing class SendAnEmail_Controller 
{    
    public List<SelectOption> foldersList {get;set;}
    public List<SelectOption> templatesList {get;set;}    
    public Boolean fail {get;set;}
    public Boolean lClose {get;set;}    
    public Id leadId {get;set;}
    public String selectedTemplate {get;set;}
    public String selectedFolder {get;set;}
    
    public SendAnEmail_Controller(ApexPages.StandardController controller)
    {
        try
        {                        
            //The following line is added to fix a VF bug with AJAX on IE8 and IE9
            Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=8');
            leadId = Apexpages.currentPage().getParameters().get('Id');            
            //If the lead is not specified then  we cannot continue.
            if(leadId == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Technical problem accrued, please send an email.'));
                fail = true;
            }
            else
            {                                    
                foldersList = new List<SelectOption>();
                //Unfiled Public Email Templates folder Id - UserInfo.getOrganizationId()               
                foldersList.add(new SelectOption(UserInfo.getOrganizationId(),'Unfiled Public Email Templates'));                                         
                //My Personal Email Templates folder Id - UserInfo.getUserId()
                Id myPersonalEmailTmpId = UserInfo.getUserId();
                if(selectedFolder ==  null)
                {                        
                    selectedFolder = myPersonalEmailTmpId;
                }  
                foldersList.add(new SelectOption(myPersonalEmailTmpId,'My Personal Email Templates'));              
                for(Folder f : [Select Id, Name From Folder Where Type = 'Email' order by Name asc]) 
                {                         
                    foldersList.add(new SelectOption(f.Id,f.Name));
                }                 
            }
        }
        catch(Exception e)
        {
            ErrorFound(e);              
        }
    }
    
    public List<SelectOption> getTemplates() 
    {        
        templatesList = new List<SelectOption>(); 
        if ( selectedFolder != null ) 
        {
            templatesList.add(new SelectOption('null', ' - Select - '));
            for (EmailTemplate t :[Select Id, Name, Subject, Body, IsActive, FolderId 
                                    From EmailTemplate 
                                    Where IsActive = true
                                    And FolderId =: selectedFolder
                                    ORDER BY Name])
            {                   
                templatesList.add(new SelectOption(t.Id,t.Name));
            }
        }
        return this.templatesList;
    }


    public List<SelectOption> getDirectories() 
    {        
        return this.foldersList;
    }
 
    public PageReference CreateAnEmail()
    {        
        PageReference page=null;
        try
        {            
            List<Lead> leadList = [SELECT Id, Name FROM Lead WHERE Id = :leadId];            
            Boolean hasTemplate = !leadList.isEmpty(); //If no lead was found, then we cannot continue.
            hasTemplate &= String.isNotBlank(selectedTemplate) && selectedTemplate.startsWith('00X'); // Check that the user selected an email template
            if(hasTemplate) 
            {                
                Lead tmpLead = leadList[0];
                lClose = false; 
                page = new PageReference('/_ui/core/email/author/EmailAuthor?retURL=%2F' + leadId + '&rtype=00Q&p2_lkid=' + leadId + '&template_id=' + selectedTemplate + '&close=1');
            }
            else
            {                   
                page = new PageReference('/_ui/core/email/author/EmailAuthor?p2_lkid=' + leadId + '&rtype=00Q&retURL=%2F' + leadId + '&alert=1&close=1');
            }       
            page.setRedirect(true);                
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return page;
    }
    
    public void ErrorFound(Exception e)
    {
        String  errorMsg = e.getMessage();
        errorMsg += '\nStack Trace:' + e.getStackTraceString();
        errorMsg += '\nLine Number:' + e.getLineNumber();
        errorMsg += '\nException Type:' + e.getTypeName();            
        System.debug('errorMsg: ' + errorMsg);
                        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }        
}