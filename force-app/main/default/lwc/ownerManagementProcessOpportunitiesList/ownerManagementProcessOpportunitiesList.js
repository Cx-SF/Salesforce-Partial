import { LightningElement, api, wire, track } from 'lwc';
import search from '@salesforce/apex/OwnersManagementProcessCtrl.search';
import getRecentlyViewed from '@salesforce/apex/OwnersManagementProcessCtrl.getRecentlyViewed';
import IMAGES from "@salesforce/resourceUrl/InformationPNG";

const columns = [
    {label : '#', fieldName : 'rowNumber',type : 'number', initialWidth: 20, cellAttributes: { alignment: 'left' }, value: false},
    { label: 'Opportunity Name', fieldName: 'Name', tepy: 'url', typeAttributes:{label:{fieldName: 'Type'}}, value: false},
    { label: 'Account Name', fieldName: 'Type', value: false},
    { label: 'Channel', fieldName: 'BillingCountry', value: false},
    { label: 'Type', fieldName: 'Total_Active_ACV__c', type: 'currency', value: false},
    { label: 'Stage', fieldName: 'openOpportunities', value: false},
    { label: 'Close Date', fieldName: 'Account_Owner__c', value: false},
    {label: 'Owner Full Name', fieldName: 'ownerName', value: false},
    {label: 'Existing Quota', fieldName: 'existingQuote', value: false},
    {label: 'New Owner', fieldName: 'NewOwner', value: true}
    
];

export default class OwnerManagementProcessOpportunitiesList extends LightningElement {
    showOpportunitiesTable = false
    MAX_ROWS_TO_SELECT = 9000;
    _accountidlist = [];
    @api getopportunitydata;

    @api
    get getaccountidlist(){
        return this._accountidlist;
    }
    set getaccountidlist(value){
        if(value != undefined){
            this._accountidlist = value;
            this.setupOppList();
        }

    }
    opportunityData;
    columns = columns;
    opportunitiesTableData;
    existtingRecords;
    selectedRecords = 0;
    opportunitiesListToUpdate = [];
    tabelsObj = {};
    tabels = [];
    currentTable = ''
    newOwnerName = '';
    sortField;
    sortAsc = true;
    opportunityInfo = false;
    infoImage = IMAGES + '/speech_balloon_answer2.png';
    infoText = 'The below lists out opps that belong to the accounts selected above, but are NOT owned by the current account owner.';
    infoText2 = 'Please review those carefully and indicate whether they should be transferred, since due to the ownership mismatch they will not be transferred as part of the account process above.';
    infoText3 = 'Similar approval applies regarding accounts with quota for the current year.';
    init(){
        if(this.getopportunitydata.length > 0) this.showOpportunitiesTable = true;
        this.opportunityData = JSON.parse(JSON.stringify(this.getopportunitydata));
        for(let i=0; i<this.opportunityData.length; i++){
            let urll = window.location.href.split('com');
            this.opportunityData[i].opportunityUrl = urll[0] + 'com/' + this.opportunityData[i].Id;
            this.opportunityData[i].opportunityAccUrl = urll[0] + 'com/' + this.opportunityData[i].AccountId;
            this.opportunityData[i].rowNumber = i+1;
            this.opportunityData[i].ownerChange = '';
        }
        let numberOfOpp = this.opportunityData.length;
        this.existtingRecords = numberOfOpp;
        let numOfLoop = numberOfOpp / this.MAX_ROWS_TO_SELECT;
        for(let i=0; i<= numOfLoop; i++){
            let num = (i + 1) * this.MAX_ROWS_TO_SELECT;
            let tabelName = 'table' + (i+1);
            this.tabels.push({'value': tabelName, 'label': tabelName });
            this.tabelsObj[tabelName] = this.opportunityData.filter((acc) => {
                if(acc.rowNumber > (num - this.MAX_ROWS_TO_SELECT) && acc.rowNumber <= num){
                    return acc;
                }
            })
        }
        this.opportunitiesTableData = this.tabelsObj.table1;
        this.currentTable = 'table1';
    }

