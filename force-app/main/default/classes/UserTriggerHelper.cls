public with sharing class UserTriggerHelper {

    
    public static void rolesInTheUserWereUpdated(Map <Id,User> newMap , Map <Id,User> oldMap){
            List<User> usersList= new List<User>();
            List<Id> usersIdList= new List<Id>();
            for (User u : newMap.values()){
                if(oldMap!=null){
                    if(u.IsActive==true && u.Director_Of_Sales__c!=oldMap.get(u.id).Director_Of_Sales__c ){
                        usersList.add(u);
                        usersIdList.add(u.id);
                    }  
                }
            }
            updateAccounts(usersList,usersIdList);
        }
        public static void updateAccounts(List<User> usersList, List<Id> usersIdList ){
            system.debug('usersList : '+usersList);
            system.debug('usersIdList : '+usersIdList);
            List<Account> accountsToUpdate = [SELECT id,CX_Owner_Director__c,OwnerId, Owner.Director_Of_Sales__c FROM account WHERE OwnerId in:usersIdList];
            system.debug('accountsToUpdate : '+accountsToUpdate);
            List<Account> updatedAccounts = new List<Account>();
            for(Account a:accountsToUpdate){
                a.CX_Owner_Director__c=a.Owner.Director_Of_Sales__c;
                updatedAccounts.add(a);
            }
            system.debug('updatedAccounts : '+updatedAccounts);
            if (!updatedAccounts.isEmpty()){
                Update updatedAccounts;
            }
    
    }
}