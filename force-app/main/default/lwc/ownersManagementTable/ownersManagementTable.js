import {LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import search from '@salesforce/apex/OwnersManagementProcessCtrl.search';
import getRecentlyViewed from '@salesforce/apex/OwnersManagementProcessCtrl.getRecentlyViewed';
import updateRecords from '@salesforce/apex/OwnersManagementProcessCtrl.updateRecords';
import LightningConfirm from 'lightning/confirm';
import Relationship_Status__c from '@salesforce/schema/Account_Planning__c.Relationship_Status__c';

export default class OwnersManagementTable extends LightningElement {
    spinner = false;
    showAccountTable = false
    profileSalesOperation = false;
    assigmentReasonList = [];
    currentOwner;
    newAssigment;
    selectedOwner;
    selectedApproverUser;
    dataForAccount
    dataForOpportunity
    updateAccout;
    accountIdList;
    updateOpportunity;
    @api childtabledata;


    init(){
        this.dataForAccount = JSON.parse(JSON.stringify(this.childtabledata['Account']));
        this.dataForOpportunity = JSON.parse(JSON.stringify(this.childtabledata['Opportunity']));
        this.currentOwnerId = this.childtabledata['currentOwnerId'];
        this.currentOwner = this.childtabledata['currentOwner'];
        let assigmentData = this.childtabledata['assignmentReasonList'];
        let profile_Id = this.childtabledata['profileId'];
        //00e3z000001BFVL
        if(profile_Id == '00e20000000n38qAAA' || profile_Id == '00eD0000001pF4UIAU') this.profileSalesOperation = true;
        let allAssigment = assigmentData.map(data => { return {label:data.label, value:data.value}}).filter(data => data.value !== undefined);
        this.assigmentReasonList = allAssigment;
    }

    async handleConfirm(){
        let run = true;
        let mess = '';
        const accArray = (this.updateAccout != undefined) ? JSON.parse(JSON.stringify(this.updateAccout)) : [];
        const oppArray = (this.updateOpportunity != undefined) ? JSON.parse(JSON.stringify(this.updateOpportunity)) : [];
        if((accArray.length > 0 || oppArray.length > 0) && (this.selectedOwner == undefined || this.selectedOwner.selectedId == undefined || this.selectedOwner.selectedId.length == 0)){
            for(let i = 0; accArray.length > i; i++){
                if(accArray[i]['ownerChange'] == ''){run = false; this.spinner = false; break;}
            }
            for(let i = 0; oppArray.length > i; i++){
                if(oppArray[i].ownerChange == ''){run = false; this.spinner = false; break;}
            }
            mess = 'No Owner Selected';
        }
        if(this.newAssigment == undefined || this.newAssigment == '') {
            run = false;
            this.spinner = false;
            mess = 'No assignment reason selected'
        }
        if(accArray.length == 0 && oppArray.length == 0){
            run = false;
            this.spinner = false;
            mess = 'No Records Selected'
        }
        if(run){
            let result = await LightningConfirm.open({
                message: 'You are about to transfer ' + accArray.length +' accounts and ' + oppArray.length + ' opps from ' + this.currentOwner + '. Please confirm this action to proceed.',
                variant: 'header',
                label: 'Note',
                theme: 'shade'
            });

            if(result){
                this.handelUpdateRecords();
            }
        }else{
            try {
                const selectedEvent = new CustomEvent('error', {
                    detail: {'title':"Error",'meesage':mess}
                });
                this.dispatchEvent(selectedEvent);

            } catch (error) {
                console.log(JSON.stringify(error));
            }
        }
    }

    connectedCallback(){
		this.init();
        this.initLookupDefaultResults();  
	}

    handleNewAssigmentChange(event){
        this.newAssigment = event.detail.value;
    }
	
    handelAccountListChange(event){
        this.updateAccout = [];
        let accountIdArray = [];
        this.updateAccout = event.detail;
        for(const acc of this.updateAccout){
            accountIdArray.push(acc.Id);
        }
        this.accountIdList = [];
        this.accountIdList = accountIdArray;
		// console.log('Rafa - handelAccountListChange this.updateAccout: ' + JSON.stringify(this.updateAccout));
    }

    handelopportunityListChange(event){
        this.updateOpportunity = [];
        this.updateOpportunity = event.detail;
		// console.log('Rafa - handelopportunityListChange this.updateOpportunity: ' + JSON.stringify(this.updateOpportunity));
    }

    handelUpdateRecords(event){   
        let run = true;
        let mess = '';

        const accArray = (this.updateAccout != undefined) ? JSON.parse(JSON.stringify(this.updateAccout)) : [];
        const oppArray = (this.updateOpportunity != undefined) ? JSON.parse(JSON.stringify(this.updateOpportunity)) : [];
        if((accArray.length > 0 || oppArray.length > 0) && (this.selectedOwner == undefined || this.selectedOwner.selectedId == undefined || this.selectedOwner.selectedId.length == 0)){
            for(let i = 0; accArray.length > i; i++){
                if(accArray[i]['ownerChange'] == ''){run = false; this.spinner = false; break;}
            }
            for(let i = 0; oppArray.length > i; i++){
                if(oppArray[i].ownerChange == ''){run = false; this.spinner = false; break;}
            }
            mess = 'No Owner Selected';
        }
        if(this.newAssigment == undefined || this.newAssigment == '') {
            run = false;
            this.spinner = false;
            mess = 'No assignment reason selected'
        }
        if(accArray.length == 0 && oppArray.length == 0){
            run = false;
            this.spinner = false;
            mess = 'No Records Selected'
        }
        if(run){
            this.template.querySelector('[data-id="updateRecords"]').className='disUpdate';
            this.template.querySelector('[data-id="updateRecordAId"]').className='updateRecordDisable';
            const objectData = {'currentOwnerId': this.currentOwnerId, 'selectedOwner': (this.selectedOwner != undefined) ? this.selectedOwner.selectedId[0].id : null, 'additionalApprover': (this.selectedApproverUser != undefined) ? this.selectedApproverUser.selectedId[0].id : null, 'newAssigment': (this.newAssigment != undefined) ? this.newAssigment : null, 'account': (this.updateAccout != undefined) ? this.updateAccout : null, 'opportunity': (this.updateOpportunity != undefined) ? this.updateOpportunity : null};
             updateRecords({dataObj: objectData})
            .then((data) => {
                // if(data['succeeded'] == undefined) {
                //     console.log('In not succeded');
                //     console.log('data: ' + data);
                //     console.log('status End: ' + data); 
                // }
                this.pushMassage(data);
                this.spinner = false;
            })            
            this.template.querySelector('[data-id="updateRecords"]').className='updateBut';
            this.template.querySelector('[data-id="updateRecordAId"]').className='updateRecordA';
        }else{
            try {
                const selectedEvent = new CustomEvent('error', {
                    detail: {'title':"Error",'meesage':mess}
                });
                this.dispatchEvent(selectedEvent);

            } catch (error) {
                console.log(JSON.stringify(error));
            }
        }
     }

     pushMassage(mess){
            if(mess.succeeded != undefined){
            try {
                const selectedEvent = new CustomEvent('tablechange', {
                    detail: {'title':"In Progress",'meesage':"Your request is in progress. You will receive email confirmations of the records that were transferred automatically, failed to transfer or went into approvals."}
                });
                this.dispatchEvent(selectedEvent);

            } catch (error) {
                console.log(JSON.stringify(error));
            }
        }else{
            for(const m in mess){
                const selectedErrorEvent = new CustomEvent('error', {
                    detail: {'title':"Error",'meesage':mess[m]}
                });
                    this.dispatchEvent(selectedErrorEvent);  
            }
        }
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

    handleLookupByProfileSearch(event) {
        const lookupElement = event.target;
        //console.log('event: ' + JSON.stringify(event.detail));
        // Call Apex endpoint to search for records and pass results to the lookup
        search({searchTerm: event.detail['searchTerm'], byProfile: 'true', selectedIds: event.detail['selectedIds']})
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
        // console.log('handleLookupSelectionChange recordId: ' + JSON.stringify(selectedOwner));
        this.selectedOwner = selectedOwner;
        //this.checkForErrors();
    }

    handleLookupProfileSelectionChange(event) {
        const selectApprover = event.detail;
        this.selectedApproverUser = selectApprover;
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