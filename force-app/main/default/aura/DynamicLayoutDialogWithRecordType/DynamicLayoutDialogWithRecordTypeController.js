({
	init : function function_name(component, event, helper) {
		helper.loadRecordTypes(component);
		if (component.get("v.fromVF")) {
			component.set("v.caller", "VISUALFORCE");
		}

	},

	onTypeSelectionCancel : function(component, event, helper) {
		helper.onTypeSelectionCancel(component, event, helper);
	},
	
	onTypeSelectionNext : function(component, event, helper) {
	   	helper.handleNextAction(component);
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
    	let accId = component.get("v.AccountId");
        component.set('v.isOpened', false);
        let fromVF = component.get("v.fromVF");
        if(!fromVF){   	
	    	if (accId){
				var objEvt = $A.get("e.force:navigateToSObject");
				objEvt.setParams({
				    "recordId": accId,
                    isredirect: true
				});
				objEvt.fire();
	    	}
	    	else{
				var homeEvt = $A.get("e.force:navigateToObjectHome");
				homeEvt.setParams({
				    "scope": component.get('v.sObjectName')
				});
				homeEvt.fire();
			}	
        }else {
        	let isSingleRecordType = component.get("v.isSingleRecordType");
        	if (isSingleRecordType) {
        		helper.onTypeSelectionCancel(component,event,helper);
        	}
        }
	}
})