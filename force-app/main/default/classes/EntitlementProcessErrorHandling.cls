public class EntitlementProcessErrorHandling {
    
    public static List<SaveResultClass> SaveResultClassList=new List<SaveResultClass>();
    
    public static List<SaveResultClass> setErrorList(Database.SaveResult[] SaveResultList,List<sObject> objectList){
        SaveResultClassList.clear();
        for(Integer i=0;i<SaveResultList.size();i++){
            if (!SaveResultList.get(i).isSuccess()){
                for (Database.Error e : SaveResultList.get(i).getErrors())
                {               
                    EntitlementProcessErrorHandling.SaveResultClass c=new EntitlementProcessErrorHandling.SaveResultClass();
                    c.Id=objectList.get(i).Id;
                    c.ErrorMessage=e.getMessage();
                    SaveResultClassList.add(c);
                }
                
            }
        }
        return SaveResultClassList;
    }
    
    public static List<SaveResultClass> setErrorList(List<Database.upsertResult> SaveResultList,List<sObject> objectList){
        SaveResultClassList.clear();
        for(Integer i=0;i<SaveResultList.size();i++){
            if (!SaveResultList.get(i).isSuccess()){
                for (Database.Error e : SaveResultList.get(i).getErrors())
                {               
                    EntitlementProcessErrorHandling.SaveResultClass c=new EntitlementProcessErrorHandling.SaveResultClass();
                    c.Id=objectList.get(i).Id;
                    c.ErrorMessage=e.getMessage();
                    SaveResultClassList.add(c);
                }
                
            }
        }
        return SaveResultClassList;
    }
    
    public static void sendEmail(String objectName,List<EntitlementProcessErrorHandling.SaveResultClass> ListOfError,String ClassName){
        string header = 'id, ErrorMessage \n';
        string finalstr = header ;
        for(EntitlementProcessErrorHandling.SaveResultClass error: ListOfError)
        {
            string recordString = '"'+error.id+'","'+error.ErrorMessage+'"\n';
            finalstr = finalstr +recordString;
        }
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname= objectName+'.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
       
        List<Email_for_receive_errors__mdt> emailForReceiveError=[select email__c from Email_for_receive_errors__mdt];
        String[] toAddresses = new list<string>();
        for(Email_for_receive_errors__mdt em:emailForReceiveError) {
            toAddresses.add(em.email__c);
        }
        
        String subject =objectName+' CSV';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('Attached '+csvname +' is a file that contains a list of errors of object:'+objectName+' from running the class:'+ClassName);
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
         if (!Test.isRunningTest())
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
    public class SaveResultClass {
        string Id;
        string ErrorMessage;
        public SaveResultClass(){
        }
        public SaveResultClass(string Id,string ErrorMessage){
            this.Id=Id;
            this.ErrorMessage=ErrorMessage;
        }
    }
}