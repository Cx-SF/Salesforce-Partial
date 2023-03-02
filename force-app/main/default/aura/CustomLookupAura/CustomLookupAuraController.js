({
	doInit : function(component, event, helper) {
		var minimumKeys = component.get('v.minimumKeys');
		if ( minimumKeys >  0 ) {
			var placeholder = component.get('v.placeholder');
			component.set('v.placeholder',placeholder+' or fill at least '+minimumKeys+' charachters');
		}
	}, 
	itemSelected : function(component, event, helper) {
		helper.itemSelected(component, event, helper);
	}, 
    serverCall :  function(component, event, helper) {
		helper.serverCall(component, event, helper);
	},
    clearSelection : function(component, event, helper){
		event.preventDefault();
		if (!component.get('v.disabled')){
			helper.clearSelection(component, event, helper);
		}
    } 
})