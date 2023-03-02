({

    validateLayoutState: function(component) {
        var self = this;
        var validateTimer = setTimeout(function() {
            var errorMsg = 'Sorry, but looks like something went wrong. Please check for any errors in your browser console.';
            if (component.get('v.layoutMode') != 'VIEW') {
                if (!component.get('v.recordLoaded')) {
                    component.set('v.isLayoutValid', false);
                    component.set('v.isInitialized', true);
                    component.set('v.recordLoaded', true);
                    self.hideProcessingSpinner(component);
                    //self.showToast(null, "error", "Oops!", errorMsg, component);
                }   
            } else {
                if (!component.get('v.isInitialized')) {
                    component.set('v.isLayoutValid', false);
                    component.set('v.isInitialized', true);
                    self.hideProcessingSpinner(component);
                    //self.showToast(null, "error", "Oops!", errorMsg, component);
                } 
            }
        }, 10000);
        component.set('v.validateTimer', validateTimer);
    },
    
    makeId : function (length) {
        var result = '';
        var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        var charactersLength = characters.length;
        for ( var i = 0; i < length; i++ ) {
            result += characters.charAt(Math.floor(Math.random() * charactersLength));
        }
        return result;
    },
    
    initComponentAttributes : function(component) {
        component.set('v.componentId', this.makeId(50));
        var sObjectName = component.get('v.sObjectName');
        component.set('v.objectIconName', sObjectName.toLowerCase());
        var recordId = component.get('v.recordId');
        if (recordId != null && typeof(recordId) != 'undefined') {
            component.set('v.currentRecordId', recordId);
        }
        var recordTypeId = component.get('v.recordTypeId');
        console.log(JSON.parse(JSON.stringify(component.get("v.pageReference"))));
        var layoutMode = component.get('v.layoutMode');
        var defaultValues = component.get('v.defaultValues');
        if (layoutMode == null || typeof(layoutMode) == "undefined") {
            if (component.get("v.pageReference") == null) {
                layoutMode = 'VIEW';
                component.set('v.uiMode', 'INLINE');
            } else {
            	layoutMode = component.get("v.pageReference").attributes.actionName.toUpperCase();
            }
            component.set('v.layoutMode', layoutMode);
        }
		if (recordTypeId == null || typeof(recordTypeId) == "undefined") {
            if (component.get("v.pageReference") == null) {
                recordTypeId = null;
                component.set('v.uiMode', 'INLINE');
            } else {
            	recordTypeId = component.get("v.pageReference").state.recordTypeId;
            }
            component.set('v.recordTypeId', recordTypeId);
            component.set('v.newRecordTypeId', recordTypeId);
        } else {
            if (component.get('v.isChangeRecordType')) {
                if (defaultValues == null) defaultValues = {};
                defaultValues['RecordTypeId'] = recordTypeId;
                component.set('v.defaultValues', defaultValues);
            }
        }    
        if (component.get("v.pageReference") != null) {
            var state = component.get("v.pageReference").state;
            if (state != null && typeof(state) != "undefined" && state.additionalParams != null && typeof(state.additionalParams) != "undefined") {
                var additionalParams = state.additionalParams.split('&');
                for (var i = 0; i < additionalParams.length; i++) {
                    var param = additionalParams[i];
                    if (param != null && param != '') {
                        var paramName = param.split('=')[0];
                        var paramValue = param.split('=')[1];
                        if (paramName == 'def_account_id') {
                            if (defaultValues == null) defaultValues = {};
                            defaultValues['AccountId'] = paramValue;
                        }
                    }
                }
                component.set('v.defaultValues', defaultValues);
            }
        }
        if (component.get("v.caller") == "VISUALFORCE") {
            let search = window.location.search;
            console.log(search);
            if(search !=null && typeof(search) != "undefined" ){
                search = search.substr(1);
                let params = search.split('&');
                for (var i = params.length - 1; i >= 0; i--) {
                   let param = params[i];
                   if (param != null && param != '') {
                       var paramName = param.split('=')[0];
                       var paramValue = param.split('=')[1];
                       if (paramName == 'def_account_id') {
                           if (defaultValues == null) defaultValues = {};
                           defaultValues['AccountId'] = paramValue;
                       }
                       if (paramName == 'retURL') {
                            component.set('v.retURL',paramValue)
                       }
                   }
                }
                component.set('v.defaultValues', defaultValues);
            }    
        }
        if (component.get("v.caller") != "APP" && component.get("v.caller") != "VISUALFORCE") {
            component.set('v.addAttachmentsFlag', true);
        }

        
        console.log('layoutMode = ' + layoutMode);
        console.log('sObjectName = ' + sObjectName);
        console.log('recordTypeId = ' + recordTypeId);
        console.log('recordId = ' + recordId);
        if (defaultValues != null) {
        	console.log(JSON.parse(JSON.stringify(defaultValues)));
        }
        
    },
    
    renderComponent : function(component) {
        var sObjectName = component.get('v.sObjectName');
        var recordId = component.get('v.recordId');
        var recordTypeId = component.get('v.recordTypeId');
        var layoutMode = component.get('v.layoutMode');
        var defaultValues = component.get('v.defaultValues');
        var accountId = (defaultValues != null && defaultValues['AccountId'] != null && defaultValues['AccountId'] != undefined) ? defaultValues['AccountId'] : null;
        var self = this;
        
        var getMetadataAction = component.get('c.getMetadata');
        getMetadataAction.setParams({ 
            sObjectName : sObjectName, 
            recordTypeId : recordTypeId,
            mode : layoutMode,
            recordId : recordId,
            accountId : accountId
        });
        getMetadataAction.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
                console.log('GetReturn Value ' + a.getReturnValue());
                var result = JSON.parse(a.getReturnValue());
                var siteType = result['SiteType'];
                var objectLabel = self.decode(result['ObjectLabel']);
                var recordTypeName = self.decode(result['RecordTypeName']);
                var objectMetadata = JSON.parse(self.decode(result['ObjectFieldsMetadata']));
                var layoutMetadata = JSON.parse(self.decode(result['LayoutMetadata']));
                var picklistValues = JSON.parse(self.decode(result['PicklistValues']));
                var recordTypesData = JSON.parse(self.decode(result['RecordTypes']));
                if (defaultValues != null && defaultValues['AccountId'] != null && defaultValues['AccountId'] != undefined) {
                    defaultValues['ContactId'] = result['ContactId'];
                }
                var recordTypes = [];
                if (recordTypesData != null) {
                    for (var i = 0; i < recordTypesData.length; i++) {
                        var recordType = {};
                        recordType['value'] = recordTypesData[i].Id;
                        recordType['label'] = recordTypesData[i].Name;
                        recordTypes.push(recordType);
                    }
                }
                
                /*
                console.log(objectLabel);
                console.log(recordTypeName);
                console.log(objectMetadata);
                console.log(layoutMetadata);
                console.log(picklistValues);
                console.log(recordTypes);
                */
                
                component.set('v.objectLabel', objectLabel);
                component.set('v.recordTypeName', recordTypeName);
                component.set('v.layoutMetadata', layoutMetadata);
                component.set('v.recordFieldsMetadata', objectMetadata);				
                component.set('v.picklistValues', picklistValues);
                component.set('v.recordTypes', recordTypes);
                component.set('v.defaultValues', defaultValues);
                if (siteType != null && component.get('v.caller') != 'COMMUNITY_VF') {
                    component.set('v.caller', 'COMMUNITY');
                }
                console.log('Metadata retreived');
                self.renderLayoutBody(component);
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);
                component.set('v.isInitialized', true);
                component.set('v.isLayoutValid', false);
                self.showToast(null, "error", "Error", 'Cannot get layout metadata: ' + message, component);
            }
        });
        
        
		var getRecordTypeIdAction = component.get('c.getRecordTypeId');
        getRecordTypeIdAction.setParams({ 
            sObjectName : sObjectName,
            recordId : recordId
        });
               
        getRecordTypeIdAction.setCallback(this, function(a) {
            var state = a.getState();
            if (state == 'SUCCESS') {
                recordTypeId = a.getReturnValue();
                //console.log('after getRecordTypeId: recordTypeId = ' + recordTypeId);
                component.set('v.recordTypeId', recordTypeId);
                component.set('v.newRecordTypeId', recordTypeId);
                getMetadataAction.setParams({ 
                    sObjectName : sObjectName, 
                    recordTypeId : recordTypeId,
                    mode : layoutMode,
            		recordId : recordId
                });
                $A.enqueueAction(getMetadataAction);
            } else {
                var message = 'Unknown error';
                var errors = a.getError();
                if (errors && Array.isArray(errors) && errors.length > 0) {
    				message = errors[0].message;
				}
				console.error(message);
                component.set('v.isInitialized', true);
                component.set('v.isLayoutValid', false);
                self.showToast(null, "error", "Error", 'Cannot check for RecordTypeId: ' + message, component);
            }
        });
        
 
               
       
        
        if (/*recordId != undefined && recordId != null && recordId != '' && */ (recordTypeId == undefined || recordTypeId == null || recordTypeId == '')) {
            $A.enqueueAction(getRecordTypeIdAction);
        } else {
            $A.enqueueAction(getMetadataAction);
        }        
    },
    
    navigateTo : function(component, recId) {
        if (component.get('v.caller') == 'VISUALFORCE' || component.get('v.caller') == 'COMMUNITY_VF') {
            window.location.href='/'+recId;
            return;
        }
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recId,
            isredirect: true
        });
        navEvt.fire();
    },
    
    decode : function(encodedStr) {
    	var parser = new DOMParser;
        var dom = parser.parseFromString('<!doctype html><body>' + encodedStr, 'text/html');
        return dom.body.textContent;
    },
    
    getAutosuggestOptions : function(component, fieldApiName) {
        var result = [];
        var picklistValues = component.get('v.picklistValues');
        var fieldOptions = picklistValues.picklistFieldValues[fieldApiName];
        if (fieldOptions.values != undefined && fieldOptions.values.length > 0) {
            for (var i = 0; i < fieldOptions.values.length; i++) {
                var option = {value: fieldOptions.values[i].value, label: fieldOptions.values[i].label};
                result.push(option);
            }
        }
        return result;
    },
    
    renderLayoutBody : function(component) {
        var layoutMode = component.get('v.layoutMode');
        var sObjectName = component.get('v.sObjectName');
        var objectLabel = component.get('v.objectLabel');
        this.setLayoutTitle(component);
        var recordId = component.get('v.recordId');     
        var layoutMetadata = component.get('v.layoutMetadata');
        var recordFieldsMetadata = component.get('v.recordFieldsMetadata');
        var layoutBodyComponents = [];
        var componentDef = null;
        var componentAttributes = {};
        var sections = layoutMetadata.sections;
        for (var i = 0; i < sections.length; i++) {
			var section = sections[i];
            var numOfColumns = section.columns;
            var sectionId = sObjectName + ':' + 'section' + i;
            componentDef = 'c:LayoutSection';
            componentAttributes = {
                "aura:id": sectionId,
                "parentId": component.get('v.componentId'),
                "sectionId": sectionId,
                "name": sectionId,
                "sectionTitle": section.heading,
                "style": section.style,
                "isExpandable": section.collapsible,
                "childComponents": null
            };
            layoutBodyComponents.push([
                componentDef,
                componentAttributes
            ]);
            
            if (section.layoutRows && section.layoutRows.length > 0) {
                var rows =  section.layoutRows;
                for (var j = 0; j < rows.length; j++) {
                    var row = rows[j];
                    var rowId = sectionId + ':' + 'Row' + j;
                    componentDef = 'c:DynamicLayoutRow';
                    componentAttributes = {
                        "aura:id": rowId,
                        "parentId": component.get('v.componentId'),
                        "sectionId": sectionId,
                        "rowId": rowId,
                        "name": rowId,
                        "childComponents": null
                    };
                    layoutBodyComponents.push([
                        componentDef,
                        componentAttributes
                    ]);                    
                    if (row.layoutItems && row.layoutItems.length > 0) {
                        var layoutItems = row.layoutItems;
                        for (var k = 0; k < layoutItems.length; k++) {
                        	var layoutItem = row.layoutItems[k];
                            
                            // Added 10-05-2019: Start
                            // Handle more than one field in one layout item - not ready yet
                            /*
                            var layoutItemComponentsCount = layoutItem.layoutComponents.length;
                            var layoutComponent;
                            var fieldType;
                            var fieldApiName = [];
                            
                            var isRendered = true;
                            var isRequired;  
                            var isDisabled;
                            var isReadOnly;                  
                            
                            if (layoutItemComponentsCount == 1) {
                                layoutComponent = layoutItem.layoutComponents[0];
                                fieldType = layoutComponent.componentType;
                                fieldApiName.push(layoutComponent.apiName);
                                var layoutItemMetadata = recordFieldsMetadata[layoutComponent.apiName];
                                var isRequired = layoutItem.required;  
                                if (layoutMode == 'NEW') {
                                    var isDisabled = (layoutItem.editableForNew) ? false : true;
                                    var isReadOnly = (layoutItem.editableForNew) ? false : true;
                                } else if (layoutMode == 'EDIT') {
                                    var isDisabled = (layoutItem.editableForUpdate) ? false : true;
                                    var isReadOnly = (layoutItem.editableForUpdate) ? false : true;
                                }
                            } else if (layoutItemComponentsCount > 1) {
                                var isField = false;
                                var isRenderedGlobal = true;
                                var isRequiredGlobal;  
                            	var isDisabledGlobal;
                            	var isReadOnlyGlobal;
                                
                                for (var c = 0; c < layoutItemComponentsCount; c++) {
                                    layoutComponent = layoutItem.layoutComponents[c];
                                    fieldType = layoutComponent.componentType;
                                    if (layoutComponent.componentType == 'Field') {
                                        isField = true;
                                        fieldApiName.push(layoutComponent.apiName);
                                    }
                                }
                                if (isField) {
                                    fieldType = 'Field';
                                }
                            }                            
                            */
                            // Added 10-05-2019: End
                            
                            /*
                            var layoutItemComponentsCount = layoutItem.layoutComponents.length;
                            if (layoutItemComponentsCount > 1) {
                                console.log('Field ' + layoutItem.label + ', number of layout components = ' + layoutItemComponentsCount);
                            }
                            */
                            
                            var layoutItemComponentsCount = layoutItem.layoutComponents.length;
                            for (var c = 0; c < layoutItem.layoutComponents.length; c++) {
                                var layoutComponent = layoutItem.layoutComponents[c];
                                if (layoutComponent.componentType == 'Field' || layoutComponent.componentType == 'EmptySpace') {
                                    var layoutItemMetadata = recordFieldsMetadata[layoutComponent.apiName];
									var isRendered = true;
                                    //var isRequired = layoutItem.required;
                                   if(layoutItemMetadata)
                                    var isRequired = layoutItemMetadata.isRequired;
                                    var isReadOnly = false;
                                    var isDisabled = false;
                                    var replaceEnabled = false;
                                    if (layoutMode == 'NEW') {
                                        var isDisabled = (layoutItem.editableForNew) ? false : true;
                                        var isReadOnly = (layoutItem.editableForNew) ? false : true;
                                    } else if (layoutMode == 'EDIT') {
                                        var isDisabled = (layoutItem.editableForUpdate) ? false : true;
                                        var isReadOnly = (layoutItem.editableForUpdate) ? false : true;
                                        if (layoutComponent.apiName == 'RecordTypeId' && component.get('v.isChangeRecordType')) {
                                            isDisabled = true;
                                            isReadOnly = false;
                                        }
                                    } else if (layoutMode == 'VIEW') {
                                        if (layoutComponent.apiName == 'RecordTypeId' && component.get('v.caller') == 'APP') {
                                            replaceEnabled = true;
                                        }
                                    }
                                    var autosuggestOptions = [];
                                    if (layoutItemMetadata != undefined && layoutItemMetadata.useAutosuggest) {
                                        autosuggestOptions = this.getAutosuggestOptions(component, layoutComponent.apiName);
                                    }
                                    var objectIconName = null;
                                    if (layoutItemMetadata != undefined && layoutItemMetadata.dataType == 'REFERENCE') {
                                        var referenceObject = layoutItemMetadata.referenceObject.toLowerCase();
                                        if (referenceObject == 'owner' || referenceObject == 'lastmodifiedby' || referenceObject == 'createdby') {
											objectIconName = 'user';
                                        } else if (referenceObject == 'recordtype') {
                                            objectIconName = null;
                                        } else {
                                            objectIconName = referenceObject;
                                        }
                                    }
                                    componentDef='c:DynamicLayoutInputField';
                                    componentAttributes = {
                                        "aura:id": rowId + ':' + ((layoutComponent.componentType == 'Field') ? layoutComponent.apiName : layoutComponent.componentType + c),
                                        "parentId": component.get('v.componentId'),
                                        "fieldType": layoutComponent.componentType,
                                        "layoutMode": component.get('v.layoutMode'),
                                        "sectionId": sectionId,
                                        "rowId": rowId,
                                        "useAutosuggest": (layoutItemMetadata != undefined) ? layoutItemMetadata.useAutosuggest : false,
                                        "autosuggestOptions": autosuggestOptions,
                                        "type": (layoutItemMetadata != undefined) ? layoutItemMetadata.dataType : null,
                                        "name": layoutComponent.apiName,
                                        "label": (layoutItemComponentsCount > 1) ? layoutComponent.label : layoutItem.label,
                                        "objectIconName": objectIconName,
                                        "required": isRequired,
                                        "readonly": isReadOnly,
                                        "disabled": isDisabled,
                                        "class": "slds-col slds-size--1-of-1 slds-small-size--1-of-" + numOfColumns + " slds-medium-size--1-of-" + numOfColumns,
                                        "helpText": (layoutItemMetadata != undefined) ? layoutItemMetadata.helpText : null,
                                        "isRendered": isRendered
                                    }
                                    if (replaceEnabled) {
                                        componentAttributes['replaceEnabled'] = replaceEnabled;
                                    }
                                    layoutBodyComponents.push([
                                        componentDef,
                                        componentAttributes
                                    ]);
                                }
                            }
                        }
                    } 
                }
            }
        }
        
        console.log('Layout components prepared');
        
        if (layoutBodyComponents.length > 0) {
            var self = this;
            $A.createComponents(layoutBodyComponents, function(cmps, status, errorMessage) {
                //console.log('CreateComponents status: ' + status);
                //console.log('errorMessage: ' + errorMessage);
                //console.log('Created components: ' + cmps.length);
                if (status == 'SUCCESS') {
                
                    var sections = component.get('v.sections');
                    var rows = component.get('v.rows');
                    var sectionFields = component.get('v.sectionFields');
                    var layoutBody = component.get('v.layoutBody');
                    var uiMetadata = {};
                    for (var i = 0; i < cmps.length; i++) {
                        var cmp = cmps[i];
                        var cmpType = cmp.get('v.layoutElementType');
                        if (cmpType && cmpType == 'LayoutSection') {
                            sections.push(cmp);
                        } else if (cmpType && cmpType == 'LayoutRow') {
                            rows.push(cmp);
                        } else if (cmpType && cmpType == 'LayoutField') {
                            sectionFields.push(cmp);
                        } else {
                            sectionFields.push(cmp);
                        }
                    }
                    for (var i = 0; i < sections.length; i++) {
                        var section = sections[i];
                        var sectionId = section.get("v.sectionId");
                        var sectionRows = section.get("v.childComponents");
                        var sectionRowsMetadata = {};
                        for (var j = 0; j < rows.length; j++) {
                            var row = rows[j];
                            var rowId = row.get("v.rowId");
                            var rowSectionId = row.get("v.sectionId");
                            var rowFields = row.get("v.childComponents");
                            if (rowSectionId == sectionId) {
                                var rowFieldsMetadata = {};
                                for (var k = 0; k < sectionFields.length; k++) {
                                    var field = sectionFields[k];
                                    var fieldSectionId = field.get("v.sectionId");
                                    var fieldRowId = field.get("v.rowId");
                                    if (fieldSectionId == sectionId && fieldRowId == rowId) {
                                        rowFields.push(field);
                                        if (field.get("v.fieldType") == 'Field') {
                                            var fieldMetadata = {};
                                             ////////////////////////////////////////////
                                            if(component.get('v.sObjectName') == 'Case' && component.get('v.layoutMode') == 'NEW' && field.get('v.label') == 'Subject'){
                                                console.log('Knowledge Search Component');
                                                field.set('v.helpText','KnowledgeSearchComponent');                                                                                                
                                            }
                                            //else if(component.get('v.sObjectName') == 'Case' && component.get('v.layoutMode') == 'NEW' && field.get('v.label') == 'Product_area__c'){                                                                                                    
                                            //}
                                            
                                            /////////////////////////////////////////////
                                            fieldMetadata["label"] = field.get('v.label');
                                            fieldMetadata["rendered"] = true;
                                            fieldMetadata["required"] = field.get("v.required");
                                            fieldMetadata["required_origin"] = field.get("v.required");                                                                                                                    
                                            rowFieldsMetadata[field.get("v.name")] = fieldMetadata;
                                        }
                                    }
                                }
                                sectionRows.push(row);
                                sectionRowsMetadata[rowId] = rowFieldsMetadata;
                            }
                            row.set("v.childComponents", rowFields);
                        }
                        section.set("v.childComponents", sectionRows);
                        uiMetadata[sectionId] = sectionRowsMetadata;
                        layoutBody.push(section);
                    }
                    component.set('v.uiMetadata', uiMetadata);
                    //console.log(uiMetadata);
                    component.set('v.layoutBody', layoutBody);
                    if (component.get('v.layoutMode') == 'VIEW') {
                        self.setInitialFieldsRenderProperties(component);
                    }
                    component.set('v.isInitialized', true);
                    self.showProcessingSpinner(component);
                    
                    console.log('Layout components and UI metadata created');
                    
                } else {
                    console.error('Cannot create layout components: ' + errorMessage);
                    component.set('v.isLayoutValid', false);
                    self.hideProcessingSpinner(component);
                    this.showToast(null, "error", "Error", 'Cannot create layout components: ' + errorMessage, component);
                }
            });            
        }
    },
    
    handleRecordLoad : function(component, event) {
        try {
            var sObjectName = component.get('v.sObjectName');
            var recordTypeId = component.get("v.recordTypeId");
            var recordUI = event.getParam("recordUi");
            var objectInfo = recordUI.objectInfo;
            if (component.get('v.isLayoutValid') && component.get('v.isInitialized') && !component.get('v.recordLoaded')) {
				console.log('');
                var rec = {};
                var fields = recordUI.record.fields;
                for (var k in fields) {
                    rec[k] = fields[k].value;
                }
                component.set("v.record", rec);
                console.log(rec);
                var fields = objectInfo.fields;
                var dependentFields = {};
                for (var k in fields) {
                    if (fields[k].controllerName != null && fields[k].controllerName != '') {
                        dependentFields[k] = fields[k].controllerName;
                    }
                }
                component.set('v.dependentFields', dependentFields);
                if (component.get('v.layoutMode') == 'NEW' || component.get('v.isChangeRecordType')) {
                    this.setInitialDefaultValues(component);
                }
                var fields = component.get('v.recordFieldsMetadata');
                for (var k in fields) {
                    var field = fields[k];
                    if (component.get('v.layoutMode') == 'EDIT' && field.useAutosuggest) {
                        rec[k] = field.fieldValue;
                        if (field.fieldValue != null) {
                            this.setFieldValue(component, k, field.fieldValue);
                        }
                    }
                }
                this.setInitialFieldsRenderProperties(component);
                this.setDependentPicklistsProperties(component);
                component.set('v.recordLoaded', true);
                this.hideProcessingSpinner(component);
                ///////////////////////////////////////////////////////////////////////////////
                console.log('Dynamic Layout loaded');
                localStorage.setItem('productArea',null);   
                localStorage.setItem('subProductArea',null);   
                console.log('recordTypeName : ' + localStorage.getItem('recordTypeName'));
                console.log('productArea : ' + localStorage.getItem('productArea'));
                console.log('subProductArea : ' + localStorage.getItem('subProductArea'));
                
            }
        } catch (err) {
            console.error(err.message);
            console.error(err);
        }
    },
    
    setInitialDefaultValues : function(component) {
        var fields = component.get('v.recordFieldsMetadata');
        var defaultValues = component.get('v.defaultValues');
        //console.log(JSON.stringify(defaultValues));
        for (var k in fields) {
            var field = fields[k];
            
            if (component.get('v.isChangeRecordType') && field.fieldApiName != "RecordTypeId") continue;
            // Set initial values from metadata
			if (field.defaultValueStatus == 'VALID') {
                this.setFieldValue(component, field.fieldApiName, field.defaultValue);
            } else if (field.defaultValueStatus == 'INVALID') {
                this.showToast(null, "error", "Error", field.defaultValue, component);
            }
            // Set initial values from component input - that will override defaults from metadata if exists
            if (defaultValues != undefined && defaultValues[field.fieldApiName] != undefined && defaultValues[field.fieldApiName] != null) {
                this.setFieldValue(component, field.fieldApiName, defaultValues[field.fieldApiName]);
            }
        }
    },
    
    setLayoutTitle : function(component) {
        var title = '';
        if (component.get('v.layoutMode') == 'NEW') {
            title = 'New ';
        } else if (component.get('v.layoutMode') == 'EDIT') {
            title = 'Edit ';
        } else {
            title = 'View ';
        }
        title = title + component.get('v.objectLabel');
        var recordTypeName = component.get('v.recordTypeName');
        if (recordTypeName != null && recordTypeName != '' && recordTypeName != 'null') {
            title = title + ' : ' + recordTypeName;
        }
        component.set('v.lauoutTitle', title);
        
        ///////////////////////////////////////////////////////////////////////////////////////////////
        if(component.get('v.objectLabel') == 'Case'){
            localStorage.setItem('recordTypeName',recordTypeName + '__c');
            console.log('recordTypeName', recordTypeName + '__c');
        }
        ///////////////////////////////////////////////////////////////////////////////////////////////
        
    },
    
    getFiledExpressionValue : function(value) {
        var expFieldValue = 'null';
        if (value != null && value != '' && typeof value == 'boolean') {
            expFieldValue = (value) ? 'true' : 'false';
        } else if (value != null && value != '') {
            expFieldValue = "'" + value + "'";
        }
        return expFieldValue;
    },
    
    getFieldRenderProperty : function(component, fieldName, renderExpression) {
        var res;
        var fieldUiMetadata = this.getFieldUiMetadata(component, fieldName);
        if (renderExpression == null) {
            res = true;
        } else {
        	var record = component.get('v.record');
            var expression = renderExpression.replace(/\s/g,'');
            //expression = expression.replace(/[$]/g, '\\$&');
            var fields = component.get('v.recordFieldsMetadata');
            for (var k in fields) {
                var field = fields[k];
            	var triggerField = '{!' + field.fieldApiName + '}';
                var searchRegExp = new RegExp(triggerField, 'i');
                if (searchRegExp.test(expression)) {
                    var currFieldValue = record[field.fieldApiName];
                    var replaceRegExp = new RegExp(triggerField, 'ig');
                    expression = expression.replace(replaceRegExp, this.getFiledExpressionValue(currFieldValue));
                }
            }
            // UserType bind variable
            var userTypeSearchRegExp = new RegExp('\\$USERTYPE', 'i');
            if (userTypeSearchRegExp.test(expression)) {
                var userType = (component.get('v.caller') == 'APP' || component.get('v.caller') == 'VISUALFORCE') ? "'SF'" : "'COMMUNITY'";
                var userTypeReplaceRegExp = new RegExp('\\$USERTYPE', 'ig');
                expression = expression.replace(userTypeReplaceRegExp, userType);
            }
            console.log('fieldName = ' + fieldName);
            console.log('expression = ' + expression);
            try {
                var res = eval(expression);
                console.log('res = ' + res);
            } catch (e) {
                console.log('Error in getFieldRenderProperty(): ' + e.message);
                console.log('  Expression: ' + expression);
                this.showToast(null, "error", "Error", fieldName + ": Display condition evaluation error: " + e.message, component);
                return false;
            }
        }
		this.updateUiMetadataRendered(component, fieldName, res);
        return res;
    },

	    getFieldRequireProperty : function(component, fieldName, renderExpression) {
        var res;
        var fieldUiMetadata = this.getFieldUiMetadata(component, fieldName);
        if (renderExpression == null) {
            res = false;
        } else {
        	var record = component.get('v.record');
            var expression = renderExpression.replace(/\s/g,'');
            //expression = expression.replace(/[$]/g, '\\$&');
            var fields = component.get('v.recordFieldsMetadata');
            for (var k in fields) {
                var field = fields[k];
            	var triggerField = '{!' + field.fieldApiName + '}';
                var searchRegExp = new RegExp(triggerField, 'i');
                if (searchRegExp.test(expression)) {
                    var currFieldValue = record[field.fieldApiName];
                    var replaceRegExp = new RegExp(triggerField, 'ig');
                    expression = expression.replace(replaceRegExp, this.getFiledExpressionValue(currFieldValue));
                }
            }
            // UserType bind variable
            var userTypeSearchRegExp = new RegExp('\\$USERTYPE', 'i');
            if (userTypeSearchRegExp.test(expression)) {
                var userType = (component.get('v.caller') == 'APP' || component.get('v.caller') == 'VISUALFORCE') ? "'SF'" : "'COMMUNITY'";
                var userTypeReplaceRegExp = new RegExp('\\$USERTYPE', 'ig');
                expression = expression.replace(userTypeReplaceRegExp, userType);
            }
            console.log('fieldName = ' + fieldName);
            try {
                var res = eval(expression);
            } catch (e) {
                console.log('Error in getFieldRenderProperty(): ' + e.message);
                console.log('  Expression: ' + expression);
                this.showToast(null, "error", "Error", fieldName + ": Display condition evaluation error: " + e.message, component);
                return false;
            }
        }
		//this.updateUiMetadataRendered(component, fieldName, res);
        return res;
    },
    
    getFieldUiMetadata : function(component, fieldName) {
    	var fieldProperties;
        var uiMetadata = component.get('v.uiMetadata');
		for (var section in uiMetadata) {
            var isSectionRendered = false;
            var sectionRows = uiMetadata[section];
            for (var row in sectionRows) {
                var isRowRendered = false;
                var rowFields = sectionRows[row];
                for (var field in rowFields) {
                    if (field == fieldName) {
                        fieldProperties = rowFields[field];
                    }
                }
            }
        }
        return fieldProperties;
    },
    
    updateUiMetadataRendered : function(component, fieldName, isRendered) {
        var uiMetadata = component.get('v.uiMetadata');
		for (var section in uiMetadata) {
            var isSectionRendered = false;
            var sectionRows = uiMetadata[section];
            for (var row in sectionRows) {
                var isRowRendered = false;
                var rowFields = sectionRows[row];
                for (var field in rowFields) {
                    if (field == fieldName) {
                        var fieldProperties = rowFields[field];
                        fieldProperties["rendered"] = isRendered;
                    }
                }
            }
        }        
        component.set('v.uiMetadata', uiMetadata);
    },
    
    updateUiMetadataRequired : function(component, fieldName, isRequired) {
        var uiMetadata = component.get('v.uiMetadata');
        for (var section in uiMetadata) {
            var isSectionRendered = false;
            var sectionRows = uiMetadata[section];
            for (var row in sectionRows) {
                var isRowRendered = false;
                var rowFields = sectionRows[row];
                for (var field in rowFields) {
                    if (field == fieldName) {
                        var fieldProperties = rowFields[field];
                        fieldProperties["required"] = isRequired;
                    }
                }
            }
        }
        component.set('v.uiMetadata', uiMetadata);
    },
    
    setDependentFieldsRenderProperty : function(component, name, value) {   
		console.log('TSR setDependentFieldsRenderProperty started');     
        var fields = component.get('v.recordFieldsMetadata');
        for (var k in fields) {
            var field = fields[k];
            var triggerField = '{!' + name.toUpperCase() + '}';
            var searchRegExp = new RegExp(triggerField, 'i');
            if (field.displayCondition != null && searchRegExp.test(field.displayCondition.replace(/\s/g, ''))) {
				var isRendered = this.getFieldRenderProperty(component, field.fieldApiName, field.displayCondition);  
                this.setFieldRenderedProperty(component, field.fieldApiName, isRendered);
                var fieldUiMetadata = this.getFieldUiMetadata(component, field.fieldApiName);
				var reqConIsNotNull = field.conditionalRequired != null;
				//if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) {
				if ((fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) || (fieldUiMetadata != undefined && this.getFieldRequireProperty(component, field.fieldApiName, field.conditionalRequired) && isRendered && reqConIsNotNull)) {
				    this.updateUiMetadataRequired(component, field.fieldApiName, true);
                    this.setFieldRequiredProperty(component, field.fieldApiName, true);
                //} else if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && !isRendered) {
				} else if ((fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) || !(fieldUiMetadata != undefined && this.getFieldRequireProperty(component, field.fieldApiName, field.conditionalRequired) && isRendered)) {
				    this.updateUiMetadataRequired(component, field.fieldApiName, false);
                    this.setFieldRequiredProperty(component, field.fieldApiName, false);
                }
            }
        }
        // console.log('point 4');
        this.setSectionsAndRowsRenderProperties(component);
    },
    
    setSingleFieldRenderProperty : function(component, fieldName) {        
        var fields = component.get('v.recordFieldsMetadata');
		for (var k in fields) {
			var field = fields[k];
		}
        for (var k in fields) {
            var field = fields[k];
            if (field.fieldApiName == fieldName) {
                var isRendered = this.getFieldRenderProperty(component, field.fieldApiName, field.displayCondition);
                this.setFieldRenderedProperty(component, field.fieldApiName, isRendered);
                var fieldUiMetadata = this.getFieldUiMetadata(component, field.fieldApiName);
				//if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) {
				if ((fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) || (fieldUiMetadata != undefined && this.getFieldRequireProperty(component, field.fieldApiName, field.conditionalRequired) && isRendered)) {
				    this.updateUiMetadataRequired(component, field.fieldApiName, true);
                    this.setFieldRequiredProperty(component, field.fieldApiName, true);
                //} else if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && !isRendered) {//} else if (fieldUiMetadata != undefined && this.setFieldRequiredFromMDT(fieldUiMetadata['required_origin'], field.displayCondition) && !isRendered) {
                } else if ((fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) || !(fieldUiMetadata != undefined && this.getFieldRequireProperty(component, field.fieldApiName, field.conditionalRequired) && isRendered)) {
				    this.updateUiMetadataRequired(component, field.fieldApiName, false);
                    this.setFieldRequiredProperty(component, field.fieldApiName, false);
                }
            }
        }
        console.log('point 3');
        this.setSectionsAndRowsRenderProperties(component);
    },
    
    setInitialFieldsRenderProperties : function(component) {        
        var fields = component.get('v.recordFieldsMetadata');
		for (var k in fields) {
			var field = fields[k];
		}
        for (var k in fields) {
            var field = fields[k];
			if (field.displayCondition != null) {
                var isRendered = this.getFieldRenderProperty(component, field.fieldApiName, field.displayCondition);              
                this.setFieldRenderedProperty(component, field.fieldApiName, isRendered);
                var fieldUiMetadata = this.getFieldUiMetadata(component, field.fieldApiName);
				//if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) {

				if ((fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) || (fieldUiMetadata != undefined && this.getFieldRequireProperty(component, field.fieldApiName, field.conditionalRequired) && isRendered)) {
                    this.updateUiMetadataRequired(component, field.fieldApiName, true);
                    this.setFieldRequiredProperty(component, field.fieldApiName, true);
                //} else if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && !isRendered) {
				} else if ((fieldUiMetadata != undefined && fieldUiMetadata['required_origin'] && isRendered) || !(fieldUiMetadata != undefined && this.getFieldRequireProperty(component, field.fieldApiName, field.conditionalRequired) && isRendered)) {
                    this.updateUiMetadataRequired(component, field.fieldApiName, false);
                    this.setFieldRequiredProperty(component, field.fieldApiName, false);
                }
                
            }            
        }
        console.log('point 2');
        this.setSectionsAndRowsRenderProperties(component);
    },
    
    setSectionsAndRowsRenderProperties : function(component) {
        // console.log('point 1');
        var uiMetadata = component.get('v.uiMetadata');
        for (var section in uiMetadata) {
            var isSectionRendered = false;
            var sectionRows = uiMetadata[section];
            for (var row in sectionRows) {
                var isRowRendered = false;
                var rowFields = sectionRows[row];
                for (var field in rowFields) {
                    var fieldProperties = rowFields[field];
                    if (fieldProperties["rendered"]) {
                        isRowRendered = true;
                        isSectionRendered = true;
                    }
                }
                this.setFieldRenderedProperty(component, row, isRowRendered);
            }
            this.setFieldRenderedProperty(component, section, isSectionRendered);
        }
    },
    
    setDependentPicklistsProperties : function(component) {
        var record = component.get('v.record');
        var dependentFields = component.get('v.dependentFields');
        var picklistValues = component.get('v.picklistValues').picklistFieldValues;
        for (var k in dependentFields) {
            var isRequired = false;
            var isDisabled = true;
            var fieldUiMetadata = this.getFieldUiMetadata(component, k);
            var controllerField = dependentFields[k];
            var controllerFieldValue = record[controllerField];
            var dependentFieldData = picklistValues[k];
            var controllerIdx = (dependentFieldData.controllerValues[controllerFieldValue] != undefined) ? dependentFieldData.controllerValues[controllerFieldValue] : -1;
            var dependentFieldValues = dependentFieldData.values;
            var autosuggestOptions = [];
            if (dependentFieldValues.length > 0) {
                for (var i = 0; i < dependentFieldValues.length; i++) {
                    var value = dependentFieldValues[i];
                    if (value.validFor.includes(controllerIdx)) {
                        isDisabled = false;
                        if (fieldUiMetadata != undefined && fieldUiMetadata['required_origin']) {
                        	isRequired = true;
                        }
                        var option = {value: value.value, label: value.label};
                        autosuggestOptions.push(option);
                    }
                }
            }
            this.setFieldDisabledProperty(component, k, isDisabled);
            this.setFieldRequiredProperty(component, k, isRequired);
            this.setAutosuggestOptions(component, k, autosuggestOptions);
            if (!isRequired && component.get('v.recordLoaded')) {
                this.setFieldErroredProperty(component, k, false, "");
            }
            this.updateUiMetadataRequired(component, k, isRequired);
        }
    },
    
    handleFieldChanged : function(component, event) {
        if (component.get("v.componentId") == event.getParam("parentId")) {
            if (component.get('v.recordLoaded')) {
                var fieldName = event.getParam("name");
                var value = event.getParam("value");
                var rec = component.get('v.record');
				if (value != rec[fieldName]) {
                    this.updateFieldValue(component, fieldName, value);        
                    this.setDependentFieldsRenderProperty(component, fieldName, value);
                    console.log('value',value);
                    console.log('fieldName',fieldName);
                    ///////////////////////////////////////////////////////////////////
                    //
                    var parentProductAreaList = JSON.parse(localStorage.getItem('parentProductAreaList'));                   
                    for(var i = 0;i < parentProductAreaList.length; i++){
                        console.log(localStorage.getItem('recordTypeName').substring(0,localStorage.getItem('recordTypeName').length - 3) + '_' + fieldName + ' == ',parentProductAreaList[i].DeveloperName + '__c'); 
                        if(localStorage.getItem('recordTypeName').substring(0,localStorage.getItem('recordTypeName').length - 3) + '_' + fieldName ==  parentProductAreaList[i].DeveloperName + '__c'){
                            localStorage.setItem('subProductArea',value);                      
                            console.log(fieldName + ' Changed : ', localStorage.getItem('subProductArea'));   
                            localStorage.setItem('subProductArea',localStorage.getItem('recordTypeName').substring(0,localStorage.getItem('recordTypeName').length - 3) + '_' + value.replace(" ","_") + '__c');
                            console.log('sub Product Area Set To : ', localStorage.getItem('subProductArea')); 
                        }
                    }
                    
                    if(fieldName == 'Product_area__c'){                        
                         var el = document.getElementsByTagName('c-knowledge-search'); 
                        console.log('c-knowledge-search collection length',el.length);
                        if(el[el.length -1] != undefined){
                            var ul = el[el.length -1].getElementsByTagName('ul')[0]; 
                            if(ul != undefined){
                               ul.style.display = 'none'; 
                            }
                        }                           
                    }
                    //if(fieldName == 'Build_Server_Plugin__c' || fieldName == 'Source_Repository__c' || fieldName == 'IDE_Plugin__c' || fieldName == 'System_Integrating__c' || fieldName == 'Languages_MultiSelection__c' || fieldName == 'Access_Management_Protocol__c'){                       
                     //  }
                    
                    
                    
                    ///////////////////////////////////////////////////////////////////
                    var dependentFields = component.get('v.dependentFields');
                    for (var k in dependentFields) {
                        if (dependentFields[k] == fieldName) {
                            this.setDependentPicklistsProperties(component);
                            break;
                        }
                    }
                }
            }
        }
    },
    
    handleReplaceFieldValue : function(component, event) {

        var fieldName = event.getParam("fieldName");
        if (fieldName == 'RecordTypeId') {
            this.initReplaceRecordTypeId(component);
        } else {
            console.error('Change value for ' + fieldName + ' is not supported yet');
        }
    },
    
    initReplaceRecordTypeId : function(component) {
        component.set('v.isRecordTypeSelectionAction', true);
    },
    
    handleReplaceRecordTypeIdNextAction : function(component, event) {
        var currRecordTypeId = component.get('v.recordTypeId');
        var newRecordTypeId = component.get('v.newRecordTypeId');
        
        console.log('currRecordTypeId', currRecordTypeId);
        console.log('newRecordTypeId', newRecordTypeId);
        
        var self = this;
        if (currRecordTypeId == newRecordTypeId) {
            self.showToast(null, "error", null, 'You selected current value', component);
        } else {
            var navEvt = $A.get("e.force:navigateToComponent");
            navEvt.setParams({
                componentDef : "c:DynamicLayoutDialog",
                componentAttributes: {
                    sObjectName : component.get("v.sObjectName"),
                    recordId : component.get('v.recordId'),
                    recordTypeId : newRecordTypeId,
                    layoutMode : 'EDIT',
                    isChangeRecordType : true,
                    caller : component.get('v.caller'),
                }
            });
            component.set('v.isRecordTypeSelectionAction', false);
            navEvt.fire();
        }
    },
    
    updateFieldValue : function(component, name, value) {
        var rec = component.get("v.record");
        rec[name] = value;
        component.set("v.record", rec);
        /*
        var uiMetadata = component.get('v.uiMetadata');
        for (var section in uiMetadata) {
            var isSectionRendered = false;
            var sectionRows = uiMetadata[section];
            for (var row in sectionRows) {
                var isRowRendered = false;
                var rowFields = sectionRows[row];
                for (var field in rowFields) {
                    if (field == name) {
                        var fieldProperties = rowFields[field];
                       if (fieldProperties["required"]) {
                            var hasError = (value == null || value == '') ? true : false;
                            var errorText = (value == null || value == '') ? 'This field is required' : '';
                            this.setFieldErroredProperty(component, field, hasError, errorText);
                        }
                    }
                }
            }
        } 
        */
    },
    
    handleAttachmentsUploaded : function(component, event) {
        var uploadedFiles = event.getParam("files");
        if (uploadedFiles.length > 0) {
            component.set('v.isAttachmentsUploaded', true);
            var attachmentsUploaded = component.get('v.attachmentsUploaded');
            for (var i = 0; i < uploadedFiles.length; i++) {
                attachmentsUploaded.push(uploadedFiles[i]);
            }
            component.set('v.attachmentsUploaded', attachmentsUploaded);
        }
    },
    
    saveDialog : function(component, event) {
        
        console.log('in save');
        
        //event.preventDefault();
        this.showProcessingSpinner(component);
        clearTimeout(component.get('v.validateTimer'));
        var isFormValid = this.validateRecord(component);
        if (isFormValid) {
            var fields = event.getParam('fields');
            var record = component.get('v.record');
            for (var field in record) {
                if (field in fields) {
                    fields[field] = record[field];
                } else {
                    // fields.push(field);
                    fields[field] = record[field];
                }
            }
            //console.log(JSON.parse(JSON.stringify(fields)));
        	component.find('recordEditForm').submit(fields);
        } else {
            this.hideProcessingSpinner(component);
			document.getElementById('dynamicLayoutModalBody').scrollTop = 0;
        }
    },
    
    validateRecord : function(component) {
        component.set('v.errors', '');
        var errors = [];
        var errorCount = 0;
        var isValid = true;
        var record = component.get('v.record');
        var uiMetadata = component.get('v.uiMetadata');
        for (var section in uiMetadata) {
            var sectionRows = uiMetadata[section];
            for (var row in sectionRows) {
                var rowFields = sectionRows[row];
                for (var field in rowFields) {
                    var fieldProperties = rowFields[field];
                    if (fieldProperties["required"]) {
                        if (record[field] == null || record[field] == '') {
                            this.setFieldErroredProperty(component, field, true, "This field is required");
                            isValid = false;
                            errorCount++;
                            var label = fieldProperties["label"];
                            var error = errorCount + ". " + label + ": This field is required";
                            errors.push(error);
                        } else {
                            this.setFieldErroredProperty(component, field, false, "");
                        }
                    }
                }
            }
        }          
        if (errors.length > 0) {
            component.set('v.errors', errors);
        }
        return isValid;
    },
    
    formSubmitSuccess : function(component, event) {
        var payload = event.getParams().response;
        component.set('v.currentRecordId', payload.id);
        if (component.get('v.addAttachmentsFlag')) {
            this.hideProcessingSpinner(component);
            component.set('v.isLayoutdisabled', true);
            component.set('v.isAddAttachmentsAction', true);
        } else {
        	this.closeDialogAfterSave(component, event);
        }
    },
    
    formSubmitError : function(component, event) {
        //debugger;
        console.error(JSON.stringify(event));
        // var error = event.getParam("error");
        // var errorMessage = error.body.message;
        // this.showToast(null, "error", "Error", errorMessage, component);
        this.hideProcessingSpinner(component);
        document.getElementById('dynamicLayoutModalBody').scrollTop = 0;
    },
    
    handleSkipAttachments : function(component, event) {
        var mode = component.get('v.layoutMode');
        if (mode == 'NEW') {
            this.closeDialogAfterSave(component, event);
        } else {
            this.closeDialog(component);
        }
    },
    
    closeDialogAfterSave : function(component, event) {
        var successMessage = '';
        var mode = component.get('v.layoutMode');
        if (mode == 'NEW') {
            successMessage = "New " + component.get('v.objectLabel') + " was created successfully"
        } else {
            successMessage = component.get('v.objectLabel') + " was updated successfully"
        }
        //Changed By Anton Yashchuk
        var recId = component.get('v.currentRecordId');
        let caller = component.get('v.caller');
        if (caller == 'VISUALFORCE' || caller == 'COMMUNITY_VF') {
            this.navigateTo(component, recId);
            return;
        } else if (caller == 'COMMUNITY') {
            $A.get("e.c:DynamicLayoutDialogStoper").fire();    
            this.navigateTo(component, recId);
        } else {
            var workspaceAPI = component.find("workspace");
            var self = this;
            workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                if (isConsole) {
                    workspaceAPI.getFocusedTabInfo().then(function(response) {
                        var focusedTabId = (response.isSubtab == 'NEW' && component.get('v.layoutMode') ) ? response.parentTabId : response.tabId;
                        workspaceAPI.openTab({
                            recordId: recId
                        }).then(function(response) {
                            if (focusedTabId != response) {
                                workspaceAPI.closeTab({tabId: focusedTabId});
                            }
                            workspaceAPI.focusTab({tabId: response});
                        }).catch(function(error) {
                            console.error(error);
                        });
                    }).catch(function(error) {
                        console.error(error);
                    });
                } else {
                    self.navigateTo(component, recId);
                }
            })
        }
        this.showToast(null, "success", "Saved", successMessage, component);
    },
    
    handleEditRecord : function(component, event) {
        //component.set('v.layoutMode', 'EDIT');
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({ 
            "componentDef" : "c:DynamicLayoutDialog", 
            "componentAttributes" : { 
                "sObjectName" : component.get('v.sObjectName'), 
                "layoutMode" : "EDIT", 
                "recordId" : component.get('v.recordId') 
            } 
        });
        evt.fire();
    },
    
    closeDialog : function(component) {
        clearTimeout(component.get('v.validateTimer'));
        component.set('v.errors', '');
        
        //CHANGED BY Anton Yashchuk
        let caller = component.get('v.caller');
        if (caller == "VISUALFORCE") {
            $A.get("e.c:DynamicLayoutDialogStoper").fire();
            return;
        } else if (caller == 'COMMUNITY') {
            $A.get("e.c:DynamicLayoutDialogStoper").fire();
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
                    if (component.get('v.layoutMode') == 'EDIT') {
                        self.navigateTo(component, component.get('v.recordId'));
                    } else {
                        var homeEvt = $A.get("e.force:navigateToObjectHome");
                        homeEvt.setParams({
                            "scope": component.get('v.sObjectName')
                        });
                        homeEvt.fire();
                    }
                    $A.get("e.c:DynamicLayoutDialogStoper").fire();
                }
            })          
        }
    },
    
    setFieldRenderedProperty : function(component, fieldApiName, isRendered) {
        var evt = $A.get("e.c:isFieldRendered");
        evt.setParams({
            "parentId" : component.get("v.componentId"),
            "name" : fieldApiName,
            "isRendered" : isRendered
        });
        evt.fire();
    },

	setFieldRequiredFromMDT : function(reqOrig, conditionReq){
		if(conditionReq == null){
			res = reqOrig;
		}
		else{
			var res = (reqOrig && conditionReq.replace(/\s/g,''));
		}
		return res;
	},
    
    setFieldRequiredProperty : function(component, fieldApiName, isRequired) {
        var evt = $A.get("e.c:setFieldRequired");
        evt.setParams({
            "parentId" : component.get("v.componentId"),
            "name" : fieldApiName,
            "isRequired" : isRequired
        });
        evt.fire();
    },
    
    setFieldDisabledProperty : function(component, fieldApiName, isDisabled) {
        var evt = $A.get("e.c:setFieldDisabled");
        evt.setParams({
            "parentId" : component.get("v.componentId"),
            "name" : fieldApiName,
            "isDisabled" : isDisabled
        });
        evt.fire();
    },
    
    setFieldErroredProperty : function(component, fieldApiName, hasError, errorMessage) {
		var evt = $A.get("e.c:handleError");
        evt.setParams({
            "parentId" : component.get("v.componentId"),
            "name" : fieldApiName,
            "hasError" : hasError,
            "errorText" : errorMessage
        });
        evt.fire();
    },
    
    setFieldValue : function(component, fieldApiName, value) {
        var evt = $A.get("e.c:setFieldValue");
        evt.setParams({
            "parentId" : component.get("v.componentId"),
            "name" : fieldApiName,
            "value" : value
        });
        evt.fire();
        this.updateFieldValue(component, fieldApiName, value);
    },
    
    setAutosuggestOptions : function(component, fieldApiName, autosuggestOptions) {
        var evt = $A.get("e.c:setAutosuggestOptions");
        evt.setParams({
            "parentId" : component.get("v.componentId"),
            "name" : fieldApiName,
            "autosuggestOptions" : autosuggestOptions
        });
        evt.fire();
    },
    
    showToast : function(mode, type, title, message, component) {
        let caller = component.get('v.caller');
        if (caller === "VISUALFORCE" || caller === 'COMMUNITY_VF') {
            component.set("v.resultMessage2VF", title + ': \n' + message);
            component.set('v.isLayoutdisabled', true);
			component.set("v.showPopupIsteadToast", true);
            return;
        } 
        var msgMode = mode;
        if (mode == null || (mode != 'pester' && mode != 'sticky' && mode != 'dismissible')) {
            msgMode = 'dismissible';
        }
        var msgType = type;
        if (type == null || (type != 'error' && type != 'warning' && type != 'success' && type != 'info' && type != 'other')) {
            msgType = 'other';
        }
        var toast = $A.get("e.force:showToast");
        toast.setParams({
            "mode": msgMode,
            "type": msgType,
            "title": title,
            "message": message
        });
        toast.fire();
    },
    
    showProcessingSpinner : function(component) {
		component.set('v.isProcessingSpinner', true);
    },
    
    hideProcessingSpinner : function(component) {
		component.set('v.isProcessingSpinner', false);
    }
    
    
})