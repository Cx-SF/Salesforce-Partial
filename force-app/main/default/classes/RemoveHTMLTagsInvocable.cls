public with sharing class RemoveHTMLTagsInvocable {
    @InvocableMethod(label='Remove HTMl Tags from text')
    
    public static List<FlowOutput> RemoveHTMLTagsInvocable(List<FlowInput> request) {
        String textWithTags = request[0].textWithTags;
        String convertedField = textWithTags.stripHtmlTags();
        System.Debug(convertedField);

        List<FlowOutput> results=new List<FlowOutput>();
        FlowOutput result= new FlowOutput();
        result.textWithoutTags = convertedField;
        results.add(result);
        system.debug('results= '+results);
    return results; 

    }


    public class FlowInput{
        @InvocableVariable
        public String textWithTags;

}
    public class FlowOutput{
        @InvocableVariable
        public String textWithoutTags;
}

}