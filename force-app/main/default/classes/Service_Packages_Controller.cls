public class Service_Packages_Controller {
    
    public list<productwrapper> recordlist { get; set;}
    public account QAccount { get; set;}
    public SBQQ__Quote__c CurrQuote { get; set;}
    public Decimal subList { get; set;}
    public Decimal subNet { get; set;}
    public Decimal assList { get; set;}
    public Decimal assNet { get; set;}
    public Decimal QlNet { get; set;}
    public Decimal Preferred { get; set;}
    public Decimal Enterprise { get; set;}
    public list<id>  CheckedId { get; set;}
    
    
    public Service_Packages_Controller() {
        id CurrQuoteId = ApexPages.currentPage().getParameters().get('id');
        recordlist = new list<productwrapper> ();
        CurrQuote = [select id, Name  , WDCX_Service_Pack_Lines_ID__c, WDCX_Service_Pack_Approved__c,  SBQQ__Account__c , WDCX_AssetsLastCalculationDate__c  , WDCX_AssetTotalNetPrice__c ,WDCX_AssetTotalListPrice__c
                     ,WDCX_SubscriptionsTotalNetPrice__c , WDCX_SubscriptionsLastCalculationDate__c , WDCX_SubscriptionsTotalListPrice__c
                     ,WDCX_Preferred_Support_Pack_Price__c , WDCX_Enterprise_Support_Pack_Price__c , WDCX_QuoteLineTotalNetPrice__c
                     from SBQQ__Quote__c where id =:CurrQuoteId ];
        CheckedId = new list<id> ();
        System.debug('yael CheckedId ' + CheckedId );
        if(CurrQuote.WDCX_Service_Pack_Lines_ID__c != null)
            CheckedId = (CurrQuote.WDCX_Service_Pack_Lines_ID__c).split(',');
        id currentAccount = CurrQuote.SBQQ__Account__c;
        for(SBQQ__Subscription__c sub : [SELECT Id, SBQQ__Account__c , name ,SBQQ__Product__r.name , SBQQ__Quantity__c ,
                                         SBQQ__ListPrice__c  ,SBQQ__NetPrice__c , SBQQ__ProrateMultiplier__c,
                                         SBQQ__EndDate__c, SBQQ__StartDate__c , SBQQ__ContractNumber__c
                                         FROM SBQQ__Subscription__c where SBQQ__Account__c =: currentAccount and WDCX_IncludedInServiceCharge__c = true])
        {
            recordlist.add(new productwrapper(sub , null , null, (!CurrQuote.WDCX_Service_Pack_Approved__c || (CheckedId.contains(sub.id))))); 
        }
        for(asset ass : [SELECT Id, AccountId  , name ,Product2.name , Quantity  ,
                         SBQQ__ListPrice__c   ,Price ,
                         SBQQ__SubscriptionStartDate__c, SBQQ__SubscriptionEndDate__c 
                         FROM asset where AccountId  =: currentAccount and WDCX_IncludedInServiceCharge__c = true])
        {
            
            recordlist.add(new productwrapper(null , ass , null , (!CurrQuote.WDCX_Service_Pack_Approved__c || (CheckedId.contains(ass.id))))); 
        }
        
        for(SBQQ__QuoteLine__c line : [SELECT Id,SBQQ__ProrateMultiplier__c, SBQQ__ListPrice__c, SBQQ__NetPrice__c, SBQQ__ProductName__c, SBQQ__EffectiveQuantity__c,
                                       SBQQ__NetTotal__c, Name , SBQQ__SubscriptionPricing__c FROM SBQQ__QuoteLine__c 
                                       where SBQQ__EffectiveQuantity__c>0 and SBQQ__Quote__c =: CurrQuoteId and SBQQ__Product__R.WDCX_IncludeForServiceCharge__c = TRUE AND (SBQQ__Quote__R.SBQQ__Primary__c = FALSE 
                                                                                                                                                                             OR (SBQQ__Quote__R.SBQQ__Primary__c = true
                                                                                                                                                                                 AND SBQQ__Quote__R.SBQQ__Opportunity2__r.SBQQ__Contracted__c = false  ) )  ])
        {
            
            recordlist.add(new productwrapper(null , null , line , (!CurrQuote.WDCX_Service_Pack_Approved__c || (CheckedId.contains(line.id))))); 
        }
        
        CactTotals ();
        
    }
    public class productwrapper{
        
        public Boolean selected    { get; set;}
        public string prodName  { get; set;}
        public string Wtype  { get; set;}
        public string WName  { get; set;}
        public string WContract  { get; set;}
        public SBQQ__Subscription__c WrapSubscription  { get; set;}
        public Asset WrapAsset  { get; set;}
        public SBQQ__QuoteLine__c WrapLine  { get; set;}
        public Decimal TotalPrice { get; set;}
        public Decimal WQuantity { get; set;}
        public Decimal WListPrice { get; set;}
        public Decimal WNetPrice { get; set;}
        public Date StartD { get; set;}
        public Date EndD { get; set;}
        public id RecID { get; set;}
        
        public productwrapper(SBQQ__Subscription__c sub , asset ass , SBQQ__QuoteLine__c line ,Boolean IsSelected)
        {
            selected = IsSelected;
            TotalPrice = 0;
            if(sub != null)
            {
                Wtype = 'Subs';
                WrapSubscription = sub;
                WQuantity = sub.SBQQ__Quantity__c;
                prodName = sub.SBQQ__Product__r.name;
                WName = sub.name;
                WContract = sub.SBQQ__ContractNumber__c;
                if(sub.SBQQ__ProrateMultiplier__c != null){
                    if(sub.SBQQ__ListPrice__c !=null)
                    WListPrice = sub.SBQQ__ListPrice__c/sub.SBQQ__ProrateMultiplier__c;
                     if(sub.SBQQ__NetPrice__c !=null)
                    WNetPrice = sub.SBQQ__NetPrice__c/sub.SBQQ__ProrateMultiplier__c;
                }
                StartD = SUB.SBQQ__StartDate__c;
                EndD = sub.SBQQ__EndDate__c;
                RecID = sub.ID;
                if(sub.SBQQ__NetPrice__c != null && sub.SBQQ__Quantity__c !=  null)
                    TotalPrice = ((sub.SBQQ__NetPrice__c/sub.SBQQ__ProrateMultiplier__c) * sub.SBQQ__Quantity__c);
                
            }
            else if(ass != null)
            {
                Wtype = 'Asset';
                WrapAsset = ass;
                if(ass.Quantity != null )
                TotalPrice =((ass.price/2.2)* ass.Quantity);
                WQuantity = ass.Quantity;
                prodName = ass.Product2.name;
                WName = ass.name;
                WListPrice = ass.SBQQ__ListPrice__c;
                WNetPrice = ass.price/2.2;
                StartD = ass.SBQQ__SubscriptionStartDate__c;
                EndD = ass.SBQQ__SubscriptionEndDate__c;
                RecID = ass.ID;
            }
            else if(line != null)
            {
                Wtype = 'QL';
                WrapLine = line;
                WQuantity = line.SBQQ__EffectiveQuantity__c;
                prodName = line.SBQQ__ProductName__c;
                WName = line.name;
                WListPrice = line.SBQQ__ListPrice__c;
                // WNetPrice = line.SBQQ__NetPrice__c/line.SBQQ__ProrateMultiplier__c; //IF(ISBLANK(SBQQ__SubscriptionPricing__c) , line.SBQQ__NetPrice__c/2.2 , line.SBQQ__NetPrice__c/line.SBQQ__ProrateMultiplier__c)
                WNetPrice = line.SBQQ__SubscriptionPricing__c == null? line.SBQQ__NetPrice__c/2.2 :line.SBQQ__NetPrice__c/line.SBQQ__ProrateMultiplier__c;
                RecID = line.ID;
                if(line.SBQQ__NetPrice__c != null && line.SBQQ__EffectiveQuantity__c != null)
                    TotalPrice = WNetPrice *line.SBQQ__EffectiveQuantity__c;
                //   TotalPrice =(line.SBQQ__NetPrice__c/line.SBQQ__ProrateMultiplier__c) *line.SBQQ__EffectiveQuantity__c;
                //  StartD = line.SBQQ__SubscriptionStartDate__c;
                //  EndD = line.SBQQ__SubscriptionEndDate__c;
            }
            
            
        }
        public Decimal AddOrNull2 (Decimal num)
        {
            if(num == null)
                return 0;
            else return num;
        }
    }
    
    public void CactTotals ()
    {
        subList = 0 ;
        subNet  =  0 ;
        assList = 0 ; 
        assNet = 0 ;
        QlNet = 0;
        Preferred = 0 ;
        Enterprise = 0 ;
        for(productwrapper Wprod: recordlist){
            if(Wprod.selected){
                if(Wprod.WrapSubscription != null){
                    subList += AddOrNull(Wprod.WListPrice) *AddOrNull(Wprod.WQuantity) ;
                    subNet += AddOrNull(Wprod.WNetPrice) * AddOrNull(Wprod.WQuantity);}
                if(Wprod.WrapAsset != null){
                    assList += AddOrNull(Wprod.WListPrice) *AddOrNull(Wprod.WQuantity) ;
                    assNet += AddOrNull(Wprod.WNetPrice) * AddOrNull(Wprod.WQuantity);}
                if(Wprod.WrapLine != null){
                    QlNet += AddOrNull(Wprod.WNetPrice) * AddOrNull(Wprod.WQuantity);}
            }
        }
        Preferred = Math.max((subNet + assNet + QlNet) * 0.15 , 15000);
        Enterprise = Math.max((subNet + assNet + QlNet) * 0.20 , 30000);
    }
    public PageReference CancelPage ()
    {//return new PageReference('/' + CurrQuote.id);
        PageReference pageRef = Null;
        pageRef = Page.SBQQ__sb;
        pageRef.getParameters().put('scontrolCaching','1');
        pageRef.getParameters().put('id',CurrQuote.Id);
        return pageRef;
    }
    public PageReference SaveRollUp ()
    {
        CurrQuote.WDCX_Service_Pack_Lines_ID__c = null;
        for(productwrapper Wprod: recordlist){
            if(Wprod.selected){
                if(CurrQuote.WDCX_Service_Pack_Lines_ID__c == null)
                    CurrQuote.WDCX_Service_Pack_Lines_ID__c =   Wprod.RecID;
                else
                    CurrQuote.WDCX_Service_Pack_Lines_ID__c += ',' +Wprod.RecID; 
            }
        }
        CurrQuote.WDCX_SubscriptionsLastCalculationDate__c = DATE.today();
        CurrQuote.WDCX_AssetsLastCalculationDate__c  =  DATE.today();
        CurrQuote.WDCX_AssetTotalNetPrice__c = AssNet;
        CurrQuote.WDCX_AssetTotalListPrice__c = AssList;
        CurrQuote.WDCX_SubscriptionsTotalNetPrice__c = SubNet;
        CurrQuote.WDCX_SubscriptionsTotalListPrice__C = SubList;
        CurrQuote.WDCX_Enterprise_Support_Pack_Price__c  = Enterprise;
        CurrQuote.WDCX_Preferred_Support_Pack_Price__c = Preferred;
        CurrQuote.WDCX_QuoteLineTotalNetPrice__c = QlNet;
        CurrQuote.WDCX_Service_Pack_Approved__c = TRUE;
        update CurrQuote;
        PageReference pageRef = Null;
        pageRef = Page.SBQQ__sb;
        pageRef.getParameters().put('scontrolCaching','1');
        pageRef.getParameters().put('id',CurrQuote.Id);
        return pageRef;
    }
    
    public Decimal AddOrNull (Decimal num)
    {
        if(num == null)
            return 0;
        else return num;
    }
}