public with sharing class knowledgeSearchController {
    public knowledgeSearchController() {
    }

    @AuraEnabled(cacheable=true)
    public static List<String> KnowledgeRecordTypes(){
        List<String> knowledgeRecordTypesValues = new List<String>();

        // Query all Knowledge__kav active record types
        for (RecordType rt : [SELECT Name FROM RecordType WHERE IsActive = true AND SobjectType = 'Knowledge__kav']) {
            knowledgeRecordTypesValues.add(rt.Name);
        }
        System.debug('knowledgeRecordTypesValues:' + knowledgeRecordTypesValues);
        return knowledgeRecordTypesValues;
    }    
    

    // Searching in Knowledge 
    @AuraEnabled(cacheable=true)
    public static List<KnowledgeArticleVersion> KnowledgeArticles(String input, String cat, String productArea, String subProductArea, boolean ifCommunityHeader) {
      
        List<KnowledgeArticleVersion> knowledgeArticlesList = new List<KnowledgeArticleVersion>();        
        
        String knowledgeQuery_1 = '';
        String knowledgeQuery_2 = '';
        String knowledgeQuery_3 = '';
        String knowledgeQuery_4 = '';
        String knowledgeQuery_5 = '';
        String knowledgeQuery_6 = '';
        String knowledgeQueryFromTopicAssignment_1 = '';
        String knowledgeQueryFromTopicAssignment_2 = '';
        String knowledgeQueryFromTopicAssignment_3 = '';
        String knowledgeQueryFromTopicAssignment_4 = '';
        String knowledgeQueryFromTopicAssignment_5 = '';        
        String knowledgeQueryFromTopicAssignment_6 = '';
        
        
        
        
            // Get the base URL.
            String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
            System.debug('Base URL: ' + sfdcBaseURL ); 
            boolean IfFromCommunity = true;
            // Set Filters for communiry
            String visableFilters = ' AND (IsVisibleInPrm = ' +  true + ' OR IsVisibleInCsp = ' +  true + ')';
            if( sfdcBaseURL.contains('https://checkmarx--uat.my.salesforce.com') || sfdcBaseURL.contains('https://checkmarx.my.salesforce.com')) {   
                // SalesForce Users
                // Delete Filters
                IfFromCommunity = false;
                visableFilters = '';
                System.debug('IfFromCommunity : ' + IfFromCommunity );    
                // Checking for not relevant category
                if(cat == 'INTERNAL - Cx Business Applications' || cat == 'INTERNAL - Cx Sales Operations' ) {
                    // Not relevant category - Not Filtering
                    return knowledgeArticlesList;
                }           
            }
            
            

            if(ifCommunityHeader){
                              
                // Filter from community general search (Community Hompe Page).
                if (cat != null && cat != 'null' && cat != '' && cat != 'All') {  
                    // category isn't null 
                    // Filter when creating new case or existing open case                
                    if (productArea != null && productArea != '' && productArea != 'null') {                                        
                        // product Area isn't null
                        if (input != null && input != 'null' && input != '' ) {    
                            // input isn't null                                                  
                            if(subProductArea != null && subProductArea != 'null' && subProductArea != '')    {
                                // sub Product Area isn't null   
                                //  1st  filter based on sub Product Area                                                  
                                //  2nd  filter based on subject content:                        
                                // - Search the subject content in Topics or Title                        
                                // - If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search empty                      
                                System.debug('Filter base on "category" & "product area" & "sub product area" & "user input"');     
                                knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  and  ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  subProductArea + ' LIMIT 5';                           
                                knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';                                
                                knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  productArea + '  LIMIT 5';
                                knowledgeQuery_4 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  cat + '  LIMIT 5';
                                                                
                                 // FromTopicAssignment
                                knowledgeQueryFromTopicAssignment_1 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + productArea.replace('__c', '') + '%\' AND  EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\') AND EntityId In (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + ') LIMIT 1000';
                                knowledgeQueryFromTopicAssignment_2 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + cat.replace('__c', '') + '%\' AND EntityId IN (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ') LIMIT 1000';
                                                                
                            }
                            else{
                                // sub Product Area null                             
                                //  1st filter based on Product area                        
                                //  2rd  filter based on subject content:                        
                                // - Search the subject content in Topics or Title                        
                                // - If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search empty                      
                                System.debug('Filter base on "category" & "product area" & "user input"');     
                                knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  productArea + ' LIMIT 5';                            
                                knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea + '  LIMIT 5';                                
                                knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  productArea + '  LIMIT 5';                                
                                knowledgeQuery_4 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  cat + '  LIMIT 5';
                                
                                // FromTopicAssignment
                                knowledgeQueryFromTopicAssignment_1 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + productArea.replace('__c', '') + '%\' AND  EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\') AND EntityId In (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + ') LIMIT 1000';
                                knowledgeQueryFromTopicAssignment_2 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + productArea.replace('__c', '') + '%\' AND EntityId IN (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ') LIMIT 1000';
                                                            
                                
                            }                                             
                        }
                        else{     
                                // input null  
                                if(subProductArea != null && subProductArea != 'null' && subProductArea != '')    {
                                    // sub Product Area isn't null 
                                    System.debug('Filter base on "category" & "product area"  & "sub product area"');                                          
                                    //  1st  filter based on sub Product Area  
                                    //  2nd filter based on Product area                                            
                                     knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  subProductArea + '  LIMIT 5';
                                     knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';                                
                                     knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea + '  LIMIT 5'; 
                                     knowledgeQuery_4 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  cat + '  LIMIT 5';
                                    
                                }
                                else{
                                    // sub Product Area null 
                                    System.debug('Filter base on "category" & "product area"');                                          
                                    //  1st  filter based on Product area                                                                                  
                                     knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';
                                     knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea + '  LIMIT 5';
                                     knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  cat + '  LIMIT 5';
                                     knowledgeQuery_4 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  cat + '  LIMIT 5';
                                    
                                }
                                                                                                                    
                            }
                    }else{
                        // Product Area null
                        System.debug('Filter in header Community'); 
                        if (input != null && input != 'null' && input != '' ) {  
                            // input isn't null  
                            System.debug('Filter base on "category" & "input"');   
                            knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + cat + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  cat + ' LIMIT 5';                                                        
                            knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + cat + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  cat + '  LIMIT 5';                            
                            knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  cat + '  LIMIT 5';                                                                                                             
                            
                            // FromTopicAssignment
                            knowledgeQueryFromTopicAssignment_1 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + cat.replace('__c', '') + '%\' AND  EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + cat + '%\' OR  Topic.Name LIKE \'%' + input + '%\') AND EntityId In (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + ') LIMIT 1000';
                            knowledgeQueryFromTopicAssignment_2 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + cat.replace('__c', '') + '%\' AND EntityId IN (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ') LIMIT 1000';
                            
                           
                        }
                        else{       
                            // input null
                            System.debug('Filter base on "category"');  
                            knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  cat + '  LIMIT 5';
                            knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  cat + '  LIMIT 5';                                                
                        }
                        // Not Filtering - return empty List
                        //return knowledgeArticlesList;
                    }
                }        
                else if (input != null && input != 'null' && input != '' ) {    
                    // input isn't null                
                    // 1st  Search the subject content in Topics or Title
                    // 2nd  Search If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search
                    System.debug('Filter in Community Hompe Page');                 
                    System.debug('Searching for 5 Match of user input in topic name assigned to knowladge'); 
                    knowledgeQuery_1 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  Topic.Name LIKE \'%' + input + '%\') AND (Not Title LIKE \'%' + input + '%\') AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                
                    System.debug('If did not find 5 Match Searching for 5 Match of user input in knowladge title'); 
                    knowledgeQuery_2 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\' AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                                
                    System.debug('If did not find 5 Match Searching for 5 Match of user input in Knowledge Summary'); 
                    //knowledgeQuery_3 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE  Id IN (Select Id from Knowledge__kav  Where Summary LIKE \'%' + input + '%\' OR ProblemNew__c LIKE \'%' + input + '%\' OR Cause__c LIKE \'%' + input + '%\' OR Resolution__c  LIKE \'%' + input + '%\' ) AND (Not Title LIKE \'%' + input + '%\') AND (NOT Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  Topic.Name LIKE \'%' + input + '%\'))  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                
                    knowledgeQuery_3 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE  Id IN (Select Id from Knowledge__kav  Where Summary LIKE \'%' + input + '%\') AND (Not Title LIKE \'%' + input + '%\') AND (NOT Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  Topic.Name LIKE \'%' + input + '%\'))  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                
                    }
                    else{
                        // input null   
                        // Not Filtering - return empty List
                        System.debug('Not Filtering');   
                        return knowledgeArticlesList;
                    }
            }
            else{
                // Not in community header
                if (cat != null && cat != 'null' && cat != '' && cat != 'All') {  
                    // category isn't null 
                    // Filter when creating new case or existing open case                
                    if (productArea != null && productArea != '' && productArea != 'null') {                                        
                        // product Area isn't null
                        if (input != null && input != 'null' && input != '' ) {    
                            // input isn't null                                                  
                            if(subProductArea != null && subProductArea != 'null' && subProductArea != '')    {
                                // sub Product Area isn't null   
                                //  1st  filter based on sub Product Area                                                  
                                //  2nd  filter based on subject content:                        
                                // - Search the subject content in Topics or Title                        
                                // - If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search empty                      
                                System.debug('Filter base on "category" & "product area" & "sub product area" & "user input"');     
                                knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  and  ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  subProductArea + ' LIMIT 5';                           
                                knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';
                                knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  productArea + '  LIMIT 5';
                               
                                   // FromTopicAssignment
                                knowledgeQueryFromTopicAssignment_1 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + productArea.replace('__c', '') + '%\' AND  EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\') AND EntityId In (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + ') LIMIT 1000';
                                knowledgeQueryFromTopicAssignment_2 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + cat.replace('__c', '') + '%\' AND EntityId IN (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ') LIMIT 1000';
                                
                            }
                            else{
                                // sub Product Area null                             
                                //  1st filter based on Product area                        
                                //  2rd  filter based on subject content:                        
                                // - Search the subject content in Topics or Title                        
                                // - If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search empty                      
                                System.debug('Filter base on "category" & "product area" & "user input"');     
                                knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  and ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  productArea  + ' LIMIT 5';                            
                                knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea  + ' LIMIT 5';
                                knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  productArea + '  LIMIT 5';
                                
                                  // FromTopicAssignment
                                knowledgeQueryFromTopicAssignment_1 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + productArea.replace('__c', '') + '%\' AND  EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\') AND EntityId In (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + ') LIMIT 1000';
                                knowledgeQueryFromTopicAssignment_2 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + productArea.replace('__c', '') + '%\' AND EntityId IN (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ') LIMIT 1000';
                                                            
                            }                                             
                        }
                        else{     
                                // input null  
                                if(subProductArea != null && subProductArea != 'null' && subProductArea != '')    {
                                    // sub Product Area isn't null 
                                    System.debug('Filter base on "category" & "product area"  & "sub product area"');                                          
                                    //  1st  filter based on sub Product Area  
                                    //  2nd filter based on Product area                                            
                                     knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  subProductArea + '  LIMIT 5';
                                     knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';                                
                                    
                                }
                                else{
                                    // sub Product Area null 
                                    System.debug('Filter base on "category" & "product area"');                                          
                                    //  1st  filter based on Product area                                                                                  
                                     knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';
                                     knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea + '  LIMIT 5';
                                    
                                }
                                                                                                                    
                            }
                    }else{
                        // Product Area null - No Filtering
                        System.debug('Filter in case - new or open, from Community or salesforce'); 
                        if (input != null && input != 'null' && input != '' ) {  
                            // input isn't null  
                              System.debug('Filter base on "category" & "input"');   
                            knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + cat + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  cat + ' LIMIT 5';                                                        
                            knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + cat + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  cat + '  LIMIT 5';                            
                            knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  cat + '  LIMIT 5';                                                                                                             
                            
                            // FromTopicAssignment
                            knowledgeQueryFromTopicAssignment_1 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + cat.replace('__c', '') + '%\' AND  EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + cat + '%\' OR  Topic.Name LIKE \'%' + input + '%\') AND EntityId In (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + ') LIMIT 1000';
                            knowledgeQueryFromTopicAssignment_2 = 'SELECT EntityId , Entity.Title FROM TopicAssignment WHERE Topic.Name  like \'%' + cat.replace('__c', '') + '%\' AND EntityId IN (SELECT Id FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ') LIMIT 1000';
                                                                                                                                         
                        }
                        else{       
                            // input null
                            System.debug('No Filter base on "category"');   
                            // Not Filtering - return empty List
                            return knowledgeArticlesList;                                               
                        }
                        
                    }
                }           

                    
            }
         /*
           if (cat != null && cat != 'null' && cat != '' && cat != 'All') {  
                // category isn't null 
                // Filter when creating new case or existing open case                
                if (productArea != null && productArea != '' && productArea != 'null') {                                        
                    // product Area isn't null
                    if (input != null && input != 'null' && input != '' ) {    
                        // input isn't null                                                  
                        if(subProductArea != null && subProductArea != 'null' && subProductArea != '')    {
                            // sub Product Area isn't null   
                            //  1st  filter based on sub Product Area                                                  
                            //  2nd  filter based on subject content:                        
                            // - Search the subject content in Topics or Title                        
                            // - If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search empty                      
                            System.debug('Filter base on "category" & "product area" & "sub product area" & "user input"');     
                            knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  and  ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  subProductArea + ' LIMIT 5';                           
                            knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';
                            knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  productArea + '  LIMIT 5';
                           
                        }
                        else{
                            // sub Product Area null                             
                            //  1st filter based on Product area                        
                            //  2rd  filter based on subject content:                        
                            // - Search the subject content in Topics or Title                        
                            // - If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search empty                      
                            System.debug('Filter base on "category" & "product area" & "user input"');     
                            knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  and ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\' ' + visableFilters + '  WITH DATA CATEGORY Products__c BELOW ' +  productArea + ' LIMIT 5';                            
                            knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND ( Topic.Name LIKE \'%' + productArea + '%\' OR  Topic.Name LIKE \'%' + input + '%\')) AND Title LIKE \'%' + input + '%\'  AND  PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea + '  LIMIT 5';
                            knowledgeQuery_3 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\'  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE_OR_BELOW ' +  productArea + '  LIMIT 5';
                            
                        }                                             
                    }
                    else{     
                            // input null  
                            if(subProductArea != null && subProductArea != 'null' && subProductArea != '')    {
                                // sub Product Area isn't null 
                                System.debug('Filter base on "category" & "product area"  & "sub product area"');                                          
                                //  1st  filter based on sub Product Area  
                                //  2nd filter based on Product area                                            
                                 knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  subProductArea + '  LIMIT 5';
                                 knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';                                
                                
                            }
                            else{
                                // sub Product Area null 
                                System.debug('Filter base on "category" & "product area"');                                          
                                //  1st  filter based on Product area                                                                                  
                                 knowledgeQuery_1 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c BELOW ' +  productArea + '  LIMIT 5';
                                 knowledgeQuery_2 = 'SELECT Id,Title FROM KnowledgeArticleVersion WHERE PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + ' WITH DATA CATEGORY Products__c ABOVE ' +  productArea + '  LIMIT 5';
                                
                            }
                                                                                                                
                        }
                }else{
                    // Product Area null - No Filtering
                    System.debug('Filter in case - new or open, from Community or salesforce'); 
                    if (input != null && input != 'null' && input != '' ) {  
                        // input isn't null  
                        System.debug('No Filter base on "category" & "input"');                                                                                                                
                    }
                    else{       
                        // input null
                        System.debug('No Filter base on "category"');                                                  
                    }
                    // Not Filtering - return empty List
                    return knowledgeArticlesList;
                }
            }           
            else { 
                // category null
                // product Area null   
                // sub product Area null                   
                // Filter from community general search (Community Hompe Page).
                if (input != null && input != 'null' && input != '' ) {    
                // input isn't null                
                // 1st  Search the subject content in Topics or Title
                // 2nd  Search If we didn’t find at least 5 matches -> Search the subject content in the article content (main fields) -> so we will not keep the search
                System.debug('Filter in Community Hompe Page');                 
                System.debug('Searching for 5 Match of user input in topic name assigned to knowladge'); 
                knowledgeQuery_1 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  Topic.Name LIKE \'%' + input + '%\') AND (Not Title LIKE \'%' + input + '%\') AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                
                System.debug('If did not find 5 Match Searching for 5 Match of user input in knowladge title'); 
                knowledgeQuery_2 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE Title LIKE \'%' + input + '%\' AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                                
                System.debug('If did not find 5 Match Searching for 5 Match of user input in Knowledge Summary'); 
                //knowledgeQuery_3 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE  Id IN (Select Id from Knowledge__kav  Where Summary LIKE \'%' + input + '%\' OR ProblemNew__c LIKE \'%' + input + '%\' OR Cause__c LIKE \'%' + input + '%\' OR Resolution__c  LIKE \'%' + input + '%\' ) AND (Not Title LIKE \'%' + input + '%\') AND (NOT Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  Topic.Name LIKE \'%' + input + '%\'))  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                
                knowledgeQuery_3 = 'SELECT Id, Title FROM KnowledgeArticleVersion WHERE  Id IN (Select Id from Knowledge__kav  Where Summary LIKE \'%' + input + '%\') AND (Not Title LIKE \'%' + input + '%\') AND (NOT Id IN (Select EntityId from TopicAssignment Where EntityType = ' + '\'' + 'Knowledge' + '\'  AND  Topic.Name LIKE \'%' + input + '%\'))  AND PublishStatus =  ' + '\'' + 'Online' + '\'  ' + visableFilters + '  LIMIT 5 ';                
                }
                else{
                    // input null   
                    // Not Filtering - return empty List
                    System.debug('Not Filtering');   
                    return knowledgeArticlesList;
                }
            }*/

            knowledgeArticlesList = getKnowledgeArticles(knowledgeArticlesList, knowledgeQuery_1,knowledgeQuery_2,knowledgeQuery_3,knowledgeQuery_4,knowledgeQuery_5,knowledgeQuery_6);
            if( knowledgeQueryFromTopicAssignment_1 != '' || knowledgeQueryFromTopicAssignment_2 != '' || knowledgeQueryFromTopicAssignment_3 != '' || knowledgeQueryFromTopicAssignment_4 != '' || knowledgeQueryFromTopicAssignment_5 != '' || knowledgeQueryFromTopicAssignment_6 != '' ){
            knowledgeArticlesList = getKnowledgeArticlesFromTopicAssignment(knowledgeArticlesList, knowledgeQueryFromTopicAssignment_1, knowledgeQueryFromTopicAssignment_2, knowledgeQueryFromTopicAssignment_3, knowledgeQueryFromTopicAssignment_4, knowledgeQueryFromTopicAssignment_5, knowledgeQueryFromTopicAssignment_6);    
            }
            
            return knowledgeArticlesList; 
                                       
    }

