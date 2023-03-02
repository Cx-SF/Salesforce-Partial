global class UpdateContCommunityUserExpirationBatch implements Database.Batchable<sObject> {
   global List<Contact> contacts;

   global UpdateContCommunityUserExpirationBatch(List<Contact> contactsList){
     contacts = contactsList;
   }

   global List<Contact> start(Database.BatchableContext BC){
      //new  Iterable<sObject>();
      return contacts;
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
      update scope;
   }

   global void finish(Database.BatchableContext BC){
        
   }
}