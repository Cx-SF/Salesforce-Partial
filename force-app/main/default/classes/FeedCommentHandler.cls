public class FeedCommentHandler 
{
    
    public static map <id,FeedComment> OldMap = new map <id,FeedComment>();
    public static string event = null;
    
    public static map <id,Case> CaseMap = new map <Id,Case>();
    
    public static map <id,Case> Case4Update = new map <Id,Case>();
    
    public static void GenData (list <FeedComment> FCList)
    {
        list <id> idlist = new list <id>();
        
        for (FeedComment fc : FCList) if (fc.parentid!=null) idlist.add (fc.parentid);
        
        
        list <Case> CList = [select id,recordtypeid,recordtype.developername,Assigned_To__c from Case where id=:idlist];
        if (CList.size()>0) CaseMap.putall (CList);
    }
    
    public static void HandleBefore (list <FeedComment> FCList, map <id,FeedComment> oldtriggermap, string evnt)
    {
        if (oldtriggermap!=null) oldmap = oldtriggermap;
        if (evnt!=null) event = evnt;
        
        GenData (FCList);
    }
    
    public static boolean UpdateCaseStatusREQ (FeedComment fc)
    {
        boolean b = false;
        if (event=='Insert' && fc.parentid!=null && string.valueof(fc.parentid).startswith('500')) b=true;
        if (event=='Insert') b=true;
        system.debug('TESTING UpdateCaseStatusREQ res is '+b);
        return b;
    }
    
    public static void UpdateCaseStatus (list <FeedComment> FCList)
    {
        for (FeedComment fc : FCList) if (UpdateCaseStatusREQ (fc)) UpdateCaseStatus (fc);
    }
    
    public static void UpdateCaseStatus (FeedComment fc)
    {
        Case c = null;
        if (fc.parentid!=null && CaseMap.containsKey (fc.parentid)) c = CaseMap.get (fc.parentid);
        system.debug('TESTING c is '+c);
        
        set <String> requiredrectypes = new set <string>{'salesforce_team','sales_operations'};
        
        boolean SHouldUpdate = c!=null && c.recordtypeid!=null && requiredrectypes.contains(c.recordtype.developername.tolowercase()) && c.assigned_to__c!=userinfo.getuserid();
        system.debug('TESTING ShouldUpdate is '+ShouldUpdate);
        
        if (ShouldUpdate){c.status = 'New comment from user'; Case4Update.put (c.id,c);}
        
    }
    
    public static void HandleAfter (list  <FeedComment> FCList)
    {
        UpdateCaseStatus (FCList);
        
        utils.CodeOff = true;
        
        system.debug('TESTING Case4Update is '+Case4Update.size());
        if (Case4Update.size()>0){ update Case4Update.values(); Case4Update.clear();}
        
        utils.CodeOff  = false;
        
    }

}