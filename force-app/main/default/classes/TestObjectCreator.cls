@isTest 
public class TestObjectCreator {
    
    public static Account CreateAccount(){
        Account a = new Account();
        a.Name = 'ACME Test';
        a.ShippingCountry = 'United States';
        a.ShippingState = 'New York';
        a.Developers__c = 1;
        return a;
    }

    public static Opportunity CreateOpportunity(Account a){
        Opportunity o = new Opportunity();
        o.Name = 'ACME Test';
        o.AccountId = a.Id;
        o.StageName = 'New';
        o.CloseDate = Date.today().addDays(1);
        return o;
    }

    public static CSM_Table_Assignment__c CreateCSMTableAssignment(){
        CSM_Table_Assignment__c ta = new CSM_Table_Assignment__c();
        ta.Org_Sub_Region__c = 'EMEA Strategic Accounts';
        return ta;
    }

    public static Knowledge__kav CreateKnowledge(){
        Knowledge__kav art = new Knowledge__kav();
        art.Notify_Users__c = true;
        art.Title = 'Test Article';
        art.UrlName = 'urlName';
        return art;
    }

    public static CX_Knowledge_Subscription_Info__c CreateKnowledgeSubscriptionInfo(Knowledge__kav art){
        CX_Knowledge_Subscription_Info__c ksi = new CX_Knowledge_Subscription_Info__c();
        ksi.Article__c = art.Id;
        ksi.Contact_Name__c = UserInfo.getUserId();
        return ksi;
    }

    public static Batch_Log__c CreateBatchLog(Account a){
        Batch_Log__c bl = new Batch_Log__c();
        bl.Record_ID__c = a.Id;
        bl.Account__c = a.Id;
        bl.Error_Message__c = 'test';
        bl.Class_Name__c = 'test';
        return bl;
    }
    
    public static Case CreateCase (Account a)
    {
        Case c = new Case();
        c.subject = 'Test';
        c.accountid  = a.id;
        return c;
    }
    
    public static FeedItem CreateFI (id parentid)
    {
        FeedItem fi = new FeedItem();
        fi.parentid = parentid;
        fi.body = 'TEST';
        
        return fi;
    }
    
    public static FeedComment CreateFC (id fiid)
    {
        FeedComment fc = new FeedComment();
        fc.feeditemid = fiid;
        fc.CommentBody = 'TEST';
        return fc;
    }
    
    public static Records_Owner_Management__c CreateROM ()
    {
        Records_Owner_Management__c rom = new Records_Owner_Management__c();
        rom.new_owner__c = userinfo.getuserid();
        return rom;
    
    }
}