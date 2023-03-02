global class FreezeUnFreezeUser_Schedule implements Schedulable {
	public static String CRON_EXP = '0 0 0 3 9 ? 2022'; //Used for test class only

    global void execute(SchedulableContext sc) {
        system.debug('iCloudius - FreezeUnFreezeUser_Schedule - START ');
        
		List <UserLogin> lul = [SELECT Id, UserId FROM UserLogin WHERE IsFrozen = true];
		Map <Id, UserLogin> userLoginMap = new Map <Id, UserLogin>();
		Map <Id, User> userMap = new Map <Id, User>();
		List <User> user2Update = new List <User>();

		for (UserLogin ul: lul) userLoginMap.put(ul.UserId, ul);
				
		List <User> lu = [SELECT Id FROM User WHERE Cx_IsFrozen__c = true];
		if (lu != null && !lu.isEmpty()) userMap.putAll(lu);

		for (UserLogin ul: lul) if (!userMap.containsKey(ul.UserId)) user2Update.add(new User(Id = ul.UserId, Cx_IsFrozen__c = true));
		for (User u: lu) if (!userLoginMap.containsKey(u.Id)) user2Update.add(new User(Id = u.Id, Cx_IsFrozen__c = false));

		Utils.CodeOff = true;
		System.debug('iCloudius - Users to update: ' + user2Update.size());
		update user2Update;
		Utils.CodeOff = false;        

    }
}