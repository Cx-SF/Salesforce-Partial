public class LeadConvertHandover_Controller {

    public Lead theLead {get;set;}
    
    public LeadConvertHandover_Controller(ApexPages.StandardController controller) {
        theLead = (Lead) controller.getRecord();
    }
    
    public PageReference LeadConvertHandover_Action(){
        theLead.CancelWorkflowForConversion__c = true;
        update theLead;
        return new PageReference('/lead/leadconvert.jsp?nooverride=1&retURL='+theLead.Id+'&id='+theLead.Id);
    }
}