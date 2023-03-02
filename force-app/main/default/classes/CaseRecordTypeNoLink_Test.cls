@isTest
public with sharing class CaseRecordTypeNoLink_Test {  
    static testMethod void CaseRecordTypeNoLink_Test() {
        CaseRecordTypeNoLink mvig=new CaseRecordTypeNoLink();
        CaseRecordTypeNoLink.isUserSelectable();
        sortablegrid.SDG coreSDG=mvig.LoadSDG('','');
        sortablegrid.SDGRequest request=new sortablegrid.SDGRequest();
        request.PageID=1;
        request.PageSize=10;
        request.SortColumn='1';
        request.sortOrder='A';
        List<sortablegrid.SDGFilter> filtersList=new List<sortablegrid.SDGFilter>();
        filtersList.add(new sortablegrid.SDGFilter('1','NOT=', 'NOTCONTAINS'));
        filtersList.add(new sortablegrid.SDGFilter( '1','CONTAINS', 'NOTCONTAINS'));
        filtersList.add(new sortablegrid.SDGFilter('1','STARTS', 'NOTCONTAINS'));
        filtersList.add(new sortablegrid.SDGFilter('1','ENDS', 'NOTCONTAINS'));
        filtersList.add(new sortablegrid.SDGFilter('1','=', 'NOTCONTAINS'));
		filtersList.add(new sortablegrid.SDGFilter('1','NOTCONTAINS', 'NOTCONTAINS'));
        request.Filters=(filtersList);
        sortablegrid.SDGResult result= CaseRecordTypeNoLink.getData(coreSDG,request);
        sortablegrid.SDGRequest request1=new sortablegrid.SDGRequest();
        request1.PageID=1;
        request1.PageSize=10;
        request1.SortColumn='1';
        request1.sortOrder='D';
        sortablegrid.SDGResult result2= CaseRecordTypeNoLink.getData(coreSDG,request1);
    }
}