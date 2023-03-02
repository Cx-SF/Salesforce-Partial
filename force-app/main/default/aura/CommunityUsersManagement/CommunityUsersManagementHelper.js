({
    
    setTables: function (component) {
        var rowActions = this.getRowActions.bind(this, component);
        
        component.set('v.usersColumns', [
            { label: 'First Name', fieldName: 'contactFirstName', type: 'text', height:"15px" ,sortable : true},
            { label: 'Last Name', fieldName: 'contactLastName', type: 'text'  ,sortable : true},
            { label: 'Email', type: 'text', fieldName: 'contactEmail' ,sortable : true , cellAttributes: { class: { fieldName: 'styleRestPassword' } } },//added cellAttributes by MichalH 24/07/19
            //{ label: 'Country', fieldName: 'contactCountry',initialWidth : 100, type: 'text' ,sortable : true },
            { label: 'Admin', fieldName: 'delegatedAdminText', type: 'text',sortable : true ,initialWidth : 80 ,cellAttributes: { class: { fieldName: 'styleAdmin' } } },
            { label: 'See all cases', type: 'text', fieldName: 'canSeeAllAccountCasesText', sortable: true, initialWidth: 80, cellAttributes: { class: { fieldName: 'styleSeeAllCases' } } }, // Added by Alex Levchenko on 12/07/2019
			{ label: 'User Status',initialWidth : 100,sortable : true, fieldName: 'userStatus', type: 'text' ,cellAttributes: { class: { fieldName: 'styleUserState' } } },
             { label: 'Select Action',type: 'action'  , initialWidth : 30, typeAttributes: {rowActions: rowActions}},
            { label: ' ', type: 'button', initialWidth : 130,  typeAttributes: { label: 'Save', title: 'Click to Save', name: 'save_status', iconName: 'utility:save', disabled: {fieldName: 'actionDisabled'}, class: 'btn_next'}},
            { label: 'Request Status', type: 'button' , initialWidth : 130, typeAttributes: { label: { fieldName: 'requestStatus'}, title: 'Click to view requests', name: 'view_requests', iconName: 'utility:zoomin', disabled: {fieldName: 'requestsButtonDisabled'}, class: 'btn_next'}},
           // { label: 'Approval',initialWidth : 100, type: 'button', typeAttributes: { label: {fieldName: 'lastApprovalStatus'}, title: {fieldName : 'lastApprovalMessage'}, name: 'showLastApproval', class: 'btn_next btnToPopup', disabled : true}  },
            {label: 'Community Privileges',initialWidth : 110, fieldName: 'commmunityPrivileges', type: 'text'  ,sortable : true},
            { label: 'Last login', fieldName: 'lastLogin',initialWidth : 170, type: 'date' , typeAttributes: {
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit"																							
            }
            },
			{ label: 'Expiration Date', fieldName: 'expirationDate',initialWidth : 170, type: 'Date' , typeAttributes: {
                year: "numeric",
                month: "2-digit",
                day: "2-digit"
            }
            }
            /* Commented by Hananel Cohen 29/1/2020
              * { label: 'Last Reset', fieldName: 'lastReset',initialWidth : 140, type: 'date' , typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                }
            },*/
                   ]);
        
        component.set('v.requestsColumns', [
            {label: 'Created Date', fieldName: 'createdDate', type: 'date', typeAttributes: {  
                                                                            day: 'numeric',  
                                                                            month: 'short',  
                                                                            year: 'numeric',  
                                                                            hour: '2-digit',  
                                                                            minute: '2-digit',  
                                                                            second: '2-digit',  
                                                                            hour12: true}},
            { label: 'Request', fieldName: 'request', type: 'text' },
            { label: 'Contact', fieldName: 'contact', type: 'text'  },
            { label: 'Action', fieldName: 'action', type: 'text'},
            { label: 'Status', fieldName: 'status', type: 'text' },
            { label: 'Reason', fieldName: 'reason', type: 'text',initialWidth : 250 }
        ]);
    },
    
    initData: function (component) {
        let getInitialData = component.get("c.getInitialData");
        component.set("v.isLoading", true);
        let accountId = component.get('v.recordId');
        getInitialData.setParams({
            'accountId': accountId
        });
		let self = this;       
        getInitialData.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let initialData = response.getReturnValue();
                let sortedUsers = self.sortUsersAndUpdateStatus(initialData.communityUsers);
                component.set("v.users", sortedUsers);
                component.set("v.account", initialData.userAccountName);
                component.set("v.recordId", initialData.userAccountId);
                component.set("v.maxPortalUsers", initialData.maxPortalUsers);
                component.set("v.availableUsers", initialData.availableUsers);
                component.set("v.haveAdditionalUsers", initialData.availableUsers > 0);
                component.set("v.communityContact", initialData.isCommunity);
                component.set("v.activeUsers", initialData.activeUsers);
                component.set("v.accounts", initialData.accounts);
                component.set("v.countries", initialData.countries);
                component.set("v.isSystemAdmin", initialData.isSystemAdmin);
                component.set("v.isPoc", initialData.isPoc);
                component.set("v.CantActivte", initialData.cantActivte);
                component.set("v.isStandard", initialData.isStandard);
                component.set("v.userType", initialData.userType);
                component.set("v.accountType", initialData.accountType);
                component.set("v.accountStatus", initialData.accountStatus);
            } else {
                console.log("Init data error "+ JSON.stringify(response.getError()));
            }
            component.set("v.isLoading", false);
        });
        $A.enqueueAction(getInitialData);
    },
    
    sortUsersAndUpdateStatus : function(users){
        if(!users || !users.length || users.length==0){
            return users;
        }
        let activeUsers = [];
        let inActiveUsers = [];
        users.forEach(function(item){
            if(item.lastApprovalStatus == 'Pending'){
                item.userStatus = 'Pending Approval';
            }
            if(item.userStatus=='Inactive' || item.lastApprovalStatus == 'Pending'){
                inActiveUsers.push(item);
            } else{
                activeUsers.push(item);
            }
        });
        return activeUsers.concat(inActiveUsers);
    },
    
    getRequests: function (component,contactId) {
        let getRequests = component.get("c.getRequests");
        
        getRequests.setParams({
            'contactId': contactId
        });
        
        getRequests.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let requests = response.getReturnValue();
                //console.log(JSON.stringify(requests));
                
                component.set("v.requests", requests);
            } else {
                console.log("Get requests error "+ JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(getRequests);
    },
    
    showToasts: function (component,variant,title,message,forContact){
        let avoidToasts = component.get('v.avoidToasts');
        let toastInfo = '';
        if(message != undefined) {
            message = message.replace("\\n", '');
        }
        
        if (avoidToasts === true){
            component.set("v.resultMessage2VF",title + '\n' + message);
            
            if(forContact === true ){
                component.set("v.showPopupIsteadToastContact",true);
            } else {
                component.set("v.showPopupIsteadToast",true);
            }
        } else {
            if (message === '') {
                toastInfo = {
                    'title': title,
                    'variant': variant
                };
            } else {
                toastInfo = {
                    'title': title,
                    'message': message,
                    'variant': variant,
                    'mode': 'sticky'
                };
            }
            
            component.find('notifLib').showToast(toastInfo);
        }
    },
    
    userManagementAction: function (component,action,rows) {
        let createRequests = component.get("c.createRequests");
        
        createRequests.setParams({
            'rowsJSON': JSON.stringify(rows),
            'accountId': component.get('v.recordId')
        });
        
        createRequests.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if (result===true){
                         
                    let avoidToasts = component.get('v.avoidToasts');
                    let toastInfo = '';
                    
                    if (avoidToasts === true){
                        
                        component.set("v.resultMessage2VF",'Request created!');
                        component.set("v.showPopupIsteadToast",true);
                        
                    } else {
                        let toastInfo = {
                            'title': 'Request created!',
                            'variant': 'success'
                        };
                        component.find('notifLib').showToast(toastInfo);
                    }
                    
                    
                }
            }
        });
        $A.enqueueAction(createRequests);
    },

	extensionTimePoc: function (component,action,rows) {
       // let createRequests = component.get("c.extensionPoc");
        
        createRequests.setParams({
            'rowsJSON': JSON.stringify(rows),
            'accountId': component.get('v.recordId')
        });
        
        createRequests.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if (result===true){
                         
                    let avoidToasts = component.get('v.avoidToasts');
                    let toastInfo = '';
                    
                    if (avoidToasts === true){
                        
                        component.set("v.resultMessage2VF",'extension created!');
                        component.set("v.showPopupIsteadToast",true);
                        
                    } else {
                        let toastInfo = {
                            'title': 'extension created!',
                            'variant': 'success'
                        };
                        component.find('notifLib').showToast(toastInfo);
                    }
                    
                    
                }
            }
        });
        $A.enqueueAction(createRequests);
    },
    
    createUserRequestForNewContact: function (component,newContactId,accId) {
        let createRequestForNewContact = component.get("c.createRequestForNewContact");
        
        createRequestForNewContact.setParams({
            'newContactId': newContactId,
            'accountId':accId
        });
        let self = this;
        createRequestForNewContact.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if (result===true){
                    
                    let avoidToasts = component.get('v.avoidToasts');
                    let toastInfo = '';
                    
                    if (avoidToasts === true){
                        
                        component.set("v.resultMessage2VF",'Request created!');
                        component.set("v.showPopupIsteadToast",true);
                        
                    } else {
                        let toastInfo = {
                            'title': 'Request created!',
                            'variant': 'success'
                        };
                        component.find('notifLib').showToast(toastInfo);
                    }
                }
            }
        });
        $A.enqueueAction(createRequestForNewContact);
    },
    
    validateContactForm: function(component) {
        var validContact = true;
        // Show error messages if required fields are blank
        
        var allValid = [component.find('contactField1') ,component.find('contactField2'),component.find('contactField3') ].reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        
        if (allValid) {
            // Verify we have an account to attach it to
            var account = component.get("v.newContact");
            if($A.util.isEmpty(account)) {
                validContact = false;
                console.log("Quick action context doesn't have a valid account.");
            }
            return(validContact);
            
        }
    },
    
    runJobs: function (component) {
        let runJobs = component.get("c.createScheduledJob");
        
        runJobs.setParams({
            'jobName': 'Community user requests handler'
        });
        
        runJobs.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                
                let avoidToasts = component.get('v.avoidToasts');
                let toastInfo = '';
                
                if (avoidToasts === true){
                    
                    component.set("v.resultMessage2VF",result);
                    component.set("v.showPopupIsteadToast",true);
                    
                } else {
                    let toastInfo = {
                        'title': result,
                        'variant': 'success'
                    };
                    component.find('notifLib').showToast(toastInfo);
                }
                
            }
        });
        $A.enqueueAction(runJobs);
    },
    
    abortJobs: function (component) {
        let abortJobs = component.get("c.abortAllJobs");
        
        abortJobs.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                
                let avoidToasts = component.get('v.avoidToasts');
                let toastInfo = '';
                
                if (avoidToasts === true){
                    
                    component.set("v.resultMessage2VF",result);
                    component.set("v.showPopupIsteadToast",true);
                    
                } else {
                    let toastInfo = {
                        'title': result,
                        'variant': 'success'
                    };
                    component.find('notifLib').showToast(toastInfo);
                }
                
            }
        });
        $A.enqueueAction(abortJobs);
    },
    
    initJobStatus : function (component) {
        let getStatus = component.get("c.areJobsRunning");
        
        getStatus.setCallback( this , function (response) {
            if (response.getState() === "SUCCESS") {
                let result = response.getReturnValue();
                if (result){
                    component.set("v.jobsStatus", "IS RUNNING" );
                } else {
                    component.set("v.jobsStatus", "IS STOPPED" );
                } 
            } else {
                component.set("v.jobsStatus", "UNKNOWN" );
            }
        });
        $A.enqueueAction(getStatus);
    },
    
    getRowActions : function (cmp, row, doneCallback) {
        
		const isPoc = cmp.get('v.isPoc');
		const isCantActivte = cmp.get('v.CantActivte');
        var actions = [];
        var activate = {
            'label': 'Activate',
            'iconName': 'utility:check',
            'name': 'changeState'
        };
        var deactivate = {
            'label': 'Deactivate',
            'iconName': 'utility:clear',
            'name': 'changeState'
        };
        var enableAdmin = {
            'label': 'Enable Admin',
            'iconName': 'utility:approval',
            'name': 'changeAdmin'
        };
        var disableAdmin = {
            'label': 'Disable Admin',
            'iconName': 'utility:clear',
            'name': 'changeAdmin'
        };
        
        // Added by Alex Levchenko on 12/07/2019: Start
        var enableSeeAllCases = {
            'label': 'Allow see all cases',
            'iconName': 'utility:overflow',
            'name': 'changeSeeAllCases'            
        };
        
        var disableSeeAllCases = {
            'label': 'Disable see all cases',
            'iconName': 'utility:clear',
            'name': 'changeSeeAllCases'            
        };
        // Added by Alex Levchenko on 12/07/2019: End
        
        //Added by Michal Havshush 24/07/19 : start
        var resetPassword = {
            'label': 'Reset Password',
            'iconName': 'utility:check',
            'name': 'executeResetPassword'            
        };
        //Added by Michal Havshush 24/07/19 : end

		//Added by Rafa 12/06/22 : start
        var activatePocUser = {
            'label': 'Activate POC User',
            'iconName': 'utility:check',
            'name': 'activeState'            
        };
        //Added by Rafa 12/06/22 : end
		//Added by Rafa 19/06/22 : start
        var pocExtensionTime = {
            'label': 'Extension POC',
            'iconName': 'utility:check',
            'name': 'extensionPoc'            
        };
        //Added by Rafa 19/06/22 : end
        
        if(  (row.userStatus == 'Pending Approval') || (row.requestStatus == 'Pending') ) {
            activate['disabled'] = 'true'
            enableAdmin['disabled'] = 'true'
            disableAdmin['disabled'] = 'true'
            resetPassword['disabled'] = 'true'//added by MichalH 24/07
            disableSeeAllCases['disabled'] = 'true'
            enableSeeAllCases['disabled'] = 'true'
            activatePocUser['disabled'] = 'true'//added by Rafa 14/06/22
            pocExtensionTime['disabled'] = 'true'//added by Rafa 22/06/22
            if (row.lastPendingRequestType == "Remove admin") {
                // deactivate['disabled'] = 'false'    
            } else {
                deactivate['disabled'] = 'true'
            }
        }
        let accountType = cmp.get("v.accountType");
        let accountStatus = cmp.get("v.accountStatus");
        if( (row.userIsActive) ) {
            if(row.deactivateEnabled){
				actions.push(deactivate);                
            }
           
            
            if (row.delegatedAdmin && accountType=='End User') {
                actions.push(disableAdmin);
            } else if(accountType=='End User'){
                actions.push(enableAdmin);
            }
            // Added by Alex Levchenko on 12/07/2019: Start
            
            if (row.canSeeAllAccountCases && row.seeAllCasesEnabled) {
                actions.push(disableSeeAllCases);
            } else if(row.seeAllCasesEnabled){
                actions.push(enableSeeAllCases);
            }
            
            // Added by Alex Levchenko on 12/07/2019: End 
            //Added by MichalH on 24/07/19: Start
            if(!row.executeResetPassword)
                actions.push(resetPassword); 
            //Added by MichalH on 24/07/19: End
			//Added by Rafa on 14/06/22: start
			//if(accountStatus == 'Prospect' && accountType=='End User' && row.userStatus == 'Poc Active'){
			if(row.userStatus == 'Poc Active') {
				actions.push(pocExtensionTime);
			}
			//Added by Rafa on 14/06/22: End
        } else {
            if(!isCantActivte) actions.push(activate)
			if(isPoc){
				actions.push(activatePocUser);
			}
        } 
        
        doneCallback(actions);
    },
    
    sortData : function(component,fieldName,sortDirection){
        var data = component.get("v.users");
        //function to return the value stored in the field
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        // to handel number/currency type fields 
        if(fieldName == 'NumberOfEmployees'){ 
            
        }
        else{// to handel text type fields 
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });    
        }
        component.set("v.users",data);
    }
});