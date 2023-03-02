global with sharing class CaseRecordTypeNoLink implements sortablegrid.sdgIDataProvider {
    global static Boolean isUserSelectable()
    {
        return true;
    }
    global static sortablegrid.SDGResult getData(sortablegrid.SDG coreSDG,  sortablegrid.SDGRequest request)  
    {
        system.debug('SDG :'+coreSDG);
        system.debug('SDGRequest :'+request);
        sortablegrid.SDGResult result = new sortablegrid.SDGResult();
        try{
            result.isFiltered = false;
            integer dataoffset = (request.pageid-1) * request.pagesize;
            integer datalimit = request.PageSize;
            List<String> filters = new List<String>();            
            if (request.Filters!=null)
            {
                for(sortablegrid.SDGFilter filter: request.filters)
                {
                    System.debug('filter: '+filter);
                    String  fo = filter.FilterOperator;
                    String fv = String.escapeSingleQuotes(filter.FilterValue.trim());
                    String fid = filter.SDGFieldID;
                    if (fid == '1')
                    {
                        if(String.isNotBlank(fv))
                        {
                            if (fo == '=')
                            {
                                filters.add('DeveloperName  = \'' + fv+'\'');
                                result.isFiltered = true;
                            }
                            if (fo == 'NOT=')
                            {
                                filters.add('DeveloperName   != \'' + fv+'\'');
                                result.isFiltered = true;
                            }
                            if(fo=='CONTAINS')
                            {
                                filters.add('DeveloperName like \'%' + fv + '%\'');
                                result.isFiltered = true;
                            }
                            if(fo=='NOTCONTAINS')
                            {
                                filters.add('NOT DeveloperName like \'%' + fv + '%\'');
                                result.isFiltered = true;
                            }
                            if (fo=='STARTS')
                            {
                                filters.add('DeveloperName   like \'' + fv + '%\'');
                                result.isFiltered = true;
                            }
                            if (fo=='ENDS')
                            {
                                filters.add('DeveloperName  like \'%' + fv + '\'');
                                result.isFiltered = true;
                            }
                        }
                    }
                }
            }
            String filterstring = String.join(filters, ' AND ');
            System.debug('filterstring '+filterstring);
            if (!String.isblank(filterstring))  
            {
                filterstring = 'AND ' + filterstring;
                result.isFiltered = true;
            }
            String sSortClause = '';
            System.debug('request '+request);
            System.debug('request.SortColumn '+request.SortColumn);
            if (String.isNotBlank(request.SortColumn))
            {
                if (request.SortColumn == '1'){
                    if (request.sortOrder == 'A'){
                        sSortClause = ' ORDER BY DeveloperName ASC';
                    }
                    else{
                        sSortClause = ' ORDER BY DeveloperName DESC';
                    }
                }                
            }
            string query='select id,Name from RecordType where sobjecttype=\'Case\' and name in (\'CxIAST\', \'CxOSA\', \'CxSAST\',\'Codebashing\',\'Hosting solutions\', \'CxSCA\') '+filterstring+' '+ sSortClause;
            system.debug('query '+query);
            List<RecordType> recordTypes=database.query(query);
            System.debug(recordTypes);
            result.data = recordTypes;
            result.FullQueryCount = 0;
            if (result.data!=null)
                
            {
                result.FullQueryCount = result.data.size();
            }
            result.pagecount = 1;
            result.isError = false;
            result.ErrorMessage = '';  
        }
        
        catch (Exception ex)            
        {
            result.isError = true;
            result.ErrorMessage = ex.getMessage();
        }
        return result;
    }
    
    global sortablegrid.SDG LoadSDG(String SDGTag, String ParentRecordId)
    {    
        system.debug('CustomDataProviderExample:LoadSDG');
        sortablegrid.SDG CoreSDG = new sortablegrid.SDG( 'CustomDataProviderExample' );
        CoreSDG.sObjectName = 'RecordType';
        CoreSDG.SDGActions = getActions();
        if(getFields()!=null){
            CoreSDG.SDGFields = getFields();
        }
        return CoreSDG;
    }

    private List<sortablegrid.SDGAction> GetActions()
    {
        List<sortablegrid.SDGAction> actions = new List<sortablegrid.SDGAction>();
        actions.add(new sortablegrid.SDGAction('1', 'New', 'e.c:DynamicLayoutDialogStarter', 'Row Button', '{"sObjectName": "Case","recordTypeId": "#Id#","layoutMode": "NEW"}', 'utility:new', 1));
        return actions;
    }
    private List<sortablegrid.SDGField> GetFields()
    {
        List<sortablegrid.SDGField> fields = new List<sortablegrid.SDGField>();
        fields.add( new sortablegrid.SDGField('1', 'Case Type', 'Name', 'STRING', '', true, true, TRUE, null, 1));
        system.debug(fields);
        return fields;
    }
}