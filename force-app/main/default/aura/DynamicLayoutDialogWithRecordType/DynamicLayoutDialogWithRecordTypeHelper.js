({
	loadRecordTypes:function (cmp) {
		let action = cmp.get("c.getAvailibleRecordTypes");
		let fromVF = cmp.get("v.fromVF");

        if (cmp.get("v.pageReference") != null) {
            var state = cmp.get("v.pageReference").state;
            if (state != null && typeof(state) != "undefined" && state.inContextOfRef != null && typeof(state.inContextOfRef) != "undefined") {
                var base64Context = state.inContextOfRef;	                
                if (base64Context.startsWith("1\.")) {	            
                    base64Context = base64Context.substring(2);	                   
                }	        
                var addressableContext = JSON.parse(window.atob(base64Context));	        
                if (addressableContext.attributes && addressableContext.attributes.recordId) {
                    var recordId = addressableContext.attributes.recordId;
                    if (recordId.startsWith('001')) {
                        cmp.set('v.AccountId', recordId);
                    }
                }
            }
        }     

        var self = this;
		action.setParams({'sObjectName' : cmp.get("v.sObjectName") , 'fromVF' : fromVF});
		action.setCallback(this, function (response) {
			if (response.getState() == 'SUCCESS') {
				let value = response.getReturnValue();
				console.log(value);
				cmp.set("v.recordTypes", value);
				if(value.length>0){
					cmp.set("v.recordTypeId", value[0].value);
				}
				if (value.length == 1) {
					cmp.set("v.isSingleRecordType", true);
					self.handleNextAction(cmp);
				} else {
					cmp.set("v.isSingleRecordType", false);					
				}
			} else {
				console.log("Error");
			}
		})
		$A.enqueueAction(action);
	},

	handleNextAction : function(cmp) {
	    var recordTypeId = cmp.find('recordTypeRadioSelector').get('v.value');
	    cmp.set("v.recordTypeId", recordTypeId);
	    let accId = cmp.get("v.AccountId");
	    if(recordTypeId) {
	    	var defaultValues = {};
	    	if (accId){
	    		defaultValues['AccountId'] = accId;
	    	}
	        var evt = $A.get("e.c:DynamicLayoutDialogStarter");
	        if (evt) {
	            evt.setParams({
	                "sObjectName": "Case",
	                "recordTypeId": recordTypeId,
	                "layoutMode": "NEW",
	                "defaultValues" : defaultValues
	            });
	            evt.fire();
	        }
	    }
	},

	onTypeSelectionCancel : function(component, event, helper) {
		let fromVF = component.get("v.fromVF");

		if (fromVF) {
			if(window.location.href.includes('retURL')) {
				let search = window.location.search;
				console.log(search);
				let retURL =null;
				if(search !=null && typeof(search) != "undefined" ){
				    search = search.substr(1);
				    let params = search.split('&');
				    for (var i = params.length - 1; i >= 0; i--) {
				       let param = params[i];
				       if (param != null && param != '') {
					       	var paramName = param.split('=')[0];
					       	var paramValue = param.split('=')[1];
				           	if (paramName == 'retURL') {
				           	     retURL = paramValue;
				           	}
				       }
				    }
				    if (retURL){
				    	while (retURL.includes("%2F")) {
					    	retURL = retURL.replace("%2F", '/');
				    	}
						window.location.href = retURL;    
				    } else {
						let sObjectPrefix = component.get("v.sObjectPrefix");
						window.location.href = "/"+sObjectPrefix+'/o';				    	
				    }
				}    
			} else {
				let sObjectPrefix = component.get("v.sObjectPrefix");
				window.location.href = "/"+sObjectPrefix+'/o';
			}
		} else {


			var workspaceAPI = component.find("workspace");
			var self = this;
			workspaceAPI.isConsoleNavigation().then(function(isConsole) {
			    if (isConsole) {
			        workspaceAPI.getFocusedTabInfo().then(function(response) {
			            var focusedTabId = response.tabId;
			            workspaceAPI.closeTab({tabId: focusedTabId});
			        }).catch(function(error) {
			            console.error(error);
			        });
			    } else {
	    			let accId = component.get("v.AccountId");
	    			component.set('v.isOpened', false);
	    	    	if (accId){
	    				var objEvt = $A.get("e.force:navigateToSObject");
	    				objEvt.setParams({
	    				    "recordId": accId
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
			    }
			})
		}
	}
	
})