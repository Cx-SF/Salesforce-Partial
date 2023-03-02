({
    doInit: function (component, event, helper) {
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