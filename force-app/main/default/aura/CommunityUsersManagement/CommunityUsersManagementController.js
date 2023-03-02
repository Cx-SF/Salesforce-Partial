({
    init: function (component, event, helper) {
        component.set('v.showContactCreatePopup',false);
        component.set('v.showResultsPopup',false);
		event.row

		helper.initData(component);
        helper.setTables(component);

        

        component.find("contactRecordCreator").getNewRecord(
            "Contact", // sObject type (entityAPIName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newContact");
                var error = component.get("v.newContactError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }
                else {
                    //console.log("Record template initialized: " + rec.apiName);
                }
            })
        );

        helper.initJobStatus(component);
    },
    reload : function (component, event, helper) {
        // component.set("v.isLoading", true);
        helper.initData(component);
        // component.set("v.isLoading", false);
    },
    updateSelectedUsers : function (component, event, helper) {
        let selectedRows = event.getParam('selectedRows');
        component.set('v.selectedUsers', selectedRows);
    },
    handleUserChangeActions: function (component, event, helper) {
        //console.log('event '+JSON.stringify(event));

        let row = event.getParam('row');
        let rows = component.get('v.users');
        let rowIndex ; 
        //Added by Hananel Cohen 29.1.20
        rows.some(function(currentRow,index){
            if(currentRow.contactId == row.contactId){
                rowIndex=index;
                return true;
            }
        });
		
        let action = event.getParam('action').name;
		console.log('Rafa - actionName: ' + action);
		console.log('Rafa - getParam action: ' + JSON.stringify(event.getParam('action')));
		console.log('Rafa - getParam row: ' + JSON.stringify(event.getParam('row')));

        switch (action) { 

            case 'changeState':
                if(  (row.userStatus !== 'Pending Approval') || (row.requestStatus !== 'Pending') ) {
                    row.actionDisabled = false;
                    row.changeUserState = true;
                    row.styleUserState = 'YellowColor';
                    //row.userIsActive = !row.userIsActive;
                    if(!row.userIsActive) {
                        row.userStatus = 'Active';
                    } else {
                        row.userStatus = 'Inactive';
                    }
					rows[rowIndex] = row;
                    component.set('v.users', rows);
                } else {
                    helper.showToasts(component,'Error','Irrelevant action!','User In Pending Status or request in Pending status.');
                }
                break;

			case 'activeState':
				console.log('Rafa - in active State');
                if(  (row.userStatus !== 'Pending Approval') || (row.requestStatus !== 'Pending') ) {
                    row.actionDisabled = false;
                    row.changeUserState = true;
					row.pocUser = true;
                    row.styleUserState = 'YellowColor';
                    //row.userIsActive = !row.userIsActive;
                    row.userStatus = 'Poc Active';
					
					rows[rowIndex] = row;
                    component.set('v.users', rows);
                } else {
                    helper.showToasts(component,'Error','Irrelevant action!','User In Pending Status or request in Pending status.');
                }
                break;
			
			case 'extensionPoc':
				console.log('Rafa - in extensionPoc');
                if(  (row.userStatus !== 'Pending Approval') || (row.requestStatus !== 'Pending') ) {
                    row.actionDisabled = false;
                    row.changeUserState = false;
					row.pocUser = true;
					row.pocExtension = true;
                    row.styleUserState = 'YellowColor';
                    //row.userIsActive = !row.userIsActive;
                    row.userStatus = 'Poc Active';
					
					rows[rowIndex] = row;
                    component.set('v.users', rows);
                } else {
                    helper.showToasts(component,'Error','Irrelevant action!','User In Pending Status or request in Pending status.');
                }
                break;

            case 'changeAdmin':
                if( (row.userStatus === 'Active') &&
                    (row.requestStatus !== 'Pending') && (row.userIsActive === true) ) {
                    row.actionDisabled = false;
                    row.changeDelegatedAdmin = true;
                    row.styleAdmin = 'YellowColor';
                    //row.delegatedAdmin = !row.delegatedAdmin;
                    if(!row.delegatedAdmin){
                        row.delegatedAdminText = 'Yes';
                    } else {
                        row.delegatedAdminText = 'No';
                    }
                    rows[rowIndex] = row;
                    component.set('v.users', rows);
                } else {
                    helper.showToasts(component,'Error','Irrelevant action!','User is not active.');
                }
                break;

            case 'save_status':
                // If user status or admin role changed - submit request
                if (row.changeUserState || row.changeDelegatedAdmin || row.pocExtension) {
                    if (row.requestStatus !== 'Pending') {
                        row.requestStatus = '';
                        rows[rowIndex] = row;
                    	component.set('v.users', rows);
                        helper.userManagementAction(component, action, [rows[rowIndex]]);
                        helper.initData(component);
                    } else {
                        helper.showToasts(component,'Error','Irrelevant action!','User Request In Pending or Error Status.');
                    }
                }
                // if SeeAllCases flag changed - update user directly
                if (row.changeSeeAllAccountCases) {
					component.set("v.isLoading", true);
                    var cAction = component.get('c.setCanSeeAllCasesFlag');
                    cAction.setParams({
                        contactId: row.contactId,
                        canSeeAllCases: row.canSeeAllAccountCases
                    });
                    cAction.setCallback(this, function(a) {
                        var state = a.getState();
                        if (state == 'SUCCESS') {
                             helper.showToasts(component,'success','Request created!','');
                            helper.initData(component);
                        } else {
                            var message = 'Unknown error';
                            var errors = a.getError();
                            if (errors && Array.isArray(errors) && errors.length > 0) {
                               helper.showToasts(component,'Error','Unknown error',errors[0]);
                            }
                            console.error(message);
                        }
                        component.set("v.isLoading", false);
                    });
                    $A.enqueueAction(cAction);
                }
                break;

            case 'view_requests':
                let contactId = row.contactId;
                helper.getRequests(component,contactId);
                component.set('v.showResultsPopup',true);
                break;
            
            case 'contactEmail' :
                //Copy to clipBoard
                /* Get the text field */
                var copyText = document.getElementById("hiddenTextForClipboard");
                copyText.value = row.contactEmail;

                /* Select the text field */
                copyText.select();

                /* Copy the text inside the text field */
                document.execCommand("copy");

                // /* Alert the copied text */
                // alert("Copied the text: " + copyText.value);
                
            // Added by Alex Levchenko on 12/07/2019: Start 
            
            case 'changeSeeAllCases' :
                row.actionDisabled = false;
                row.changeSeeAllAccountCases = true;
                row.styleSeeAllCases = 'YellowColor';
                row.canSeeAllAccountCases = !row.canSeeAllAccountCases;
                if (row.canSeeAllAccountCases) {
                    row.canSeeAllAccountCasesText = 'Yes';
                } else {
                    row.canSeeAllAccountCasesText = 'No';
                }
                rows[rowIndex] = row;
                component.set('v.users', rows); 
            break;
            // Added by Alex Levchenko on 12/07/2019: End 
            
            //Added by MichalH 24/07/19: Start
            case 'executeResetPassword':
                if (row.requestStatus !== 'Pending') {
                        row.requestStatus = '';
                }
                row.styleRestPassword='YellowColor';
                if(!row.executeResetPassword){
                row.executeResetPassword=true; 
                helper.userManagementAction(component, action, [rows[rowIndex]]);
                }
                rows[rowIndex] = row;
                component.set('v.users', rows);
             
            //Added by MichalH 24/07/19: End  

            
        }

    },
    handleUserActions: function (component, event, helper) {
        //first check action from buttons
        let action = event.getSource().get("v.name");
        let rows = [];
        if (action !== undefined) {
            rows = component.get("v.selectedUsers");

        // next check row action
        } else {
            action = event.getParam('action').name;
            rows = [event.getParam('row')];
        }

        // console.log('row action -> ' + action);
        // console.log('rows -> ' + JSON.stringify(rows));
        helper.userManagementAction(component, action, rows);

    },
    handleAddNewContact: function (component, event, helper) {
        component.set('v.showContactCreatePopup',true);
    },
    closeAddNewContactPopup: function (component, event, helper){
        component.set('v.showContactCreatePopup',false);
    },
    closeRequestsPopup: function (component, event, helper){
        component.set('v.showResultsPopup',false);
    },
    accountSelect: function (component, event, helper) {
        let acc = component.find('selectAccount').get('v.value');
        component.set('v.recordId', acc);
        //console.log('Account Id '+acc);
        helper.initData(component);
    },
    countrySelect: function (component, event, helper) {
        let cc = component.find('selectCountry').get('v.value');
        component.set('v.selectedCountryCode', cc);
        let countries = component.get('v.countries');
        let isAvalible = false;
        for (var i = countries.length - 1; i >= 0; i--) {
            if ( countries[i].value == cc ) {
                if(countries[i].states.length != 0 ) {
                    component.set('v.isCountryStatesAvalible', true);
                    component.set('v.countriesStates', countries[i].states);
                    isAvalible = true;
                    break;
                }
            }
        }
        if (!isAvalible) {
            component.set('v.isCountryStatesAvalible', false);
            component.set('v.countriesStates', []);                
        }
    },
    stateSelect: function (component, event, helper) {
        let selState = component.find('selectCountryState'); 
        let cc = selState.get('v.value');
        component.set('v.selectedCountryState', cc);
        //console.log('selectedCountryCode '+cc);
    },
    handleAdminSelect: function (component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        if (selectedMenuItemValue == 'Run Jobs') {
            helper.runJobs(component);
        }
        if (selectedMenuItemValue == 'Abort Jobs') {
            helper.abortJobs(component);
        }
        helper.initJobStatus(component);

    },
    closePopupIsteadToast: function (component, event, helper) {
        helper.initData(component);
        component.set("v.showPopupIsteadToast",false);
        component.set("v.showPopupIsteadToastContact",false);
        component.set("v.selectedCountryCode",'');
        component.set("v.selectedCountryState",null);
        component.set('v.isCountryStatesAvalible', false);
        component.set('v.countriesStates', []);  
    },

    handleSaveContact: function(component, event, helper) {
        debugger;
        if(helper.validateContactForm(component)) {
            component.set("v.isLoading", true);
			
            //component.set("v.simpleNewContact.AccountId", component.get("v.recordId")); // remove account as it is not possible fo portal users
            component.set("v.simpleNewContact.Community_Account__c", component.get("v.recordId"));
            var isStandard = component.get("v.isStandard"); 
            var userType = component.get("v.userType");
            console.log(userType); 
            console.log(isStandard); 
            if (isStandard) {
                component.set("v.simpleNewContact.Community_User_Management_Status__c", 'Active');
            }else {
                component.set("v.simpleNewContact.Community_User_Management_Status__c", 'Pending');
            }
            
            component.set("v.simpleNewContact.MailingCountryCode", component.get("v.selectedCountryCode"));
            component.set("v.simpleNewContact.MailingStateCode", component.get("v.selectedCountryState"));
            component.set("v.simpleNewContact.Contact_Roles__c", "Customer Support");
            // console.log(JSON.parse(JSON.stringify(component.get("v.simpleNewContact"))));
            // console.log(component.get("v.simpleNewContact"));
            // console.log(component.get("v.selectedCountryState"));
            // if (component.get("v.isCountryStatesAvalible")) {
            // }
            component.set("v.newContact.fields.Community_Account__c.value", component.get("v.account"));
            component.set("v.newContact.fields.Community_Account_Id__c.value", component.get("v.recordId"));
            component.set("v.newContact.fields.LastName.value", component.get("v.simpleNewContact.LastName"));
            component.set("v.newContact.fields.FirstName.value", component.get("v.simpleNewContact.FirstName"));
            component.set("v.newContact.fields.Email.value", component.get("v.simpleNewContact.Email"));
            component.set("v.newContact.fields.MailingCountryCode.value", component.get("v.selectedCountryCode"));
            component.set("v.newContact.fields.MailingStateCode.value", component.get("v.selectedCountryState"));
            let newCon = component.get('v.newContact');
            newCon.id = null;
            component.set('v.newContact',newCon);
            component.find("contactRecordCreator").saveRecord(function(saveResult) {
                debugger;
                var state = saveResult.state;
                var err = saveResult.error;
                if (saveResult.state === "SUCCESS") {
                    // record is saved successfully
                    component.set('v.showContactCreatePopup',false);
                    component.set("v.selectedCountryCode",'');
                    component.set("v.selectedCountryState",null);
                    component.set('v.isCountryStatesAvalible', false);
                    component.set('v.simpleNewContact', {});
                    component.set('v.countriesStates', []);  

                    let newContact = component.get('v.newContact');
                    let newContactId = newContact.id;
                    let accountId = component.get('v.recordId');
                    helper.createUserRequestForNewContact(component,newContactId,accountId);
                    helper.showToasts(component,'success','New contact was added.','');
                    var evt = $A.get('e.force:refreshView');
                    if (typeof evt !== 'undefined')
                    {
                        evt.fire();
                    }

                } else if (saveResult.state === "INCOMPLETE") {
                    // handle the incomplete state
                    console.log("User is offline, device doesn't support drafts.");
                } else if (saveResult.state === "ERROR") {
                    // handle the error state
                    console.log('Problem saving contact, error: ' + JSON.stringify(saveResult.error));
                    helper.showToasts(component,'error','Problem saving contact!',JSON.stringify(saveResult.error[0].message),true);

                } else {
                    console.log('Unknown problem, state: ' + saveResult.state +
                        ', error: ' + JSON.stringify(saveResult.error));
                }
                component.set("v.isLoading", false); 
                
            });
        }
    },
        //Method gets called by onsort action,
    handleSort : function(component,event,helper){
        //Returns the field which has to be sorted
        var sortBy = event.getParam("fieldName");
        //returns the direction of sorting like asc or desc
        var sortDirection = event.getParam("sortDirection");
        //Set the sortBy and SortDirection attributes
        component.set("v.sortBy",sortBy);
        component.set("v.sortDirection",sortDirection);
        // call sortData helper function
        helper.sortData(component,sortBy,sortDirection);
    }
});