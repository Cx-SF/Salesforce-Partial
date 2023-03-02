({
	    
    fieldChanged : function(component, newValue) {
        var value = newValue;
        if (component.get('v.isRendered')) {
            if (value == '' && component.get('v.type') == 'BOOLEAN') value = false;
            else if (value == '') value = null;
            component.set("v.value", value);
			var name = component.get('v.name');
            // In case of autosuggest - re-render dummy hidden picklist to refesh its value
            if (component.get('v.useAutosuggest')) {
                component.set('v.dummyPicklistRenderFlag', false);
                component.set('v.dummyPicklistRenderFlag', true);
            }
            var evt = $A.get('e.c:FieldChangedEvent');
            evt.setParams({
                "parentId" : component.get('v.parentId'),
                "name" : name,
                "value" : value
            });
            evt.fire();
        }
    },    
    
    replaceFieldValue : function(component, fieldName) {
        var evt = $A.get('e.c:replaceFieldValue');
        evt.setParams({
            "fieldName" :  fieldName
        });
        evt.fire();
    },
    
    hideAutosuggestOptions : function(component) {
        var autosuggestOptionsRn = component.find('autosuggestOptionsRn');
        $A.util.removeClass(autosuggestOptionsRn, 'slds-show');
        $A.util.addClass(autosuggestOptionsRn, 'slds-hide');
        component.set('v.autosuggestOptionsOpened', false); 
    },
    
    showAutosuggestOptions : function(component) {
        var autosuggestOptionsRn = component.find('autosuggestOptionsRn');
        $A.util.removeClass(autosuggestOptionsRn, 'slds-hide');
        $A.util.addClass(autosuggestOptionsRn, 'slds-show');
        component.set('v.autosuggestOptionsOpened', true); 
    }
    
})