    setupOppList(){
        let newOpptuintiesTableData = [];
        const checkBoxElements = this.template.querySelector('[data-id="mainCheckbox"]');
        
        if(this._accountidlist.length > 0){
            this.opportunityData.map((opp)=>{ if(this._accountidlist.includes(opp.AccountId)) newOpptuintiesTableData.push(opp); })
        }else{
            this.opportunityData.map((opp)=>{ newOpptuintiesTableData.push(opp); })

        }

        if(newOpptuintiesTableData.length === 0) this.showOpportunitiesTable = false;
        if(newOpptuintiesTableData.length > 0) this.showOpportunitiesTable = true;

        this.opportunitiesTableData = newOpptuintiesTableData;
        this.setupTabelData();
        this.setupCheckoppList();
        if(checkBoxElements === undefined || checkBoxElements === null) return;
        if(this.opportunitiesListToUpdate.length !== newOpptuintiesTableData.length || newOpptuintiesTableData.length === 0 || this.opportunitiesListToUpdate.length == 0){
            checkBoxElements.checked = false;
        }else if(this.opportunitiesListToUpdate.length === newOpptuintiesTableData.length){
            checkBoxElements.checked = true;
        }

        
    }

    setupTabelData(){
        //let numberOfOpp = this.opportunityData.length;
        for(let i=0; i<this.opportunitiesTableData.length; i++){
            this.opportunitiesTableData[i].filterRowNumber = i+1;
        }
        let numberOfOpp = this.opportunitiesTableData.length;
        //this.existtingRecords = numberOfOpp;
        let numOfLoop = numberOfOpp / this.MAX_ROWS_TO_SELECT;
        this.tabels = [];
        this.tabelsObj = [];
        for(let i=0; i<= numOfLoop; i++){
            let num = (i + 1) * this.MAX_ROWS_TO_SELECT;
            let tabelName = 'table' + (i+1);
            this.tabels.push({'value': tabelName, 'label': tabelName });
            this.tabelsObj[tabelName] = this.opportunitiesTableData.filter((acc) => {
                if(acc.filterRowNumber > (num - this.MAX_ROWS_TO_SELECT) && acc.filterRowNumber <= num){
                    return acc;
                }
            })
        }
        
        this.opportunitiesTableData = this.tabelsObj.table1;
        this.currentTable = 'table1';
    }

    setupCheckoppList(){
        let oppIdList = [];
        let opportunitiesToUpdate = []
        for(const opp of this.opportunitiesListToUpdate){ oppIdList.push(opp.Id);}

        this.opportunitiesTableData.map((acc) => {if(oppIdList.includes(acc.Id)) opportunitiesToUpdate.push(acc);});
        this.opportunitiesListToUpdate = [];
        this.opportunitiesListToUpdate = opportunitiesToUpdate;
        this.selectedRecords = this.opportunitiesListToUpdate.length;

        for(let i=0; i<this.opportunitiesTableData.length; i++){
            if(!oppIdList.includes(this.opportunitiesTableData[i].Id)){
                this.opportunitiesTableData[i].checked = false;
            }else{
                this.opportunitiesTableData[i].checked = true;
            }
        }
    }

    connectedCallback(){
		this.init();        
	}
	
	renderedcallback(){
        // console.log('check');
        // //console.log(this.getaccountidlist);
	}

    butClick(){
        let numberOfAccount = this.opportunitiesTableData.length;
        let numOfLoop = numberOfAccount / this.MAX_ROWS_TO_SELECT;
        let obj = {};
        for(let i=0; i<= numOfLoop; i++){
            let num = (i + 1) * this.MAX_ROWS_TO_SELECT;
            let tabelName = 'table' + (i+1);
            obj[tabelName] = this.opportunitiesTableData.filter((acc) => {
                if(acc.rowNumber >= (num - this.MAX_ROWS_TO_SELECT) && acc.rowNumber < num){
                    return acc;
                }
            })
        }
	}

    handelCheckbox(event){
        let checkBoxElements = this.template.querySelector('[data-id="mainCheckbox"]');
        checkBoxElements.checked = false;
        let eventChecked = event.target.checked;
        let eventCheck = event.target.name;
        if(eventChecked){
            this.opportunitiesListToUpdate.push(eventCheck);
        }else{
            let opportunitiesToUpdate = this.opportunitiesListToUpdate.filter((acc) => acc.Id !== eventCheck.Id);
            this.opportunitiesListToUpdate = [];
            this.opportunitiesListToUpdate = opportunitiesToUpdate;
        }
        this.selectedRecords = this.opportunitiesListToUpdate.length;
        const selectedEvent = new CustomEvent('opportunityupdaterecord', {
            detail: this.opportunitiesListToUpdate
        });
        this.dispatchEvent(selectedEvent);

    }

