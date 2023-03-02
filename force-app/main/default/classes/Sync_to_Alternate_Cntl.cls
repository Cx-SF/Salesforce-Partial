public class Sync_to_Alternate_Cntl {
    /*** Controller: ***/
    PUBLIC List<Opportunity> selectcon {get;set;}
    PUBLIC List<Opportunity> allcons {get;set;}
  
    public string OID  {get;set;}
    public SBQQ__Quote__c CurrQ  {get;set;}
    public list <Opportunity> AllOpp  {get;set;}
    public map <id,Opportunity> AllOppMap  {get;set;}
    public Sync_to_Alternate_Cntl (ApexPages.StandardController stdController)
    {
        AllOpp = NEW list <Opportunity>();
        SBQQ__Quote__c CurrQ1 = (SBQQ__Quote__c)stdController.getRecord();
        CurrQ = [select id, SBQQ__Opportunity2__c , SBQQ__Account__c , SBQQ__MasterContract__c   from SBQQ__Quote__c where id =: CurrQ1.id ];
        OID =  CurrQ.SBQQ__Opportunity2__c;
        AllOppMap = new map <id,Opportunity> ();
        id accountQ = CurrQ.SBQQ__Account__c ;
        for (Opportunity OPP : [SELECT  Id, Amount, Name, StageName, CreatedBy.NAME FROM Opportunity where StageName not in('Approved','Cancelled' , 'Closed Lost' , 'Duplicate', 'Closed Won' ,  'Paid ') and type ='Upsell' and AccountId =: accountQ  and id !=: OID order by name ASC]){ 
            AllOpp.add(opp);
            AllOppMap.put(opp.id, opp);
        } 
    }
    
    public pagereference saveIt() {
      
        If (selectcon.size() == 0)
        {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Choose an Opportunity'));
         return null;         
        }
        else{
            
            Opportunity oldopp = [select id  from Opportunity where id =: OID ];
            CurrQ.SBQQ__Opportunity2__c  = selectcon[0].id;
            CurrQ.SBQQ__Primary__c = false;
            Opportunity NewOpp = AllOppMap.get(selectcon[0].id);
            NewOpp.SBQQ__AmendedContract__c = CurrQ.SBQQ__MasterContract__c ;
            NewOpp.SBQQ__PrimaryQuote__c = CurrQ.id;
            UPDATE CurrQ;
            delete oldopp;
            update NewOpp;
            Return new pagereference('/'+ CurrQ.id);
        }  

    }
    

Public List<Opportunity> getAllContacts()

{

    id accountQ = CurrQ.SBQQ__Account__c ;
    
    allcons = [SELECT Id, Amount, Name, StageName, CreatedBy.NAME FROM Opportunity 
                                 where StageName  != 'Approved' and type ='Upsell' and AccountId =: accountQ  and id !=: OID order by name ASC];

    return allcons;

}   

Public void selectcon()

{

    String selcontactid = System.currentPagereference().getParameters().get('conid');

    Opportunity con = [SELECT Id, Amount, Name, StageName, CreatedBy.NAME FROM Opportunity where Id=:selcontactid];

    selectcon =  new List<Opportunity>();

    selectcon.add(con);

}

Public List<Opportunity> getselectedContact()

{

    return selectcon;

}
}