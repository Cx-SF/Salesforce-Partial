@isTest
public with sharing class RemoveHTMLTagsInvocable_TEST {
    private static testMethod void testMethod1() {
        
        String test = '<b>Hello World</b>';
        List<RemoveHTMLTagsInvocable.FlowInput> InputsList=new List<RemoveHTMLTagsInvocable.FlowInput>();
        RemoveHTMLTagsInvocable.FlowInput inputs =new RemoveHTMLTagsInvocable.FlowInput();
        inputs.textWithTags = test ;    
        InputsList.add(inputs);  

        System.Test.startTest();
        List<RemoveHTMLTagsInvocable.FlowOutput> results= RemoveHTMLTagsInvocable.RemoveHTMLTagsInvocable(InputsList);
        System.Debug(results[0].textWithoutTags);

        System.Test.stopTest();

        system.assertEquals('Hello World', results[0].textWithoutTags);

    }
}