import { LightningElement, api, wire } from 'lwc';
import search from '@salesforce/apex/OwnersManagementProcessCtrl.search';
import getRecentlyViewed from '@salesforce/apex/OwnersManagementProcessCtrl.getRecentlyViewed';
import IMAGES from "@salesforce/resourceUrl/InformationPNG";
import CX_Confirm_Submission_to_Deal_Reg__c from '@salesforce/schema/Lead.CX_Confirm_Submission_to_Deal_Reg__c';
import SystemModstamp from '@salesforce/schema/AcceptedEventRelation.SystemModstamp';


const columns = [
    {label : '#', fieldName : 'rowNumber',type : 'number', initialWidth: 20, cellAttributes: { alignment: 'left' }, value: false, value2: false},
    { label: 'Account Name', fieldName: 'Name', tepy: 'url', value: false, typeAttributes:{label:{fieldName: 'Type'}}, value2: false},
    { label: 'Type', fieldName: 'Type', value: false , value2: false},
    { label: 'Account Status', fieldName: 'accStatus', value: false , value2: false},
    { label: 'Billing Country', fieldName: 'BillingCountry', value: true , value2: false},
    //{ label: 'Next FY Expected Renewal ACV', fieldName: 'NextFyRenewal', value: false , value2: false},
    { label: 'Total Active ACV ($)', fieldName: 'Total_Active_ACV__c', type: 'currency', value: false , value2: false},
    { label: '# Of Open Opportunities', fieldName: 'openOpportunities', value: false , value2: false},
    {label: 'Existing Quota', fieldName: 'existingQuote', value: false, value2: false},
    {label: 'New Owner', fieldName: 'NewOwner', value: false, value2: true}
];

export default class OwnerManagementProcessAccountList extends LightningElement {

    showAccountTable = false
    accountInfo = false
    MAX_ROWS_TO_SELECT = 1000;
    @api getaccountdata;
    accountData;
    columns = columns;
    accountTableData;
    existtingRecords;
    selectedRecords = 0;
    billingCountryFilter = [];
    accountListToUpdate = [];
    tabelsObj = {};
    tabels = [];
    currentTable = ''
    newOwnerName = '';
    sortAsc = true;
    sortField = '';
    infoImage = IMAGES + '/speech_balloon_answer2.png';
    infoText = 'Please select the accounts for transferring and indicate the new owner, either at the top of the screen (mass transfer) on individually per account at the end of the row (specific transfer).';
    infoText2 = 'Note that if specific new owners are chosen, that selection will override the mass new owner.';
    infoText3 = 'After submitting the transfer, accounts with no renewal quota for the current year will be transferred automatically, along with any open opps and quotes belonging to the current account owner. However, if the accounts have renewal quota for the current year (last column), they will only be transferred after the quota reallocation will be confirmed by Finance and RevOps.';
    init(){
        if(this.getaccountdata.length > 0) this.showAccountTable = true;
        this.accountData = JSON.parse(JSON.stringify(this.getaccountdata));
        for(let i=0; i<this.accountData.length; i++){
            this.accountData[i].CX_NextFY_ExpectedRenewalACV__c = this.convertNumToStr(this.accountData[i].CX_NextFY_ExpectedRenewalACV__c);
            this.accountData[i].Total_Active_ACV__c = this.convertNumToStr(this.accountData[i].Total_Active_ACV__c);
            //this.accountData[i].of_Open_Opportunities__c = this.convertNumToStr(this.accountData[i].of_Open_Opportunities__c);
            this.accountData[i].accountUrl = 'https://checkmarx--uat.sandbox.lightning.force.com/lightning/r/Account/' + this.accountData[i].Id + '/view';
            this.accountData[i].rowNumber = i+1;
            this.accountData[i].ownerChange = '';
        }
        let numberOfAccount = this.accountData.length;
        this.existtingRecords = numberOfAccount;
        let numOfLoop = numberOfAccount / this.MAX_ROWS_TO_SELECT;
        for(let i=0; i<= numOfLoop; i++){
            let num = (i + 1) * this.MAX_ROWS_TO_SELECT;
            let tabelName = 'table' + (i+1);
            this.tabels.push({'value': tabelName, 'label': tabelName });
            this.tabelsObj[tabelName] = this.accountData.filter((acc) => {
                if(acc.rowNumber > (num - this.MAX_ROWS_TO_SELECT) && acc.rowNumber <= num){
                    return acc;
                }
            })
        }
        this.accountTableData = this.tabelsObj.table1;
        this.billingCountryFilter.push('All');
        this.accountTableData.forEach((acc) => {
           if (!this.billingCountryFilter.includes(acc.BillingCountry)){
            this.billingCountryFilter.push(acc.BillingCountry);
           }
        })
        this.currentTable = 'table1';
    }

