({
	doInit : function(component, event, helper) {
		var recordId = component.get('v.recordId');
        var action = component.get('c.getStatus');
        action.setParams({ 
            caseId : recordId
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
                if (a.getReturnValue() == 'Closed') {
                    component.set('v.isFollowUpAllowed', true);
                }
            } else {
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
    
    followUpCase : function(component, event, helper) {
        var recordId = component.get('v.recordId');
        var action = component.get('c.cloneCase');
        action.setParams({ 
            caseId : recordId
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
                var newCase = a.getReturnValue();

                console.log(newCase);

                component.set('v.sObjectName', 'Case');
                component.set('v.layoutMode', 'NEW');
                component.set('v.recordTypeId', newCase.RecordTypeId);
                component.set('v.defaultValues', newCase);
                component.set('v.isOpened', true);
                
                console.log('isOpened = ' + component.get('v.isOpened'));

            } else {
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
    
    dynamicLayoutDialogStarter : function(component, event, helper) {
        component.set('v.sObjectName', event.getParam("sObjectName"));
        component.set('v.recordId', event.getParam("recordId"));
        component.set('v.recordTypeId', event.getParam("recordTypeId"));
        component.set('v.layoutMode', event.getParam("layoutMode"));
        component.set('v.defaultValues', event.getParam("defaultValues"));
        component.set('v.isOpened', true);
	},
    
    dynamicLayoutDialogStoper : function(component, event, helper) {
        //component.set('v.sObjectName', event.getParam("sObjectName"));
        //component.set('v.recordId', event.getParam("recordId"));
        //component.set('v.recordTypeId', event.getParam("recordTypeId"));
        //component.set('v.layoutMode', event.getParam("layoutMode"));
        component.set('v.isOpened', false);
	}
    
})