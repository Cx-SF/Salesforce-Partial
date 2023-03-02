({
    doInit : function(component, event, helper) {
        //component.set("v.autosuggestOptionsFiltered", component.get("v.autosuggestOptions"));
	},
    
    onchange : function(component, event, helper) {
        helper.fieldChanged(component, event.getSource().get('v.value')) ;
               
         ////////////////////////////////////////////
               if(component.get('v.label') == 'Product area' && component.get('v.layoutMode') == 'NEW'){  
                   var apiValue = event.getSource().get('v.value');
                   if(apiValue == 'Lesson'){
                       apiValue = 'Lessons';
                   }
                  localStorage.setItem('productArea',localStorage.getItem('recordTypeName').substring(0,localStorage.getItem('recordTypeName').length - 3) + '_' + apiValue.replace("_&_","_") + '__c');    
                  localStorage.setItem('subProductArea',null);
                  console.log('Product Area Changed : ', localStorage.getItem('productArea'));                     
                  console.log('Sub Product Area : ', localStorage.getItem('subProductArea')); 
                   
                   
                   var apiForKnowledgeSearchList = JSON.parse(localStorage.getItem('apiForKnowledgeSearchList'));                   
                    for(var i = 0;i < apiForKnowledgeSearchList.length; i++){
                        console.log('test - ' + localStorage.getItem('recordTypeName').substring(0,localStorage.getItem('recordTypeName').length - 3) + '_' + apiValue  + '__c' + ' == ',apiForKnowledgeSearchList[i].Product_Area_API__c); 
                        if(localStorage.getItem('recordTypeName').substring(0,localStorage.getItem('recordTypeName').length - 3) + '_' + apiValue  + '__c'  ==  apiForKnowledgeSearchList[i].Product_Area_API__c){                          
                            localStorage.setItem('productArea',apiForKnowledgeSearchList[i].Product_Area_DC_API__c);
                            console.log('product Area API Converted To : ', localStorage.getItem('productArea')); 
                            
                        }
                    }
                  }
        
          /////////////////////////////////////////////
	},
    
    setRenderProperty : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            var name = event.getParam("name");
            var isRendered = event.getParam("isRendered");
            if (component.get("v.name") == name) {
                component.set("v.isRendered", isRendered);
            }
        }
    },
    
    setRequiredProperty : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            var name = event.getParam("name");
            var isRequired = event.getParam("isRequired");
            if (component.get("v.name") == name) {
                component.set("v.required", isRequired);
                //component.set("v.disabled", !isRequired);
            }
        }
    },
    
    setDisabledProperty : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            var name = event.getParam("name");
            var isDisabled = event.getParam("isDisabled");
            if (component.get("v.name") == name) {
                component.set("v.disabled", isDisabled);
            }
        }
    },
    
    handleError : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            if (component.get("v.name") == event.getParam("name")) {
                component.set("v.hasError", event.getParam("hasError"));
                component.set("v.errorText", event.getParam("errorText"));
            }
        }
    },
    
    setFieldValue : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            var name = event.getParam("name");
            var value = event.getParam("value");
            if (component.get("v.name") == name) {
                component.set("v.value", value);
                var field = component.find('dynamicLayoutInputField');
                if (field != undefined && field != null) {
                    var isAutosuggest = component.get("v.useAutosuggest");
                    if (component.get("v.useAutosuggest")) {
                        var autosuggestOptions = component.get("v.autosuggestOptions");
                        for (var i = 0; i < autosuggestOptions.length; i++) {
                            if (value == autosuggestOptions[i].value) {
                                value = autosuggestOptions[i].label;
                            }
                        }
                    }
                    field.set("v.value", value);                                 
                }
            }
        }
    },
    
    clearAutosuggest : function(component, event, helper) {
        component.find('dynamicLayoutInputField').set('v.value', null);
        helper.fieldChanged(component, null);
        helper.hideAutosuggestOptions(component);
    },
    
    autosuggestShowAllValues : function(component, event, helper) {
        if (component.get('v.autosuggestOptionsOpened')) {
            component.find('dynamicLayoutInputField').blur();
            helper.hideAutosuggestOptions(component);
        } else {
            component.set("v.autosuggestOptionsFiltered", component.get("v.autosuggestOptions"));
            component.find('dynamicLayoutInputField').focus();
            helper.showAutosuggestOptions(component);
        }
    },
    
    autosuggestOnBlur : function(component, event, helper) {  
        setTimeout(function() {
            component.find('dynamicLayoutInputField').set('v.placeholder', '--None--');
            var autosuggestOptionsRn = component.find('autosuggestOptionsRn');
            if ($A.util.hasClass(autosuggestOptionsRn, 'slds-show')) {
                var value = component.get("v.value");
                var label = null;
                var autosuggestOptions = component.get("v.autosuggestOptions");
                for (var i = 0; i < autosuggestOptions.length; i++) {
                    if (value == autosuggestOptions[i].value) {
                        label = autosuggestOptions[i].label;
                    }
                }
                component.find('dynamicLayoutInputField').set('v.value', label);
                helper.hideAutosuggestOptions(component);
                component.set("v.autosuggestOptionsFiltered", component.get("v.autosuggestOptions"));
            }
        }, 200);
    },
    
    autosuggestOnFocus : function(component, event, helper) {  
        component.find('dynamicLayoutInputField').set('v.placeholder', '');
    },
    
    autosuggestOptionSelected : function(component, event, helper) {
        var value = event.target.dataset.value;
        var label = event.target.dataset.label;
        if (value == '--None--') value = null;
        component.find('dynamicLayoutInputField').set('v.value', label);
        //helper.fieldChanged(component, event);
        helper.fieldChanged(component, value);
        helper.hideAutosuggestOptions(component);
       
    },
    
    autosuggestOnChange : function(component, event, helper) {
        var value = component.find('dynamicLayoutInputField').get('v.value');
        value = value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        var searchRegExp = new RegExp(value, 'i');
        var autosuggestOptionsFiltered = [];
        if (value != '') {
            autosuggestOptionsFiltered.push({value: null, label: '--None--'});
            var autosuggestOptions = component.get("v.autosuggestOptions");
            for (var i = 0; i < autosuggestOptions.length; i++) {
                if (searchRegExp.test(autosuggestOptions[i].label) || value == '\\*') {
                    autosuggestOptionsFiltered.push(autosuggestOptions[i]);
                }
            }
        } else {
            autosuggestOptionsFiltered = [];
            autosuggestOptionsFiltered.push({value: null, label: '--None--'});
        }
        component.set("v.autosuggestOptionsFiltered", autosuggestOptionsFiltered);
        helper.showAutosuggestOptions(component);
    },
    
    setAutosuggestOptions : function(component, event, helper) {
        if (component.get("v.parentId") == event.getParam("parentId")) {
            var isAutosuggest = component.get('v.useAutosuggest');
            if (isAutosuggest) {
                var name = event.getParam("name");
                if (component.get("v.name") == name) {
                    var autosuggestOptions = event.getParam("autosuggestOptions");
                    component.set("v.autosuggestOptions", autosuggestOptions);
                    var field = component.find('dynamicLayoutInputField');
                    if (field != undefined && field != null) {
                        var value = component.find('dynamicLayoutInputField').get('v.value');
                        if (value != null && value != '' && !autosuggestOptions.includes(value)) {
                            component.find('dynamicLayoutInputField').set('v.value', null);
                            //helper.fieldChanged(component, event);
                            helper.fieldChanged(component, null);
                        }
                    }
                }
            }
        }
    },
    
    replaceFieldValue : function(component, event, helper) {
        helper.replaceFieldValue(component, event.getSource().get("v.name"));
    },
    
    getValueFromLwc : function(component, event, helper) {		
        helper.fieldChanged(component, event.getParam('value')) ;
        console.log('Label',component.get('v.label'));
        console.log('LWC value',event.getParam('value'));
        var el = document.getElementsByTagName('c-knowledge-search'); 
        if(el[el.length -1] != undefined){
            var ul = el[el.length -1].getElementsByTagName('ul')[0]; 
            if(ul != undefined){
               ul.style.display = 'block'; 
            }
        }
        
	}
    
})