    handelMainCheckbox(event){
        let eventValue = event.target.checked;
        let checkboxes = this.template.querySelectorAll('[data-id="checkBoxRos"]')
        this.spinner=true;
        for(let i=0; i<checkboxes.length; i++){
            checkboxes[i].checked = eventValue; 
        }
        
        if(this.opportunitiesListToUpdate.length > 0) this.opportunitiesListToUpdate = [];
        if(eventValue){
            this.opportunitiesListToUpdate = [...this.opportunitiesTableData];
        }
        // console.log('Rafa - this.opportunitiesListToUpdate: ' + JSON.stringify(this.opportunitiesListToUpdate));
        this.selectedRecords = this.opportunitiesListToUpdate.length;
        const selectedEvent = new CustomEvent('onopportunityupdaterecord', {
            detail: this.opportunitiesListToUpdate
        });
        this.dispatchEvent(selectedEvent);

        this.spinner=false;
    }

    handelNewOwnerKeydown(event){
        let eventKey = event.keyCode;
        let inputValue = event.target.value;
        let index = event.target.dataset.targetId;
    
        if(eventKey == 13 || eventKey == 9){
        }
    }

    handelChangeTable(event){
        let checkBoxElements = this.template.querySelector('[data-id="mainCheckbox"]');
        checkBoxElements.checked = false;
        let selectedTable = event.currentTarget.dataset.id;
        this.currentTable = selectedTable;
        this.opportunitiesTableData = this.tabelsObj[selectedTable]; 

        this.setupCheckoppList();   
    }

    handelSortBy(event){
        const selectedColumn = event.target.outerText;
        const ttt = JSON.stringify(selectedColumn).replaceAll('\\','').replaceAll('"', '').split(' ');
        const num = ttt.length - 1;
        let selectedString = '';
        for(let i = 0; i < num; i++){
            if(i === 0) selectedString += ttt[i];
            if(i !== 0) selectedString += ' ' + ttt[i];
        }
        let fieldName;
        switch(selectedString){
            case '#':
                fieldName = 'rowNumber'
                break
            case 'Opportunity Name':
                fieldName = 'Name'
                break    
            case 'Account Name':
                fieldName = 'Account_name__c'
                break 
            case 'Channel':
                fieldName = 'Channel__c'
                break
            case 'Type':
                fieldName = 'Type'
                break    
            case 'Stage':
                fieldName = 'StageName'
                break
            case 'Close Date':
                fieldName = 'CloseDate'
                break
            case 'Owner Full Name':
                fieldName = 'Opportunity_Owner_Name__c'
                break
            case 'Existing Quota':
                fieldName = 'Existing_Quota__c'
                break 
            default:
                fieldName = 'no';
                return;
        }
        if(fieldName != 'no') this.sortBy(fieldName);
    }

    sortBy(fieldName){
        let sortAscNew = this.sortField !== fieldName || !this.sortAsc;
        let sortOpportunityTable = [...this.opportunitiesTableData];
        sortOpportunityTable.sort((a, b)=>{
            let aa = a[fieldName];
            let bb = b[fieldName];
            let t1;
            let t2;
            if(fieldName === 'Name' || fieldName === 'Account_name__c' || fieldName === 'Channel__c' || fieldName === 'Type' || fieldName === 'StageName' || fieldName === 'Opportunity_Owner_Name__c' || fieldName === 'Existing_Quota__c'){
                if(aa == undefined) aa = 'AAA';
				if(bb == undefined) bb = 'AAA';
            }

            t1 = aa == bb;
			t2 = (!aa && bb) || (aa < bb);
			let res = t1 ? 0 : (sortAscNew ? -1 : 1) * (t2 ? 1 : -1);
			return res;
        })

        this.opportunitiesTableData = sortOpportunityTable;
        this.sortAsc = sortAscNew;
        this.sortField = fieldName;
    }

    iconOver(event){
        this.opportunityInfo = true;
    }

    icondown(){
        this.opportunityInfo = false;
    }

    mouseOverCountry(event){
        this.template.querySelector(".dropdown-content").style='display: block;';
    }

    mouseLeaveCountry(event){
        this.template.querySelector(".dropdown-content").style='display: none;';
    }

     /////////////////////
         // Use alerts instead of toasts (LEX only) to notify user
         
