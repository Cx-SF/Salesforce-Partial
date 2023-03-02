({
    makeId : function (length) {
        var result = '';
        var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        var charactersLength = characters.length;
        for ( var i = 0; i < length; i++ ) {
            result += characters.charAt(Math.floor(Math.random() * charactersLength));
        }
        return result;
    },

    getCaseEmailMessages : function (component) {
        var caseId = component.get("v.recordId");
        var getCaseEmailMessages = component.get("c.getCaseEmailMessages");
        getCaseEmailMessages.setParam("caseId", caseId);
        getCaseEmailMessages.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var response = response.getReturnValue();
                component.set("v.emails", response.emailMessageList);
                component.set("v.threadId", response.refId);
                //console.log(JSON.stringify(caseEmailMessages[0].CreatedDate));
        }
        });
        $A.enqueueAction(getCaseEmailMessages);
    },

    getCase2EmailAddress : function (component) {
        // var caseId = component.get("v.recordId");
        var getCase2EmailAddress = component.get("c.getCase2EmailAddress");
        getCase2EmailAddress.setParam("localPart", "checkmarxsupport");
        getCase2EmailAddress.setCallback(this, function (response) {
            console.log(response.getState());
            console.log(response.getError());
            if (response.getState() === "SUCCESS") {
                var case2EmailAddress = response.getReturnValue();
                component.set("v.email", case2EmailAddress);
                
                console.log('email = ' + case2EmailAddress);
                
            }
        });
        $A.enqueueAction(getCase2EmailAddress);
    },

    createFeedItemOnAttachmentsUpload : function(component) {
        console.log('In createFeedItemOnAttachmentsUpload()');
        var action = component.get("c.createFeedItemOnAttachmentsUpload");
        action.setParams({
            'caseId' : component.get("v.recordId"),
            'attachData' : component.get("v.attachList")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var errMsg = response.getReturnValue();
            if (state != "SUCCESS") {
                var errors = response.getError();
                var message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
                let toastInfo = {
                    'title': 'Error',
                    'message': message,
                    'duration' : 5,
                    'variant': 'error'
                };
                component.find('notifLib').showToast(toastInfo);
            }
        });        
        $A.enqueueAction(action);
    },

    sendHelper: function(component, getEmail, getSubject, getbody, getCaseId, getAttachList, getAttachData) {
        // call the server side controller method
        var action = component.get("c.sendMailMethod");
        // set the 3 params to sendMailMethod method

        console.log(JSON.parse(JSON.stringify(component.get("v.currentCase"))));
        
        var refThreadId = component.get("v.threadId");
        var cc = component.get("v.currentCase.cc__c");
        
        console.log('refThreadId = ' + refThreadId);
        console.log('cc = ' + cc);
        console.log('mMail = ' + getEmail);
        console.log('mSubject = ' + getSubject);
        console.log('mbody = ' + getbody);
        
        if(refThreadId && getbody && ! (getbody.trim().endsWith(refThreadId) || getbody.trim().endsWith(refThreadId+'</p>') )){
            getbody +='\n'+ refThreadId;
        }
        
        //getbody += '\n \n \n ' + "["+refThreadId+"]";

        action.setParams({
            'mMail': getEmail,
            'cc': cc,
            'mSubject': getSubject,
            'mbody': getbody,
            'caseId': getCaseId,
            // 'attachList': getAttachList,
            'attachData': getAttachData
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var errMsg = response.getReturnValue();
            if (state === "SUCCESS" && !errMsg) {
                var storeResponse = response.getReturnValue();
                // if state of server response is comes "SUCCESS",
                // display the success message box by set mailStatus attribute to true
                // component.set("v.mailStatus", true);

                // if state of server response is comes "SUCCESS",
                // display the success message box by set mailStatus attribute to true
                
                component.set("v.mailStatus", false);
                component.set("v.subject", null);
                component.set("v.body", null);
                component.set("v.showEmailDetails", false);
                component.set("v.showMailSendPopup", false);

                var emptyArr = [];
                var emptyMap = {};
                component.set("v.attachList", emptyArr);
                component.set("v.attachData", emptyMap);
                component.set("v.attachTotalSize", 0);

                let toastInfo = {
                    'title': 'Email Status',
                    'message': "Email Sent successfully to Case " + component.get("{!v.currentCase.CaseNumber}"),
                    'duration' : 3,
                    'variant': 'success'
                };
                component.find('notifLib').showToast(toastInfo);
                
                self.getCase2EmailAddress(component);
                self.getCaseEmailMessages(component);

            } else {
                var errors = response.getError();
                var message = 'Unknown error';
                // Retrieve the error message sent by the server
                 if(errMsg){
                    message = errMsg
                    if(message.includes('ccAddresses'))
                        message='CC Addresses are invalid. Please change it to include only valid emails and symbols by clicking the "Manage CC Recipients" button.';
                }
                else if(errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                    if(message.includes('ccAddresses'))
                        message='CC Addresses are invalid. Please change it to include only valid emails and symbols by clicking the "Manage CC Recipients" button.';
                }

                console.error(message);
                let toastInfo = {
                    'title': 'Error',
                    'message': message,
                    'duration' : 5,
                    'variant': 'error',
                    'mode': 'sticky'
                };
                component.find('notifLib').showToast(toastInfo);
            }

        });
        $A.enqueueAction(action);
    },
    sendErrorMail: function (component,caseId,msg) {
        var action = component.get("c.sendMailOnError");
        action.setParams({
            'message': msg,
            'caseId': caseId
        });
        $A.enqueueAction(action);
    },
    setTables: function (component) {
        var actions = [
            {label: 'Show details', name: 'show_details'}
        ];

        component.set("v.emailsColumns", [
            //{label: 'Email Id', fieldName: 'Id', type: 'text'},
            //{label: 'Case Id', fieldName: 'ParentId', type: 'text'},
            //{label: 'Case Number', fieldName: 'Parent.CaseNumber', type: 'text'},
            {
                label: 'Date', fieldName: 'CreatedDate', type: 'date', typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                    hour: "2-digit",
                    minute: "2-digit"
                },
                cellAttributes : { style : "vertical-align: top;"},
                initialWidth: 130
            },
            {label: 'Sender Name', fieldName: 'FromName', type: 'text', initialWidth: 130,cellAttributes : { style : "vertical-align: top;"}},
            //{label: 'Sender Email', fieldName: 'FromAddress', type: 'text'},
            {label: 'Subject', fieldName: 'Subject', type: 'text', initialWidth: 300,cellAttributes : { style : "vertical-align: top;"}},
            {label: 'Description', fieldName: 'TextBody', type: 'text', cellAttributes : { style : "max-height:120px; text-overflow: clip;", class:"descCell"}},
            {label: 'Attachments', fieldName: 'HasAttachment', type: 'boolean', initialWidth: 100},
            {type: 'action', typeAttributes: {rowActions: actions}}
        ]);
    },
    
    deleteAttachments: function(component,attachments,attachList){
    	var deleteAtt = component.get("c.deleteAtt");
        deleteAtt.setParam("docIdList", attachments);
        deleteAtt.setCallback(this, function (response) {
            if (response.getState() === "SUCCESS") {
                var response = response.getReturnValue();
                component.set("v.attachList", attachList);
            }
            else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error while deleting attachment!",
                    "type": "error",
                    //"message": "Account Widget was created."
                });
                toastEvent.fire(); 
            }
        });
        $A.enqueueAction(deleteAtt);
    }
});