({
	loadInitialData : function(cmp, evt){
		console.log('Loading initial data');
		var recId = cmp.get('v.recordId');
		var action = cmp.get("c.getInitialData");
		if (!this.isEmpty(recId)) {
			action.setParams({ "objId" : recId });
		}
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
				var isPowerPartner = false;
				//console.log('storeResponse: ' + JSON.stringify(storeResponse));
                if (!this.isEmpty(storeResponse)){
					if (!this.isEmpty(storeResponse.running_user)){
						cmp.set('v.runningUser', storeResponse.running_user);
						if (!this.isEmpty(storeResponse.running_user.Account)){
							if (!storeResponse.running_user.Account.CX_Block_Account_from_Download_Center__c) {
								cmp.set('v.blockPage', false);
							}
							isPowerPartner = (storeResponse.running_user.Account.Type == 'Distributor' || storeResponse.running_user.Account.Type == 'Service Provider (SI)' || storeResponse.running_user.Account.Type == 'Partner/ Reseller');
						} else {
							cmp.set('v.blockPage', false);
						}
						cmp.set('v.isPowerPartner', isPowerPartner);
					}
					if (!this.isEmpty(storeResponse.availableProducts)){
						var availableProducts = JSON.parse(storeResponse.availableProducts);
						cmp.set('v.availableProducts', availableProducts);

						var productMapping = {};
						for (var i = 0; i < availableProducts.length; i++){
							productMapping[availableProducts[i].pName] = availableProducts[i];
						}
						cmp.set('v.productMapping', productMapping);
					}
					if (!this.isEmpty(storeResponse.available_accounts)){
						cmp.set('v.available_accounts', storeResponse.available_accounts);
						if (!this.isEmpty(storeResponse.available_accounts) && Array.isArray(storeResponse.available_accounts) && storeResponse.available_accounts.length == 1){
							if (isPowerPartner) cmp.set('v.selected_account', storeResponse.available_accounts[0].value);
						}
					}
                }
            } else {
				let errors = response.getError();
				console.log('Error loading products: ' + errors[0].message);
			}
            let spinner = cmp.find("cmspinner"); 
			$A.util.addClass(spinner, "slds-hide");
        });
        let spinner = cmp.find("cmspinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.enqueueAction(action);
	},
	getProductVersions : function(cmp, evt){
		console.log('Loading Product versions');
		var product = cmp.get('v.selectedProduct');

		var action = cmp.get("c.getVersionsAndPlugIns");
		action.setParams({ "product" : product });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
				//console.log('storeResponse: ' + JSON.stringify(storeResponse));
                if (!this.isEmpty(storeResponse)){
					if (!this.isEmpty(storeResponse.versions)){
						cmp.set('v.loadedProductVersions', storeResponse.versions);
						cmp.set('v.productSelected', true);
					}
					if (!this.isEmpty(storeResponse.plugins)){
						cmp.set('v.loadedPlugins', storeResponse.plugins);
						cmp.set('v.pluginTabsLoaded', true);
					}
					if (!this.isEmpty(storeResponse.services)){
						cmp.set('v.loadedServices', storeResponse.services);
						cmp.set('v.servicesLoaded', true);
					}					
                }
            } else {
				let errors = response.getError();
				console.log('Error loading product versions: ' + errors[0].message);
			}
            var spinner = cmp.find("cmspinner");
			$A.util.addClass(spinner, "slds-hide");
        });
        var spinner = cmp.find("cmspinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.enqueueAction(action);
	},
	openUrl : function(url){
		let exp = /[\/\/\.]/gm;
		let wName = url.replace(exp, '_');
		console.log('Target window: ' + wName);
		console.log('Opening: ' + url);
		window.open(url, wName, '_blank');
	},
	getURL : function(cmp, evt, dlObj){
		console.log('dlObj: ' + JSON.stringify(dlObj));

		var action = cmp.get('c.getDLURL');
		action.setParams({ 'dlObj' : dlObj });
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
				console.log('Got the file: '  + storeResponse);
				try{
					if (storeResponse.toLowerCase().indexOf('could not') > -1 || storeResponse.toLowerCase().indexOf('error') > -1){
						cmp.find('notifLib').showToast({
							"variant" : "error",
							"title": "Something went wrong",
							"message": "The File you requested could not be found."
						});
					} else {
						var element = document.createElement('a');
						element.setAttribute('href',  storeResponse);
						element.style.display = 'none';
						document.body.appendChild(element);
						element.click();
						document.body.removeChild(element);
					}
				} catch(err) {
					console.log('Error pushing the file: ' + err);
				}
            } else {
				let errors = response.getError();
				console.log('Error loading products: ' + errors[0].message);
			}
            let spinner = cmp.find("cmspinner"); 
			$A.util.addClass(spinner, "slds-hide");
        });
        let spinner = cmp.find("cmspinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.enqueueAction(action);
	},
	getObjectById : function(cmp, idToFind){
		var theObject = cmp.find(idToFind);
		if (!this.isEmpty(theObject) && !this.isEmpty(theObject.length) && theObject.length > 0) theObject = theObject[0];
		return theObject;
	},
	isEmpty : function (obj){
		return (obj == null || typeof(obj) == 'undefined' || obj == 'undefined' || obj == '');
	}
})