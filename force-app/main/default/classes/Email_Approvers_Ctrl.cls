global class Email_Approvers_Ctrl {
    
   public string ParentId { get; set; }
   public string  cc_Name {get; set;}
   public string  cc_groupId {get; set;}
   public string  cc_OwnerId {get; set;}
   public string cc_userId {get; set;}
   public list <sbaa__Approval__c> AllApprovers { get; set; }
    
   public list <sbaa__Approval__c> RecordsToDisplay
    {
        get
        {
            list <sbaa__Approval__c> AllRs = new list <sbaa__Approval__c> (); 
            set <string> ApproversName = new set <string> ();
         for(sbaa__Approval__c app : [SELECT Id, sbaa__Status__c, WDCX_ConsolidatedApprover__c, sbaa__Rule__r.Name, sbaa__CommentsLong__c, sbaa__ApprovalChain__r.name, sbaa__ApprovalStep__c FROM sbaa__Approval__c where Quote__c =:ParentId ORDER BY sbaa__ApprovalChain__r.name, sbaa__ApprovalStep__c  ])   
            {
                if(!(ApproversName.contains(app.WDCX_ConsolidatedApprover__c ))){
                //ApproversName.add(app.WDCX_ConsolidatedApprover__c );
					AllRs.add(app);
                }
            }
			/*for(sbaa__Approval__c sbaaApproval : AllRs){
				
			}*/
            AllApprovers = AllRs;
            return AllApprovers;
        }
        set;
    }

	public String inTheGroup
	{
		get{
			
			String nameFromGtoup = 'tt';
			List<Id> userListId = new List<Id>();
			List<String> userNameList = new List<String>();
			//List<sbaa__Approver__c> apprList = [Select sbaa__GroupId__c from sbaa__Approver__c where id =: cc_aproverId];
			//String groupIdApp = apprList[0].sbaa__GroupId__c;
			List<GroupMember> groupM = [Select GroupId, UserOrGroupId from GroupMember where GroupId =: cc_groupId];
			for(GroupMember GM : groupM){
				userListId.add(GM.UserOrGroupId);
			}

			for(User u : [Select Id, name from user where id in :userListId]){
				userNameList.add(u.Name);
				if(cc_OwnerId == u.Id) nameFromGtoup = u.Name;
			}

			System.debug('Rafa - User Name List: ' + userNameList);

			return nameFromGtoup;
		}
		set;
	}

	public List<String> memberGroup
	{
		get{
			List<String> userGroup = new List<String>();
			if(cc_userId != null){
				Map<Id, String> GroupMap = new Map<Id, String>();
				for(Group lstPublicGroup : [SELECT Id, name FROM Group]){
					if(lstPublicGroup.name != null) GroupMap.put(lstPublicGroup.Id, lstPublicGroup.name);
				}

				Map<Id, List<Id>> groupMeMap = new Map<Id, List<Id>>();
				for(GroupMember m : [Select GroupId, UserOrGroupId from GroupMember]){
					if(groupMeMap.containsKey(m.GroupId)){
						groupMeMap.get(m.GroupId).add(m.UserOrGroupId);
					}else{
						List<Id> memberIdList = new List<Id>();
						memberIdList.add(m.UserOrGroupId);
						groupMeMap.put(m.GroupId, memberIdList);
					}
				}

				
				for(Id groupId : groupMeMap.keySet()){
					if(groupMeMap.get(groupId).contains(cc_userId)) userGroup.add(GroupMap.get(groupId));
				}
			}
			return userGroup;
	}
		set;
	}

    
  
}