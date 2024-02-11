public class WDCX_CreateQuoteController {
    private ID opptyId = null;
    private ID quoteId = null;
    public SBQQ__Quote__c quoteCU {get;set;}
    public Boolean isError {get;set;}
    public string textDis {get;set;}
    public string textError {get;set;}
    public Opportunity oppCU {get;set;}    
    public WDCx_CreateQuoteController(ApexPages.StandardSetController stdSetController) {
        //get the opportunity id
        textError = null;
        this.opptyId = ApexPages.currentPage().getParameters().get('id');
        isError = false;
        //textDis = 'Only Checkmarx Global Price Book can be used for quoting. \r\n Please click on "Approve" to replace the opportunitys price book to Checkmarx Global Price Book, or Cancel. Please Note: Changing the price book permanently deletes all products from the opportunity. Continue?';
    }
    public PageReference Approve()
    {
        System.debug('Approve  :' + oppCU.Pricebook2Id);
        PageReference pageRef = null;
        delete oppCU.OpportunityLineItems;
        oppCU.Pricebook2Id = CPQ_Settings__c.getInstance().GlobalPriceBookId__c;
        update oppCU;
        System.debug('Approve  :' + oppCU.Pricebook2Id);
        return moveon();
        //return null;
    }
    //Callback invoked when the page is loaded
    //@return the page reference 
    public PageReference createAndRedirect()
    {
        System.debug('createAndRedirect');
        oppCU = [SELECT Id, Probability ,Pricebook2Id ,SBQQ__RenewedContract__c, SBQQ__AmendedContract__c, CX_Distributor_Account__c,Partner_Account__r.CX_Partner_Reseller_Sub_Type__c,  (select id from OpportunityLineItems) FROM Opportunity where id = : opptyId];
        System.debug('yael oppCU.Pricebook2Id ' + oppCU.Pricebook2Id);
         System.debug('yael CPQ_Settings__c.getInstance().GlobalPriceBookId__c ' + CPQ_Settings__c.getInstance().GlobalPriceBookId__c);
      /*  if(oppCU.Pricebook2Id != null && oppCU.Pricebook2Id !=  CPQ_Settings__c.getInstance().GlobalPriceBookId__c )
        {   
            System.debug('return null');
            return null;
        }else*/ 
            List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
            String ProfileName = PROFILE[0].Name;
            if ( ((oppCU.SBQQ__RenewedContract__c != null || oppCU.SBQQ__AmendedContract__c != null) && ProfileName != 'Sales Operations') || Test.isRunningTest()) {
            System.debug('return null');
            isError = true;
            textError = 'New quote can\'t be created from Renewal / Amendment Opportunity. To create additional Upsell / Renewal quotes, please use “Clone With Related” button on any existing quote, or click “create renewal quote” on the renewed contract.';
            ApexPages.getMessages().add(new ApexPages.Message(ApexPages.Severity.Error, 'New quote can\'t be created from Renewal \\ Amendment Opportunity. Please create a new quote from Contract.'));
            return null;
                
        }
        else if (oppCU.Probability == 0 && ProfileName != 'System Administrator')
            {isError = true; textError = 'New quote can\'t be created on Stage Zero opportunity (%0 probability).';
            ApexPages.getMessages().add(new ApexPages.Message(ApexPages.Severity.Error, 'New quote can\'t be created on Stage Zero opportunity (%0 probability).'));
            return null;
            }
        else if (oppCU.CX_Distributor_Account__c == null && oppCU.Partner_Account__r.CX_Partner_Reseller_Sub_Type__c =='Tier 2 Reseller')
            {isError = true; textError = 'Distributor is required when partner is a Tier 2 Reseller.';
            ApexPages.getMessages().add(new ApexPages.Message(ApexPages.Severity.Error, 'Distributor is required when partner is a Tier 2 Reseller.'));
            return null;
            }
       else {System.debug('return moveon'); return moveon();}
        //return null;
    }
    
    public PageReference moveon()
    {
        System.debug('return');
        PageReference pageRef = null;
        SBQQ__Quote__c quoteSO = new SBQQ__Quote__c();
        quoteSO.SBQQ__Opportunity2__c = opptyId;
        
        /*try
        {*/
            insert quoteSO;
            this.quoteId = quoteSO.Id;
            pageRef = Page.SBQQ__sb;
            
            if(quoteId != NULL)
            {
                pageRef.getParameters().put('newid', quoteId);    
            }
            return pageRef;
    }
}

/*
 * 
<apex:page standardController="SBQQ__Quote__c" extensions="WDCX_CreateQuoteController" recordSetVar="Quotes" action="{!createAndRedirect}">
    <apex:form >
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.12.4/jquery.min.js">
        </script>
        <body>
            
            <center>
                  <apex:pageblock >
                <div align="center" draggable="false" >
                    <apex:outputPanel id="err2">
                        <div class="slds-notify slds-notify--toast slds-theme--error" role="alert">
                            <span class="slds-assistive-text"></span>
                            <div class="slds-notify__content" >
                                <h2 class="slds-text-heading--small">Only Checkmarx Global Price Book can be used for quoting. Please click on 'Approve' to replace the opportunity's price book to Checkmarx Global Price Book, or Cancel. 
                                    Please Note: Changing the price book permanently deletes all products from the opportunity. Continue?
                                </h2>
                                <apex:outputText value=""></apex:outputText>
                            </div>
                        </div>
                    </apex:outputPanel>
                </div>  
                
              
                    <apex:pageBlockButtons location="bottom">
                        <!---apex:commandButton value="Create new ticket" action="{!CreateMore}" styleClass="slds-button slds-button--neutral" reRender="Ticket"/--->
                        <apex:commandButton value="Approve" action="{!Approve}" styleClass="slds-button slds-button--neutral" style="background:LightBlue;width:400px;"/>
                        <apex:commandButton value="Cancel" action="{!Cancel}" styleClass="slds-button slds-button--neutral" style="background:LightBlue;width:400px;"/>
                    </apex:pageBlockButtons>
                </apex:pageblock>
                
            </center>
        </body>
    </apex:form>
</apex:page>
*/