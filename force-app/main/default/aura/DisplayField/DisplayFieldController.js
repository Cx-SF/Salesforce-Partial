({
	doInit : function(component, event, helper) {
        var apiName = component.get("v.apiName");
        var val = component.get("v.record." + apiName);
        component.set("v.fieldValue", val);
	}
})