({
    
    doInit : function(component, event, helper) { 
        console.log('IN doInit Dynamic cmp');
        helper.validateLayoutState(component);
        helper.initComponentAttributes(component);
        helper.renderComponent(component);
              
         /////////////////////////////////////////// 
         // get Parent Product Area Custom Metadata
        var parentProductsArea = component.get("c.getParentProductAreaCustomMetadata");        
        parentProductsArea.setCallback(this, function(a) {
            var state = a.getState();            
            if (state == 'SUCCESS') {    
                var parentProductAreaList = JSON.stringify(a.getReturnValue());                
                console.log('parent Product Area List',parentProductAreaList);
                localStorage.setItem('parentProductAreaList',parentProductAreaList);
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);               
                self.showToast(null, "error", "Error", 'Cannot check for RecordTypeId: ' + message, component);
            }
        });
        $A.enqueueAction(parentProductsArea);   
        
        
         // get Api For Knowledge Search Custom Metadata
        var apiForKnowledgeSearch = component.get("c.getApiForKnowledgeSearchCustomMetadata");        
        apiForKnowledgeSearch.setCallback(this, function(a) {
            var state = a.getState();            
            if (state == 'SUCCESS') {    
                var apiForKnowledgeSearchList = JSON.stringify(a.getReturnValue());                
                console.log('api For Knowledge Search  List',apiForKnowledgeSearchList);
                localStorage.setItem('apiForKnowledgeSearchList',apiForKnowledgeSearchList);
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);               
                self.showToast(null, "error", "Error", 'Cannot check for RecordTypeId: ' + message, component);
            }
        });
        $A.enqueueAction(apiForKnowledgeSearch);   
        ////////////////////////////////////////////////////////
    },
    
    handleRecordLoad : function(component, event, helper) {
        helper.handleRecordLoad(component, event);
    },
    
    fieldChanged : function(component, event, helper) {        
		helper.handleFieldChanged(component, event);
    },
    
    replaceFieldValue : function(component, event, helper) {        
		helper.handleReplaceFieldValue(component, event);
    },
    
    onTypeSelectionCancel : function(component, event, helper) {
        component.set('v.isRecordTypeSelectionAction', false);
    },
    
    onTypeSelectionNext : function(component, event, helper) {
       	helper.handleReplaceRecordTypeIdNextAction(component, event);
    },
    
    handleSubmit : function(component, event, helper) {
        event.preventDefault();
        helper.saveDialog(component, event);
    },
    
    handleOnSuccess : function(component, event, helper) {
        helper.formSubmitSuccess(component, event);
    },
    
    handleOnError : function(component, event, helper) {
    	helper.formSubmitError(component, event);
    },
    
    editRecord : function(component, event, helper) {
        helper.handleEditRecord(component, event);
    },
    
    cancelDialog : function(component, event, helper) {
        helper.closeDialog(component);
    },
    
    closePopupIsteadToast : function (component, event, helper) {
        component.set("v.showPopupIsteadToast",false);
        component.set('v.isLayoutdisabled', false);
    },
    
    attachmantsUploadFinished : function (component, event, helper) {
        helper.handleAttachmentsUploaded(component, event);        
    },
    
    deleteAttachment : function (component, event, helper) {
        var documentId = event.getSource().get('v.name');
        var deleteAction = component.get('c.deleteContentAttachment');
        deleteAction.setParams({ 
            docId : documentId
        });
        deleteAction.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
				var attachmentsUploaded = component.get('v.attachmentsUploaded');
                for (var i = 0; i < attachmentsUploaded.length; i++) {
                    var attachment = attachmentsUploaded[i];
                    if (attachment.documentId == documentId) {
                        attachmentsUploaded.splice(i, 1);
                    }
                }
                component.set('v.attachmentsUploaded', attachmentsUploaded);  
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);
                helper.showToast(null, "error", "Error", message, component);
            }
        });
        $A.enqueueAction(deleteAction);
    },
    
    skipAttachments : function (component, event, helper) {
        helper.handleSkipAttachments(component, event);
    },
    
    closeDialogAfterSave : function(component, event, helper) {
        helper.closeDialogAfterSave(component, event);
    },
})