// From KnowledgeArticleVersion
    public static List<KnowledgeArticleVersion> getKnowledgeArticles(List<KnowledgeArticleVersion> knowledgeArticlesList,String knowledgeQuery_1, String knowledgeQuery_2, String knowledgeQuery_3, String knowledgeQuery_4, String knowledgeQuery_5, String knowledgeQuery_6) {
      //  List<KnowledgeArticleVersion> knowledgeArticlesList = new List<KnowledgeArticleVersion>();
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_1, '1');
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_2 != ''){
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_2, '2');
        }
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_3 != ''){
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_3, '3'); 
        }
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_4 != ''){
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_4, '4'); 
        } 
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_5 != ''){
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_5, '5'); 
        }  
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_6 != ''){
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_6, '6'); 
        }  
        return knowledgeArticlesList;
    }

    
    public static List<KnowledgeArticleVersion> getknowledgeQuery(List<KnowledgeArticleVersion> knowledgeArticlesList, String knowledgeQuery, String searchNumber) {
        
        List<KnowledgeArticleVersion> knowledgeArticlesTmpList = new List<KnowledgeArticleVersion>();
        
        Boolean helper = false;
        System.debug('Doing search no. ' + searchNumber);                
        knowledgeArticlesTmpList = Database.query(knowledgeQuery);
        for(KnowledgeArticleVersion k : knowledgeArticlesTmpList){
            if(knowledgeArticlesList.size() < 5){
                System.debug('Title :' + k.Title); 
                for(KnowledgeArticleVersion kav : knowledgeArticlesList){
                    if(kav.id == k.id){
                        helper = true;
                        break;
                    }
                }
                if(!helper){
                    knowledgeArticlesList.Add(k);
                   }                                    
                }else{
                    break;
                }
         }                                   
        System.debug('Total Found ' + knowledgeArticlesList.size() + ' articles');        
        return knowledgeArticlesList;
    }
    
    //FromTopicAssignment
        public static List<KnowledgeArticleVersion> getKnowledgeArticlesFromTopicAssignment(List<KnowledgeArticleVersion> knowledgeArticlesList,String knowledgeQuery_1, String knowledgeQuery_2, String knowledgeQuery_3, String knowledgeQuery_4, String knowledgeQuery_5, String knowledgeQuery_6) {      
        knowledgeArticlesList = getknowledgeQueryFromTopicAssignment(knowledgeArticlesList, knowledgeQuery_1, '1');
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_2 != ''){
        knowledgeArticlesList = getknowledgeQueryFromTopicAssignment(knowledgeArticlesList, knowledgeQuery_2, '2');
        }
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_3 != ''){
        knowledgeArticlesList = getknowledgeQueryFromTopicAssignment(knowledgeArticlesList, knowledgeQuery_3, '3'); 
        }
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_4 != ''){
        knowledgeArticlesList = getknowledgeQueryFromTopicAssignment(knowledgeArticlesList, knowledgeQuery_4, '4'); 
        } 
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_5 != ''){
        knowledgeArticlesList = getknowledgeQueryFromTopicAssignment(knowledgeArticlesList, knowledgeQuery_5, '5'); 
        }  
        if(knowledgeArticlesList.size() < 5 && knowledgeQuery_6 != ''){
        knowledgeArticlesList = getknowledgeQuery(knowledgeArticlesList, knowledgeQuery_6, '6'); 
        }  
        return knowledgeArticlesList;
    }

    
     public static List<KnowledgeArticleVersion> getknowledgeQueryFromTopicAssignment(List<KnowledgeArticleVersion> knowledgeArticlesList, String knowledgeQuery, String searchNumber) {
               
        List<TopicAssignment> TopicAssignmentTmpList = new List<TopicAssignment>();        
        Boolean helper = false;
        System.debug('Doing search no. ' + searchNumber);                        
        TopicAssignmentTmpList = Database.query(knowledgeQuery);
        for(TopicAssignment k : TopicAssignmentTmpList){
            if(knowledgeArticlesList.size() < 5){
                 System.debug('Title :' + k.Entity.Title); 
                for(KnowledgeArticleVersion kav : knowledgeArticlesList){
                    if(kav.id == k.EntityId){
                        helper = true;
                        break;
                    }
                }
                if(!helper){
                    string newknowledgeQuery = 'Select Id,Title From KnowledgeArticleVersion Where Id  =  ' + '\'' + k.EntityId + '\'';
                    KnowledgeArticleVersion n = (KnowledgeArticleVersion)Database.query(newknowledgeQuery)[0];
                    knowledgeArticlesList.Add(n);
                   }                                    
                }else{
                    break;
                }
         }           
                        
        System.debug('Total Found ' + knowledgeArticlesList.size() + ' articles');        
        return knowledgeArticlesList;
    }
}