         @api notifyViaAlerts = false;

         isMultiEntry = false;
         maxSelectionSize = 2;
         initialSelection = [
             {
                 id: 'na',
                 sObjectType: 'na',
                 icon: 'standard:lightning_component',
                 title: '',
                 subtitle: 'Not a valid record'
             }
         ];
         errors = [];
         recentlyViewed = [];
         newRecordOptions = [
             { value: 'Account', label: 'New Account' },
             { value: 'Opportunity', label: 'New Opportunity' }
         ];
     
         /**
          * Loads recently viewed records and set them as default lookpup search results (optional)
          */

         @wire(getRecentlyViewed)
         getRecentlyViewed({ data }) {
             if (data) {
                 this.recentlyViewed = data;
                 this.initLookupDefaultResults();
             }
         }
     
         /**
          * Initializes the lookup default results with a list of recently viewed records (optional)
          */
         
         initLookupDefaultResults() {
             // Make sure that the lookup is present and if so, set its default results
             const lookup = this.template.querySelector('c-lookup');
             if (lookup) {
                 lookup.setDefaultResults(this.recentlyViewed);
             }
         }
     
         /**
          * Handles the lookup search event.
          * Calls the server to perform the search and returns the resuls to the lookup.
          * @param {event} event `search` event emmitted by the lookup
          */
         
         handleLookupSearch(event) {
             const lookupElement = event.target;
             // Call Apex endpoint to search for records and pass results to the lookup
             search(event.detail)
                 .then((results) => {
                     lookupElement.setSearchResults(results);
                 })
                 .catch((error) => {
                     this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                     // eslint-disable-next-line no-console
                     console.error('Lookup error', JSON.stringify(error));
                     this.errors = [error];
                 });
         }
     
         /**
          * Handles the lookup selection change
          * @param {event} event `selectionchange` event emmitted by the lookup.
          * The event contains the list of selected ids.
          */
         
         // eslint-disable-next-line no-unused-vars
         handleLookupSelectionChange(event) {
            const selectedOwner = event.detail;
            const rowNumner = parseInt(selectedOwner.selectedRow) + 1;
            const tableNum = parseInt(this.currentTable.slice(-1));
            const rowNum = this.MAX_ROWS_TO_SELECT * tableNum - this.MAX_ROWS_TO_SELECT + rowNumner;
            // console.log('Rafa - tableNum: ' + tableNum);
            // console.log('Rafa - rowNum: ' + rowNum);

            if(selectedOwner.selectedId.length > 0){
                this.opportunityData.map((opp) => {
                    if(opp.rowNumber === rowNum){
                        opp.ownerChange = selectedOwner.selectedId[0].id;
                    }
                })
            }else{
                this.opportunityData.map((opp) => {
                    if(opp.rowNumber === rowNum && opp.ownerChange !== ''){
                        opp.ownerChange = '';
                    }
                })
            }
         }
     
         // All functions below are part of the sample app form (not required by the lookup).
     
         handleLookupTypeChange(event) {
             this.initialSelection = [];
             this.errors = [];
             this.isMultiEntry = event.target.checked;
         }
     
         handleMaxSelectionSizeChange(event) {
             this.maxSelectionSize = event.target.value;
         }
     
         handleSubmit() {
             //this.checkForErrors();
             if (this.errors.length === 0) {
                 this.notifyUser('Success', 'The form was submitted.', 'success');
             }
         }
     
         handleClear() {
             this.initialSelection = [];
             this.errors = [];
         }
     
         checkForErrors() {
             this.errors = [];
             const selection = this.template.querySelector('c-lookup').getSelection();
             // Custom validation rule
             if (this.isMultiEntry && selection.length > this.maxSelectionSize) {
                 this.errors.push({ message: `You may only select up to ${this.maxSelectionSize} items.` });
             }
             // Enforcing required field
             if (selection.length === 0) {
                 this.errors.push({ message: 'Please make a selection.' });
             }
         }
     
         notifyUser(title, message, variant) {
             if (this.notifyViaAlerts) {
                 // Notify via alert
                 // eslint-disable-next-line no-alert
                 alert(`${title}\n${message}`);
             } else {
                 // Notify via toast (only works in LEX)
                 const toastEvent = new ShowToastEvent({ title, message, variant });
                 this.dispatchEvent(toastEvent);
             }
         }
}