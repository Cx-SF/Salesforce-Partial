({
	doInit : function(component, event, helper) {
		helper.getMetadata(component);
        helper.initArticleResultsTable(component); 
        //////////////////////////////
        helper.getManagedTopics(component);
	},
    
    onChange : function(component, event, helper) {
		helper.handleOnChange(component);
	},
    
    createNewCase : function (component, event, helper) {
        component.set('v.isRecordTypeSelectionAction', true);
        var recordTypes = component.get('v.recordTypes');        
        //////////////////////////////////////////////////////////////
         console.log('recordTypeName in NewCaseWizard',localStorage.getItem('recordTypeName'));                
        var currentParam = getCurrentParam().toLowerCase();
         console.log('recordTypeName after',localStorage.getItem('recordTypeName'));  
        console.log('currentParam',currentParam); 
        
        if(localStorage.getItem('ifArticle') === 'true' || localStorage.getItem('ifDownloadCenter') === 'true' || localStorage.getItem('ifCases') === 'true'){
            console.log('Need To Select Product');
            return;
        }else{           
                for(var i = 0; i < recordTypes.length ;i++){       
               console.log(localStorage.getItem('recordTypeName').includes(recordTypes[i].label));
               if(currentParam.includes(recordTypes[i].label.toLowerCase())){
                component.set('v.isRecordTypeSelectionAction', false);
                console.log(recordTypes[i].label.toLowerCase());
                console.log(recordTypes[i].value.toLowerCase());
				component.set('v.defaultRecordType', recordTypes[i].value);
                helper.handleNextActionFromCommunity(component, recordTypes[i].value);
                break;
               }else if(localStorage.getItem('recordTypeName').includes(recordTypes[i].label)){
                component.set('v.isRecordTypeSelectionAction', false);
                console.log(recordTypes[i].label.toLowerCase());
                console.log(recordTypes[i].value.toLowerCase());
                helper.handleNextActionFromCommunity(component,recordTypes[i].value);
                break;
               }
              }                            
        }
       
                
        function getCurrentParam(){
        var currentUrl = window.location.href;         
        currentUrl = currentUrl.split('/'); 
        var index = currentUrl.length - 1;   
        //var productNameArrey = ['CxSAST','CxOSA','CxIAST','Codebashing','CxSCA'];   
        var productNameArrey = JSON.parse(localStorage.getItem('productNameArrey'));    
       var currentParam = currentUrl[index].split('?')[0];
            if(currentUrl[index- 1] == 'article'){
                localStorage.setItem('ifArticle',true); 
            }else{
                localStorage.setItem('ifArticle',false); 
            } 
            
             if(currentParam == 'download-page'){                 
                localStorage.setItem('ifDownloadCenter',true);                  
            }else{
                localStorage.setItem('ifDownloadCenter',false); 
            }  
              
            if(currentParam == 'view-my-comm-cases' || currentParam == 'all-my-comm-cases' || currentParam == 'my-account-cases'){                 
                localStorage.setItem('ifCases',true);                                                          
            }else{
                localStorage.setItem('ifCases',false); 
            }  
            if(component.get('v.recordTypes').length == 0){               
                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    "mode": 'sticky',
                    "type": 'warning',
                    "message": 'Please login before open a ticket!'
                });
                toast.fire();
                setTimeout(function(){ 
                    var base_url = window.location.origin;
                    console.log('base_url',base_url);
                    window.location.replace(base_url +"/secur/logout.jsp?retUrl=" + base_url + "/CheckmarxCustomerServiceCommunity/s/login/?ec=302&startURL=%2FCheckmarxCustomerServiceCommunity%2Fs%2F");
                }, 1000); 
                 
            }
            
            console.log('productNameArrey.length' ,productNameArrey.length);
           
        for(var i = 0;i < productNameArrey.length;i++){      
        currentParam = currentParam.replace('-',' ');
        console.log('productNameArrey ' + i ,productNameArrey[i]);
        console.log(currentParam +'=='+ productNameArrey[i].topic.name.toLowerCase());
        console.log(currentParam.includes(productNameArrey[i].topic.name.toLowerCase()));
        if(currentParam.includes(productNameArrey[i].topic.name.toLowerCase())){
            localStorage.setItem('productIndex',i);
            localStorage.setItem('recordTypeName',currentParam + '__c');
          }                     
        }
        return currentParam; 
       }    
    },
    
    onTypeSelectionCancel : function(component, event, helper) {
        component.set('v.isRecordTypeSelectionAction', false);
    },
    
    onTypeSelectionNext : function(component, event, helper) {
       	helper.handleNextAction(component);
    },
    
    onRowAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        if (action.name == 'articleResolvedIssueAction') {
            helper.handleArticleResolvedIssueAction(component, row.Id);
        }
        if (action.name == 'articleOpenAction') {
            helper.handleOpenArticle(component, row);
        }
    },
    
    articleResolvedIssue : function(component, event, helper) {
        var articleId = component.get('v.openedArticleId');
        helper.handleCloseArticle(component);
        helper.handleArticleResolvedIssueAction(component, articleId);
    },
    
    closeArticle : function(component, event, helper) {
        helper.handleCloseArticle(component);
    },
	// Handle Account Selection
	closeAccountSelectionModal : function (cmp){
		cmp.set('v.downloadModalOpen', false);
        cmp.set('v.selected_tenant_obj', null);
		cmp.set('v.selected_account', null);
	},
    partnerAccountSelected: function(cmp, evt, hlp){
        let selectedValue = evt.getParam('value');
        console.log('NCCW - Selected partner Account: ' + selectedValue);
        let tenantFilter = ' AND Account__c = \'' + selectedValue + '\'';
        cmp.set('v.selected_tenant_obj', null);
        cmp.set('v.tenant_list_filter', tenantFilter);
    },
    selectAccountAndContinue : function(cmp, evt, hlp){
		var available_accounts = cmp.get('v.available_accounts');
		var selected_account = cmp.get('v.selected_account');
        var selected_tenant_obj = cmp.get('v.selected_tenant_obj');
		var runningUser = cmp.get('v.runningUser');
		var canCreate = true;
		var combo = cmp.find('AccountCombo');
        var tenantLookup = cmp.find('tenantlookup');
        var defaultValues = {};

		if (hlp.isEmpty(selected_account)){
			$A.util.addClass(combo, "error-box");
            canCreate = false;
		} else {
            $A.util.removeClass(combo, "error-box");
        }

        if (!hlp.isEmpty(tenantLookup)){
            if (hlp.isEmpty(selected_tenant_obj) || hlp.isEmpty(selected_tenant_obj.val)){
                $A.util.addClass(tenantLookup, "error-box");
                canCreate = false;
            } else {
                $A.util.removeClass(tenantLookup, "error-box");
                cmp.set('v.selected_tenant', selected_tenant_obj.val);
                defaultValues['Account_Tenant_List__c'] = selected_tenant_obj.val;
            }
        }
                
        if (canCreate) {
			console.log('Can create Case');

			var userType = cmp.get('v.userType');
			var recordTypeId = cmp.get('v.defaultRecordType');
			var searchKeyWord = cmp.find('searchInputField').get('v.value');

			if (selected_account != runningUser.AccountId){
                defaultValues['AccountId'] = selected_account;// New b
				defaultValues['Customer_Account_ID__c'] = selected_account;
			}
			
			if (searchKeyWord != null && searchKeyWord != '') {
				defaultValues['Subject'] = searchKeyWord.substring(0, 80);
			}
			console.log('NCCW - Default values: ' + JSON.stringify(defaultValues));
			
			cmp.set('v.isRecordTypeSelectionAction', false);
			
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
			cmp.set('v.downloadModalOpen', false);
			if (!hlp.isEmpty(available_accounts) && Array.isArray(available_accounts) && available_accounts.length > 1){
				console.log('Reseting');
				cmp.set('v.selected_account', null);
			}
            cmp.set('v.selected_tenant_obj', null);
            cmp.set('v.selected_tenant', null);
		}
	},
	// .Handle Account Selection

    // Handle tenant selection
    closeTenantSelectionModal : function (cmp){
		cmp.set('v.isSelectTenantREQ', false);
        cmp.set('v.selected_tenant_obj', null);
		cmp.set('v.selected_tenant', null);
	},
    selectTenantListAndContinue : function(cmp, evt, hlp){
        var canCreate = true;
        var defaultValues = {};
        var selected_tenant_obj = cmp.get('v.selected_tenant_obj');
        var tenantLookup = cmp.find('tenantlookup');
        var recordTypeId = cmp.get('v.defaultRecordType');
        var searchKeyWord = cmp.find('searchInputField').get('v.value');

        if (hlp.isEmpty(selected_tenant_obj) || hlp.isEmpty(selected_tenant_obj.val)){
			$A.util.addClass(tenantLookup, "error-box");
            canCreate = false;
		} else {
            $A.util.removeClass(tenantLookup, "error-box");
            cmp.set('v.selected_tenant', selected_tenant_obj.val);
            defaultValues['Account_Tenant_List__c'] = selected_tenant_obj.val;
        }

        if (canCreate) {
			console.log('Can create Case');
			
			if (!hlp.isEmpty(searchKeyWord)) {
				defaultValues['Subject'] = searchKeyWord.substring(0, 80);
			}

			console.log('NCCW - Default values: ' + JSON.stringify(defaultValues));
			cmp.set('v.isRecordTypeSelectionAction', false);
			
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
			cmp.set('v.isSelectTenantREQ', false);
            cmp.set('v.selected_tenant_obj', null);
            cmp.set('v.selected_tenant', null);

		}

    }
    // .Handle tenant selection
})