@isTest(SeeAllData=true)
public with sharing class knowledgeSearchControllerTest {

    @isTest
    private static void KnowledgeRecordTypes(){       
      
        Test.startTest();
            List<String> knowledgeRecordTypesValues = new List<String>();
            knowledgeRecordTypesValues = knowledgeSearchController.KnowledgeRecordTypes();
            System.assertEquals(3, knowledgeRecordTypesValues.size());                 
        Test.stopTest();

    }
    
     @isTest
    private static void KnowledgeArticlesInCommunityHeader(){       
      
        Test.startTest();
            List<KnowledgeArticleVersion> knowledgeArticlesList = new List<KnowledgeArticleVersion>();        
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('', 'CxSAST__c', '', '', true);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
                    
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('cli', 'CxSAST__c', '', '', true);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
        
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('cli', 'CxSAST__c', 'CxSAST_CLI__c', '', true);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
        
           knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('', 'CxSAST__c', 'CxSAST_CLI__c', '', true);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
            
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('cli', 'CxSAST__c', 'CxSAST_CLI__c', 'CxSAST_Maven__c', true);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
        
           knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('', 'CxSAST__c', 'CxSAST_CLI__c', 'CxSAST_Maven__c', true);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
        
        Test.stopTest();

    }
    
     @isTest
    private static void KnowledgeArticlesNotInCommunityHeader(){       
      
        Test.startTest();
            List<KnowledgeArticleVersion> knowledgeArticlesList = new List<KnowledgeArticleVersion>();        
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('', 'CxSAST__c', '', '', false);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
                    
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('cli', 'CxSAST__c', '', '', false);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
        
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('cli', 'CxSAST__c', 'CxSAST_CLI__c', '', false);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
        
            knowledgeArticlesList = knowledgeSearchController.KnowledgeArticles('cli', 'CxSAST__c', 'CxSAST_CLI__c', 'CxSAST_Maven__c', false);
            System.assertEquals(knowledgeArticlesList.size(), knowledgeArticlesList.size()); 
            
        
        Test.stopTest();

    }
}