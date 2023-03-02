({
	itemSelected : function(component, event, helper) {
        var target = event.target;   
        var changeEvent = component.getEvent("lookupEvent");
        var SelIndex = helper.getIndexFrmParent(target,helper,"data-selectedIndex");  
        if(SelIndex){
            var serverResult = component.get("v.server_result");
            var selItem = serverResult[SelIndex];
            if(selItem.val){
               component.set("v.selItem",selItem);
               component.set("v.last_ServerResult",serverResult);
               changeEvent.setParams({"selectedValue" : selItem });
               changeEvent.fire();
            } 
            component.set("v.server_result",null); 
        } 
	}, 
    serverCall : function(component, event, helper) {  
        var target = event.target;  
        var searchText = target.value; 
        var minimumKeys = component.get('v.minimumKeys');
        var last_SearchText = component.get("v.last_SearchText");
        //Escape button pressed 
        if (event.keyCode == 27 || !searchText.trim()) { 
            helper.clearSelection(component, event, helper);
        }else if(searchText.trim() != last_SearchText  && (/\s+$/.test(searchText) || (minimumKeys >  0 && searchText!=null && typeof(searchText) == "string" && searchText.length >= minimumKeys)) ){ 
            //Save server call, if last text not changed
            //Search only when space character entered
         
            var objectName = component.get("v.objectName");
            var field_API_text = component.get("v.field_API_text");
            var field_API_val = component.get("v.field_API_val");
            var field_API_search = component.get("v.field_API_search");
            var query_literal = component.get("v.query_literal");
            var field_API_text_to_add = component.get("v.field_API_text_to_add");
			var multi_API_text_to_add = component.get("v.multi_API_text_to_add");
            var limit = component.get("v.limit");
			var additional_restrictions = component.get("v.additional_restrictions");
			var restrictedList = component.get("v.additional_restrictions_list");

			console.log('restrictedList: ' + JSON.stringify(restrictedList));
            
            var action = component.get('c.searchDB');
            action.setStorable();
            
            action.setParams({
                objectName : objectName,
                fld_API_Text : field_API_text,
                fld_API_Val : field_API_val,
                lim : limit, 
                fld_API_Search : field_API_search,
                searchText : searchText,
                query_literal : query_literal,
                field_API_text_to_add : field_API_text_to_add,
				multi_API_text_to_add : multi_API_text_to_add,
				additionalMode : additional_restrictions,
				additionalList : restrictedList
            });
    
            action.setCallback(this,function(a){
                this.handleResponse(a,component,helper);
            });
            
            component.set("v.last_SearchText",searchText.trim());
            console.log('Server call made');
            $A.enqueueAction(action); 
        }else if(searchText && last_SearchText && searchText.trim() == last_SearchText.trim()){ 
            component.set("v.server_result",component.get("v.last_ServerResult"));
            console.log('Server call saved');
        }         
	},
    handleResponse : function (res,component,helper){
        if (res.getState() === 'SUCCESS') {
            var retObj = JSON.parse(res.getReturnValue());
            if(retObj.length <= 0){
                var noResult = JSON.parse('[{"text":"No Results Found"}]');
                component.set("v.server_result",noResult); 
            	component.set("v.last_ServerResult",noResult);
            }else{
                component.set("v.server_result",retObj); 
            	component.set("v.last_ServerResult",retObj);
            }  
        }else if (res.getState() === 'ERROR'){
            var errors = res.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    alert(errors[0].message);
                }
            } 
        }
    },
    getIndexFrmParent : function(target,helper,attributeToFind){
        //User can click on any child element, so traverse till intended parent found
        var SelIndex = target.getAttribute(attributeToFind);
        while(!SelIndex){
            target = target.parentNode ;
			SelIndex = helper.getIndexFrmParent(target,helper,attributeToFind);           
        }
        return SelIndex;
    },
    clearSelection: function(component, event, helper){
        component.set("v.selItem",null);
        component.set("v.server_result",null);
        var changeEvent = component.getEvent("lookupEvent");
        changeEvent.setParams({"selectedValue" : null });
        changeEvent.fire();
    },
	isEmpty: function(obj){
		return (obj == null || obj == 'null' || typeof(obj) == 'undefined' || obj == 'undefined' || obj == '');
	}
})