    connectedCallback(){
		this.init();
        
	}
	
	renderedcallback(){
        
	}

    convertNumToStr(number){
        let numString = '';
        let dollarUS = Intl.NumberFormat("en-US", {style:'currency', currency:'USD', maximumFractionDigits: 0, minimumFractionDigits: 0});
        if(number !== undefined) numString = dollarUS.format(number);
        return numString;
    }

    butClick(){
        let numberOfAccount = this.accountTableData.length;
        let numOfLoop = numberOfAccount / this.MAX_ROWS_TO_SELECT;
        let obj = {};
        for(let i=0; i<= numOfLoop; i++){
            let num = (i + 1) * this.MAX_ROWS_TO_SELECT;
            let tabelName = 'table' + (i+1);
            obj[tabelName] = this.accountTableData.filter((acc) => {
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
            this.accountListToUpdate.push(eventCheck);
        }else{
            let accountToUpdate = this.accountListToUpdate.filter((acc) => acc.Id !== eventCheck.Id);
            this.accountListToUpdate = [];
            this.accountListToUpdate = accountToUpdate;
        }
        this.selectedRecords = this.accountListToUpdate.length;
        const selectedEvent = new CustomEvent('accountupdaterecord', {
            detail: this.accountListToUpdate
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
        
        if(this.accountListToUpdate.length > 0) this.accountListToUpdate = [];
        if(eventValue){
            this.accountListToUpdate = [...this.accountTableData];
        }

        this.selectedRecords = this.accountListToUpdate.length;
        const selectedEvent = new CustomEvent('accountupdaterecord', {
            detail: this.accountListToUpdate
        });
        this.dispatchEvent(selectedEvent);

        this.spinner=false;
    }

    handelChangeTable(event){
        let checkBoxElements = this.template.querySelector('[data-id="mainCheckbox"]');
        checkBoxElements.checked = false;
        let selectedTable = event.currentTarget.dataset.id;
        this.currentTable = selectedTable;
        this.accountTableData = this.tabelsObj[selectedTable];
       
    }

    handelSortBy(event){
        let selectedString = '';
        if(event === 'Billing Country'){
            selectedString = event;
        }else{
        let selectedColumn = event.target.outerText;
            const ttt = JSON.stringify(selectedColumn).replaceAll('\\','').replaceAll('"', '').split(' ');
            const num = ttt.length - 1;
            for(let i = 0; i < num; i++){
                if(i === 0) selectedString += ttt[i];
                if(i !== 0) selectedString += ' ' + ttt[i];
            }
        }
        let fieldName;
        switch(selectedString){
            case '#':
                fieldName = 'rowNumber'
                break
            case 'Account Name':
                fieldName = 'Name'
                break    
            case 'Type':
                fieldName = 'Type'
                break 
            case 'Account Status':
                fieldName = 'Account_Status__c'
                break
            case 'Next Fy Renewal':
                fieldName = 'CX_NextFY_ExpectedRenewalACV__c'
                break    
            case 'Total Active ACV ($)':
                fieldName = 'Total_Active_ACV__c'
                break
            case '# Of Open Opportunities':
                fieldName = 'of_Open_Opportunities__c'
                break
            case 'Existing Quota':
                fieldName = 'Existing_Quota__c'
                break   
            case 'Billing Country':
                fieldName = 'BillingCountry'
                break
            default:
                fieldName = 'no';
                return;
        }
        if(fieldName != 'no') this.sortBy(fieldName);
    }

    sortBy(fieldName){
        let sortAscNew = this.sortField != fieldName || !this.sortAsc;
        let sortAccountTable = [...this.accountTableData];
        sortAccountTable.sort((a, b)=>{
            let aa = a[fieldName];
            let bb = b[fieldName];
            let t1;
            let t2;
            if(fieldName === 'Name' || fieldName === 'Type' || fieldName === 'Account_Status__c' || fieldName === 'Account_Status__c' || fieldName === 'Existing_Quota__c' || fieldName === 'BillingCountry'){
                if(aa == undefined || aa == '') aa = 'AAA';
				if(bb == undefined || bb == '') bb = 'AAA';
            }

            if(fieldName === 'CX_NextFY_ExpectedRenewalACV__c' || fieldName === 'Total_Active_ACV__c' || fieldName === 'of_Open_Opportunities__c'){
                // if(aa !== undefined) aa = aa.toString();
                // if(bb !== undefined) bb = bb.toString();
                if(aa === undefined || aa === '') aa = -1;
				if(bb === undefined || bb === '') bb = -1;
                let aaType = typeof aa;
                let bbType = typeof bb;

				if(aaType === 'string'){
                    if(aa.includes(',')) aa = aa.replaceAll(',', '');
                    if(aa.includes('$')) aa = aa.replaceAll('$', '');
                }

				if(bbType === 'string'){
                    if(bb.includes(",")) bb = bb.replaceAll(',','');
                    if(bb.includes("$")) bb = bb.replaceAll('$','');
                } 
                if(aaType === 'string') aa = parseFloat(aa);
                if(bbType === 'string') bb = parseFloat(bb);

			}
            t1 = aa == bb;
			t2 = (!aa && bb) || (aa < bb);
			let res = t1 ? 0 : (sortAscNew ? -1 : 1) * (t2 ? 1 : -1);
			return res;
        })

        this.accountTableData = sortAccountTable;
        this.sortAsc = sortAscNew;
        this.sortField = fieldName;
    }

    handelBillingCountrySortBy(event){
        let selectedColumn = event.target.outerText;
        const ttt = JSON.stringify(selectedColumn).replaceAll('\\','').replaceAll('"', '').split(' ');
        const num = ttt.length - 1;
        let selectedString = '';
        for(let i = 0; i < num; i++){
            if(i === 0) selectedString += ttt[i];
            if(i !== 0) selectedString += ' ' + ttt[i];
        }
        if(selectedString === 'Billing Country'){
            this.handelSortBy(event);
        }
    }

    iconOver(event){
        this.accountInfo = true;
    }

    icondown(){
        this.accountInfo = false;
    }

    mouseOverCountry(event){
        this.template.querySelector(".dropdown-content").style='display: block;';
    }

    mouseLeaveCountry(event){
        this.template.querySelector(".dropdown-content").style='display: none;';
    }

    filterByCountry(event){
        const selectedContry = event.target.outerText;
        const curentTab = this.currentTable;
        let checkBoxElements = this.template.querySelector('[data-id="mainCheckbox"]');
        let checkboxes = this.template.querySelectorAll('[data-id="checkBoxRos"]');
        for(let i=0; i<checkboxes.length; i++){
            checkboxes[i].checked = false; 
        }
        this.accountListToUpdate = [];
        checkBoxElements.checked = false;
        if(selectedContry === 'All'){     
            this.accountTableData = this.tabelsObj[curentTab];
        }else{
            let filtAccountTable = [];
            this.tabelsObj[curentTab].map((acc)=>{
                if(acc.BillingCountry === selectedContry) filtAccountTable.push(acc);
            })
            this.accountTableData = filtAccountTable;
        }
        this.template.querySelector(".dropdown-content").style='display: none;';
        //document.getElementsByClassName("dropdown-content").style.backgroundColor = "red";
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

            if(selectedOwner.selectedId.length > 0){
                this.accountData.map((acc) => {
                    if(acc.rowNumber === rowNum){
                        acc.ownerChange = selectedOwner.selectedId[0].id;
                    }
                })
            }else{
                this.accountData.map((acc) => {
                    if(acc.rowNumber === rowNum && acc.ownerChange !== ''){
                        acc.ownerChange = '';
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