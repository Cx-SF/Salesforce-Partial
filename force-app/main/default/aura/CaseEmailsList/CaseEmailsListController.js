({
    doInit: function (component, event, helper) {
		component.set("v.userId", $A.get("$SObjectType.CurrentUser.Id"));
        helper.setTables(component);
        if (component.get("v.recordId")) {
            helper.getCaseEmailMessages(component);
            helper.getCase2EmailAddress(component);
        }
    },

    sendMail: function(component, event, helper) {
        var getAttachList = component.get("v.attachList");
        if((getAttachList||[]).length > 0){
             helper.createFeedItemOnAttachmentsUpload(component);
        }
        if (getAttachList.length > 0) {
            var htmlBody = component.get('v.body');
            var bodyParts = htmlBody.split('&nbsp;&nbsp;&nbsp;');
            var newMessage = bodyParts[0];
            var lastMessage = (bodyParts[1] != null && bodyParts[1] != undefined) ? bodyParts[1] : '';
            newMessage += '</br></br>SF Attachment Notification: The file';
            newMessage += (getAttachList.length > 1) ? 's' : '';
            newMessage += ' below have been uploaded to the case:</br>';
            for (var n = 0; n < getAttachList.length; n++) {
                newMessage += ' - ' + getAttachList[n].name + '</br>';
            }
            newMessage += '</br></br>';
            component.set('v.body', newMessage + lastMessage);
        }
        // when user click on Send button
        // First we get all 3 fields values
        var getEmail = component.get("v.email");
        var getSubject = component.get("v.subject");
        var getbody = component.get("v.body");
        var getCaseId = component.get("v.recordId");
        var getAttachData = component.get("v.attachData");
        var getCC = component.get("v.currentCase.cc__c");

        // check if Email field is Empty or not contains @ so display a alert message
        // otherwise call call and pass the fields value to helper method
        if ($A.util.isEmpty(getEmail) || !getEmail.includes("@")) {
            alert('Please Enter valid Email Address');
        } else if (!$A.util.isEmpty(getCC)) { // REM 25/09
            if(!getCC.includes("@")){
                alert('CC Email Address is not valid. Your administrators has been notified.');
            	helper.sendErrorMail(component,getCaseId,'CC Email Address is not valid.');
            } else {
            	helper.sendHelper(component, getEmail, getSubject, getbody, getCaseId, getAttachList, getAttachData);
            }
        } else {
            helper.sendHelper(component, getEmail, getSubject, getbody, getCaseId, getAttachList, getAttachData);
        }
    },

    // when user click on the close buttton on message popup ,
    // hide the Message box by set the mailStatus attribute to false
    // and clear all values of input fields.
    closeMessage: function(component, event, helper) {
        component.set("v.mailStatus", false);
        component.set("v.subject", null);
        component.set("v.body", null);
        component.set("v.showEmailDetails", false);
        component.set("v.showMailSendPopup", false);

        var emptyArr = [];
        var emptyMap = [];
        component.set("v.attachList",emptyArr);
        component.set("v.attachData", emptyMap);
        component.set("v.attachTotalSize", 0);


        helper.getCase2EmailAddress(component);
        // component.set("v.showMailSend", false);
        // $A.get('e.force:refreshView').fire();
        helper.getCaseEmailMessages(component);
    },

    closeEmailDetails: function (component, event, helper) {       
        component.set("v.showEmailDetails", false);
    },

    closeEmailSendPopup: function (component, event, helper) {
        component.set("v.mailStatus", false);
        component.set("v.subject", null);
        component.set("v.body", null);
        component.set("v.showEmailDetails", false);
        component.set("v.showMailSendPopup", false);

        var emptyArr = [];
        var emptyMap = [];
        component.set("v.attachData", emptyMap);
        component.set("v.attachTotalSize", 0);         
        component.set("v.showMailSendPopup", false);
        var docIdList = [];
        var attachList = component.get("v.attachList");
        for (var i = 0; i < attachList.length; i++) {
            var fileObj = attachList[i];
            if (fileObj.documentId) {
                docIdList.push(fileObj.documentId);
            }
        }
        if(docIdList.length>0){
            helper.deleteAttachments(component,docIdList,[]);
        } else {
            component.set("v.attachList", []);
        }
        
    },

    handleUploadFinished: function (component, event, helper) {
        var attachList = component.get("v.attachList");
        var uploadedFiles = event.getParam("files");
        for (var n=0;n<uploadedFiles.length;n++){
            var fileObj = {};
            fileObj.documentId = uploadedFiles[n].documentId;
            fileObj.name = uploadedFiles[n].name;
            attachList.push(fileObj);
        }
        component.set("v.attachList", attachList);
        /*helper.createFeedItemOnAttachmentsUpload(component);
        if (attachList.length > 0) {
            var htmlBody = component.get('v.body');
            var bodyParts = htmlBody.split('&nbsp;&nbsp;&nbsp;');
            var newMessage = bodyParts[0];
            var lastMessage = (bodyParts[1] != null && bodyParts[1] != undefined) ? bodyParts[1] : '';
            newMessage += '</br></br>A new ';
            newMessage += (attachList.length > 1) ? 'files were ' : 'file was ';
            newMessage += 'uploaded and can be seen inside the case:</br>';
            for (var n = 0; n < uploadedFiles.length; n++) {
                newMessage += ' - ' + uploadedFiles[n].name + '</br>';
            }
            newMessage += '</br></br>';
            component.set('v.body', newMessage + lastMessage);
        }*/
    },
    
    handleFilesUpload : function (component, event, helper) {
        var files = event.getSource().get("v.files");
        var attachList = component.get("v.attachList");
        var attachData = component.get("v.attachData");
        var attachTotalSize = component.get("v.attachTotalSize");
        var attachTotalSizeTmp = attachTotalSize;
        if (attachData == null) {
            attachData = {};
        }
        
        console.log(JSON.parse(JSON.stringify(attachData)));
        
        for (var i = 0; i < files.length; i++) {
            var file = files[i];
            attachTotalSizeTmp = Number(attachTotalSizeTmp) + Number(file.size);
            if (attachTotalSizeTmp > 3000000) {
                var toastInfo = {
                    'title': 'Error',
                    'message': 'Your total attachments size (' + Math.round((attachTotalSizeTmp/1024/1024)*100)/100 + 'Mb) exceeded the limit of 3Mb',
                    'duration' : 3,
                    'variant': 'error'
                };
                component.find('notifLib').showToast(toastInfo);
                return;
            }
        }
        for (var i = 0; i < files.length; i++) {
            (function(i) {
                var file = files[i];
                attachTotalSize = Number(attachTotalSize) + Number(file.size);
                var reader = new FileReader();
                reader.onload = $A.getCallback(function() {
                    try {
                        var fileContents = reader.result;
                        var base64 = 'base64,';
                        var dataStart = fileContents.indexOf(base64) + base64.length;
                        fileContents = fileContents.substring(dataStart);
                        var fileObj = {};
                        var fileData = {};
                        fileObj.fileId = helper.makeId(30);
                        fileObj.name = file.name + ' (' + Math.round(file.size/1024) + ' KB)';
                        fileObj.size = file.size;
                        fileData[file.name] = fileContents;
                        attachData[fileObj.fileId] = fileData;
                        attachList.push(fileObj);
                        component.set("v.attachList", attachList);
                        component.set("v.attachData", attachData);
                        component.set("v.attachTotalSize", attachTotalSize);
                    } catch (e) {
                        console.error(e);
                    }
                    //console.log(attachData);
                });
                reader.readAsDataURL(file);                
            })(i); 
        }
    },
    
    deleteAttachment : function (component, event, helper) {
        var fileIdToDelete = event.getSource().get("v.value");
        
 		var attachList = component.get("v.attachList");
        
        for (var i = 0; i < attachList.length; i++) {
            var fileObj = attachList[i];
            if (fileObj.documentId == fileIdToDelete) {
                attachList.splice(i, 1);
                break;
            }
        }
        helper.deleteAttachments(component,[fileIdToDelete],attachList);
        
    },

    handleReplyClick: function (component, event, helper) {
        // component.set("v.showMailSend", true);
		//console.log ('handleReplyClick');
        var caseEmailMessages = component.get("v.emails");
        var currentCase = component.get("v.currentCase");
        if (caseEmailMessages.length > 0) {
            console.log ('handleReplyClick - caseEmailMessages > 0');
            var lastEmail = caseEmailMessages[0];
            component.set("v.lastEmail",lastEmail);
            var htmlBody;

            if (lastEmail.HtmlBody === undefined) {
                htmlBody = lastEmail.TextBody;
            }else {
                htmlBody = lastEmail.HtmlBody;
            }

            //console.log(JSON.stringify(lastEmail));
            var createdDate = lastEmail.CreatedDate;
            createdDate = createdDate.replace("T"," ");
            createdDate = createdDate.replace(".000Z","");

            // Do not remove &nbsp;&nbsp;&nbsp; from body - it used as separator between new message and last response
            htmlBody = "<b></br>&nbsp;&nbsp;&nbsp;</br>" + createdDate + ", " + lastEmail.FromName + " wrote:</b></br>" + htmlBody;
            component.set("v.body", htmlBody);

            //var currentCase = component.get("v.currentCase");
            //var subject = currentCase.Subject;
            //subject = subject.replace("Sandbox:", "");
            //subject = subject.replace("Sandbox", "");

            //var refThreadId = component.get("v.currentCase.Email_Thread_Id__c");

            //subject = subject.replace("["+refThreadId+"]", "");
            //subject = subject.replace(refThreadId, "");
            //component.set("v.subject", currentCase.Subject);
            component.set("v.subject", lastEmail.Subject);
        } else {
        	//console.log ('handleReplyClick - caseEmailMessages < 0');
            //console.log(JSON.parse(JSON.stringify(component.get("v.currentCase"))));
            component.set("v.subject", '[#' + currentCase.CaseNumber + '] - ' + currentCase.Subject);    
            //component.set ("v.subject", currentCase.CaseNumber);    
            //console.log (component.get("v.subject"));
        }     
        component.set("v.showMailSendPopup", true);
        //console.log ('handleReplyClick - v.showMailSendPopup = true')
    },

    handleCcClick: function (component, event, helper) {
        component.set('v.isOpen', true);
        var flow = component.find("CCflow");
        var inputVariables = [{ name : "Case_Id",  type: "String", value: component.get("v.recordId")}];
        flow.startFlow("Customer_Community_Manage_CC",inputVariables);
    },
   
    closeFlowModal : function(component, event, helper) {
    	component.set("v.isOpen", false);
        $A.get('e.force:refreshView').fire();
    },

    closeModalOnFinish : function(component, event, helper) {
                             if(event.getParam('status') === "FINISHED") {
                             component.set("v.isOpen", false);                  
        }
    },

    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        switch (action.name) {

            case 'show_details':

                if (row.HtmlBody === undefined){
                    row.HtmlBody = row.TextBody;
                }
                var currentEmailBody = row.HtmlBody;
                component.set("v.currentEmailBody",currentEmailBody);
                component.set("v.currentEmailBodyBackup",currentEmailBody);

                var currentEmailSubject = row.Subject;
                component.set("v.currentEmailSubject",currentEmailSubject);

                component.set("v.currentEmail", row);
                component.set("v.showEmailDetails", true);
                break;
        }
    },
    handleTabRefreshed: function (component, event, helper) {

        helper.getCaseEmailMessages(component);

    }/*,
    richTextGetMessageBack: function (component, event, helper) {
        component.set("v.currentEmailBody",component.get("v.currentEmailBodyBackup"));
    }*/
});