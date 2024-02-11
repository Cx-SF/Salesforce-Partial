({
    
    getMetadata : function(component) {
        var getMetadataAction = component.get('c.getMetadata');
        getMetadataAction.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
                var result = JSON.parse(a.getReturnValue());
                var userType = result['UserType'];
                var defaultRecordTypeId = result['DefaultRecordTypeId'];
                var generalRecordTypeId = result['GeneralRecordTypeId'];
                var caseDeflectionRecordTypeId = result['CaseDeflectionRecordTypeId'];
                var recordTypesData = (result['RecordTypes'] != null && result['RecordTypes'] != undefined) ? JSON.parse(result['RecordTypes']) : null;
				var runningUser = result['running_user'];
				var isPowerPartner = false;
				if (!this.isEmpty(runningUser) && !this.isEmpty(runningUser.Account)){
					if (runningUser.Account.Type == 'Service Provider (SI)' || runningUser.Account.Type == 'Partner/ Reseller' || runningUser.Account.Type == 'Distributor'){
						isPowerPartner = true;
					}
				}
				component.set('v.isPowerPartner', isPowerPartner);

				if (!this.isEmpty(result.available_accounts)){
					component.set('v.available_accounts', result.available_accounts);
					if (!this.isEmpty(result.available_accounts) && Array.isArray(result.available_accounts) && result.available_accounts.length == 1){
						component.set('v.selected_account', result.available_accounts[0].value);
					}
				}

                /*
                console.log(userType);
                console.log(defaultRecordTypeId);
                console.log(generalRecordTypeId);
                console.log(recordTypesData);
                */
                var recordTypes = [];
                if (recordTypesData != null) {
                    for (var i = 0; i < recordTypesData.length; i++) {
                        var recordType = {};
                        recordType['value'] = recordTypesData[i].Id;
                        recordType['label'] = recordTypesData[i].Name;
                        recordTypes.push(recordType);
                    }
                }
                component.set('v.userType', userType);
				component.set('v.runningUser', result['running_user']);
                component.set('v.defaultRecordType', defaultRecordTypeId);
                component.set('v.generalRecordTypeId', generalRecordTypeId);
                component.set('v.caseDeflectionRecordTypeId', caseDeflectionRecordTypeId);
                component.set('v.recordTypes', recordTypes);
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);
            }
        });
        $A.enqueueAction(getMetadataAction);
    },
    
    initArticleResultsTable : function(component) {
       this.setArticleResultsTableColumns(component);
    },
    
    setArticleResultsTableColumns : function(component) {
        var columns = [
            { 
                label: 'Article Number',
                type: 'button',
                typeAttributes: 
                {
                    variant: 'base',
                    name: 'articleOpenAction',
                    label: {fieldName: 'ArticleNumber'},
                    title: 'Click to open article',
                    class: 'slds-button_link'
                }
            },             
            {
                label: 'Subject',
                fieldName: 'Title',
                type: 'text'
            },
            {
                label: 'Date',
                fieldName: 'LastModifiedDate',
                type: 'date'
            },
            { 
                label: '', 
                fieldName: 'solved', 
                type: 'button',
                sortable: false,
                typeAttributes: 
                {
                    iconName: 'action:approval',
                    name: 'articleResolvedIssueAction',
                    label: 'Resolved my issue',
                    title: 'This article resolved my issue'
                }
            }    
    	];
    	component.set('v.articleColumns', columns);     
	},
    
    fetchArticles : function(component, searchKeyWord) {
        var p = new Promise($A.getCallback(function(resolve, reject) { 
            var getArticlesDataAction = component.get('c.fetchArticles');
            getArticlesDataAction.setParams({ 
                searchKeyWord : searchKeyWord
            });
            getArticlesDataAction.setCallback(this, function(callbackResult) {
                var state = callbackResult.getState();
                if (state == 'SUCCESS') {
                    resolve(callbackResult.getReturnValue());
                } else {
                    console.error(callbackResult.getError()); 
                	reject(callbackResult.getError());
                }
            });                
        	$A.enqueueAction(getArticlesDataAction);           
    	}));            
    	return p;
    },
    
    handleOnChange : function(component) {
        var searchKeyWord = component.find('searchInputField').get('v.value');
        if (searchKeyWord != null & searchKeyWord != '' && searchKeyWord.trim().length >= 3) {
            this.fetchArticles(component, searchKeyWord).then(function(result) {
                component.set('v.articleData', result);
                component.set('v.articleSearchCount', result.length);
                if (result != undefined && result != null && result.length > 0) {
                    component.set('v.hasArticleResult', true);
                } else {
                    component.set('v.hasArticleResult', false);
                }
            });
        } else {
            this.clearArticleResults(component);
        }
    },
    
    clearArticleResults : function(component) {
        var articles = [];
        component.set('v.articleData', articles);
        component.set('v.articleSearchCount', 0);
        component.set('v.hasArticleResult', false);
    },
    
    handleNextAction : function(component) {
		var available_accounts = component.get('v.available_accounts');
		var selected_account = component.get('v.selected_account');
		var canCreate = true;
        var userType = component.get('v.userType');
        var recordTypeId = component.find('recordTypeRadioSelector').get('v.value');
        var searchKeyWord = component.find('searchInputField').get('v.value');
		var isPowerPartner = component.get('v.isPowerPartner');
        var defaultValues = {};
        if (searchKeyWord != null && searchKeyWord != '') {
            defaultValues['Subject'] = searchKeyWord.substring(0, 80);
            //defaultValues['Description'] = searchKeyWord;
        }

		if (isPowerPartner && !this.isEmpty(available_accounts) && Array.isArray(available_accounts) && available_accounts.length > 0 && this.isEmpty(selected_account)){
			component.set('v.downloadModalOpen', true);
			canCreate = false;
		} else if (!this.isEmpty(selected_account)){
			defaultValues['CX_End_Customer__c'] = selected_account;
		}

		if (canCreate){
			component.set('v.isRecordTypeSelectionAction', false);
			/*if (userType == 'Standard') {//(false){//Not work 
				var evt = $A.get("e.force:navigateToComponent");
				evt.setParams({
					componentDef : "c:DynamicLayoutDialog",
					componentAttributes: {
						'sObjectName' : 'Case',
						'recordTypeId' : recordTypeId,
						'layoutMode' : 'NEW',
						'defaultValues' : defaultValues
					}
				});
				evt.fire();
			} else {*/
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
			//}
		}
    },
    
    
    handleNextActionFromCommunity : function(component,value) {
		var isPowerPartner = component.get('v.isPowerPartner');
		var available_accounts = component.get('v.available_accounts');
		var selected_account = component.get('v.selected_account');
		var canCreate = true;

		var userType = component.get('v.userType');
        var recordTypeId = value;
        var searchKeyWord = component.find('searchInputField').get('v.value');
        var defaultValues = {};
        if (searchKeyWord != null && searchKeyWord != '') {
            defaultValues['Subject'] = searchKeyWord.substring(0, 80);
        }

		if (isPowerPartner && !this.isEmpty(available_accounts) && Array.isArray(available_accounts) && available_accounts.length > 0 && this.isEmpty(selected_account)){
			component.set('v.downloadModalOpen', true);
			canCreate = false;
		} else if (!this.isEmpty(selected_account)){
			defaultValues['CX_End_Customer__c'] = selected_account;
		}

		if (canCreate){
			component.set('v.isRecordTypeSelectionAction', false);
			
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
    
    handleArticleResolvedIssueAction : function(component, articleId) {
		this.showProcessingSpinner(component);
        var subject = 'Resolved by knowlege article';
        var description = 'Resolved by knowlege article';
		//var recordTypeId = component.get('v.caseDeflectionRecordTypeId');
        var recordTypeId = component.get('v.generalRecordTypeId');
        var searchKeyWord = component.find('searchInputField').get('v.value');
        if (searchKeyWord != null && searchKeyWord != '') {
            subject = searchKeyWord.substring(0, 80);
        }
        var newCase = {'sobjectType': 'Case'};
        newCase.RecordTypeId = recordTypeId;
        newCase.Subject = subject;
        newCase.Description = description;
        newCase.Status = 'Closed';
        newCase.Origin = 'Community';
        newCase.IsClosedOnCreate = true;
        
        var createNewCaseAction = component.get('c.createNewCaseWithArticle');
        createNewCaseAction.setParams({ 
            newcase : newCase,
            articleId : articleId
        });
        createNewCaseAction.setCallback(this, function(callbackResult) {
            var state = callbackResult.getState();
            if (state == 'SUCCESS') {
                component.find('searchInputField').set('v.value', null);
                component.set('v.articleData', null);
                component.set('v.hasArticleResult', false);
                //console.log('After create case: ' + callbackResult.getReturnValue());
                var toast = $A.get("e.force:showToast");
                toast.setParams({
                    "mode": 'dismissible',
                    "type": 'success',
                    "message": 'Thank you for your feedback!'
                });
                toast.fire();
            } else {
                console.error(callbackResult.getError()); 
            }
            this.hideProcessingSpinner(component);
        });                
        $A.enqueueAction(createNewCaseAction);        
    },
    
    handleOpenArticle : function(component, row) {
        //component.set('v.articleURL', articleURL);
        component.set('v.openedArticleId', row.Id);
        component.set('v.openedArticleNumber', row.ArticleNumber);
        component.set('v.isArticleOpened', true);
    },
    
    handleCloseArticle : function(component) {
        component.set('v.openedArticleId', null);
        component.set('v.openedArticleNumber', null);
        component.set('v.isArticleOpened', false);
    },
    
    showProcessingSpinner : function(component) {
		component.set('v.isProcessingSpinner', true);
    },
    
    hideProcessingSpinner : function(component) {
		component.set('v.isProcessingSpinner', false);
    },
    
      /////////////////////////////////////////// 
    getManagedTopics : function(component) {        
        var productName = component.get("c.getManagedTopics");        
        productName.setCallback(this, function(a) {
            var state = a.getState();            
            if (state == 'SUCCESS') {    
                var productNameArrey = JSON.stringify(a.getReturnValue());                
                console.log('product Name Arrey',productNameArrey);
                localStorage.setItem('productNameArrey',productNameArrey);
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);               
                self.showToast(null, "error", "Error", 'Cannot check for Products Names: ' + message, component);
            }
        });
        $A.enqueueAction(productName); 
    },
	isEmpty : function(obj){
		return ((obj == null || obj == '' || obj == 'undefined' || typeof(obj) == 'undefined') && obj !== 0 && obj !== false);
	}
})