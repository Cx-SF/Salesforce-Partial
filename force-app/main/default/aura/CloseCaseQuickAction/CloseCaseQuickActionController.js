({
    doInit: function(component, event, helper) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.getStatus');
        action.setParams({ 
            caseId : recordId
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
                if (a.getReturnValue() == 'Closed') {
                    component.set('v.isNotClosed', false);
                }
            }
            else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                console.error(message);
            }
        }); 
        $A.enqueueAction(action);
    },
    changeStatusCaseToClose : function(component, event, helper) {
        var caseRecord = component.get("v.caseRecord");
        var recordError=component.get("v.recordError");
        var errorMsg, mTitle, mType;
        if(caseRecord!=null){
            if(caseRecord.Status ==="Closed" ){
                var toastParams = { title: "Notice", message: "This case is already closed", type: "Error"};
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams(toastParams);
                toastEvent.fire();
            }
            else{
                var action = component.get('c.updateStatus');
                action.setParams({ 
                    caseRecord : caseRecord
                });
                action.setCallback(this, function(a) {
                    var state = a.getState();
                    if (state === "SUCCESS" || state === "DRAFT") {
                        errorMsg = "Operation completed successfully.";
                        mTitle = "Success!";
                        mType = "Success";
                        component.set("v.isNotClosed", false);
                    }
                    else{
                        if (state === "INCOMPLETE"){
                            errorMsg = "User is offline, device doesn't support drafts.";
                        }
                        if (state === "ERROR"){   
                            errorMsg = "Problem saving record, error: " + JSON.stringify(state);
                            alert('error '+errorMsg);
                        }
                        if (state != "ERROR" && state != "INCOMPLETE"){
                            errorMsg = "Unknown problem, state: "  + state + ", error: " + JSON.stringify(state);
                        }
                        mTitle = "Error";
                        mType = "Error";
                    }
                    var toastParams = { title: mTitle, message: errorMsg, type: mType};
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams(toastParams);
                    toastEvent.fire(); $A.get("e.force:closeQuickAction").fire();
                }); 
                $A.enqueueAction(action);
            }
        }
        $A.get("e.force:closeQuickAction").fire();      
    }
})