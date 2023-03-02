import { LightningElement, api, track } from 'lwc';
import init from '@salesforce/apex/QuotaTransitionProcessCtrl.init';
import updateQuotaPlanning from '@salesforce/apex/QuotaTransitionProcessCtrl.updateQuotaPlanning';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class QuotaTransitionProcess extends LightningElement {
    dataIsSet = false;
    spinner = false; // 
    @api recordId; // the recoud id from the current page 
    initIsRunning = false; // check if the init function is wall ready runs 
    quotePlanningObject; // all the quota planning thet active from the database 
    currentPlanningQuota; // the current quota planning the one from the page 
    rsmFilter = false; tbhFilter =false; postionFilter = false; // boolean thet open or close the cards filter 
    enableBlur = true; // boolean thet help to open and close the card filter in the right way
    rsmOptions=[]; @track filterRsmOptions = []; selectedRsm = ''; rsmDisabled=false; rsmDataId = ''; // all the var for rsm
    tbhOptions=[]; @track filterTbhOptions = []; selectedTbh = ''; tbhDisabled=false; tbhDataId = ''; // all the var for tbh
    positionOptions=[]; @track filterPositionOptions = []; selectedPosition = ''; positionDisabled=false; quotaSelected = {}; // all the var for position
    resultTable = []; // Holding all the result
    tableTemp = false; // boolean thet open or close the table
    compaerTable = false; // boolean thet open or close the comaer table
    isModalOpen = false;
    quotaTransfers = {};
    notComment = true;
    noteMess  = '';
    disableSaveButt = true;

    // set recordId(value){
    //     this._recordId = value;
    // }

    // @api get recordId(){
    //     return this._recordId;
    // }
    connectedCallback(){
    }

    renderedCallback(){
        if(this.recordId != undefined && this.recordId != '' && !this.initIsRunning){
            this.initData();
            this.initIsRunning = true;
        }
    }

    // Get the data from the back end use QuotaTransitionProcessCtrl class with init function
    initData(){
        init({quotaPlannigId : this.recordId}).then((data) => {
            if(data.Succses){
                const rsmOject = data.rsmList;
                const tbhOject = data.tbhList;
                const positionOject = data.rsmPositionIdList;
                this.quotePlanningObject = data.quotePlanning;
                this.currentPlanningQuota = data.currentQuotaPlanning;

                let rsmArray = [];
                let tbhArray = [];
                let positionArray = [];

                for(const rsm in rsmOject){
                    rsmArray.push({'rsmId':rsm, 'name':rsmOject[rsm]});
                }

                for(const tbh in tbhOject){
                    tbhArray.push({'tbhId':tbh, 'name':tbhOject[tbh]});
                }

                for(const position in positionOject){
                    positionArray.push({'positionId':position});
                }

                this.rsmOptions = rsmArray;
                this.tbhOptions = tbhArray;
                this.positionOptions = positionArray;

                if(this.rsmOptions.length || 0 && this.tbhOptions.length || 0 && this.positionOptions.length || 0) this.dataIsSet = true;
            }
        })
    }

    // Happens qhen mous is over, add the class onRowBlue
    rowOnMousOver(e) {
        const idTarget = e.target.dataset.targetId;
        this.template.querySelector(`[data-target-id="${idTarget}"]`).classList.add('onRowBlue');
        this.enableBlur = false; 
    }

    // Happens qhen mous is leave, remove the class onRowBlue
    rowOnMousLeave(e) {
        const idTarget = e.target.dataset.targetId;
        this.template.querySelector(`[data-target-id="${idTarget}"]`).classList.remove('onRowBlue');
        this.enableBlur = true; 
    }

    // RSM Function
    // Happens when search quota by rsm show 5 quota based the on the letters thet user entered
    rsmHandelChange(event){
        this.filterRsmOptions = [];
        this.selectedRsm = '';
        this.rsmDataId = '';
        this.tbhDisabled = false;
        this.positionDisabled = false;
        let rsmChar = event.detail.value;
        if(rsmChar.length > 1){
            this.rsmOptions.filter((rm) => {
                let rmStr = rm.name.toLowerCase();
                if(rmStr.indexOf(rsmChar.toLowerCase()) != -1 && this.filterRsmOptions.length < 5) {this.filterRsmOptions.push(rm);}  
            })
        }
        this.rsmFilter = true;
    }

    // Happens when click with the mous, Passes the selected Rsm
    rowOnMousUpRsm(e){
        this.selectedRsm = e.target.dataset.targetId;
        this.rsmDataId = e.target.dataset.id;
        this.rsmFilter = false;
        this.enableBlur = true;
        this.tbhDisabled = true;
        this.positionDisabled = true;
    }

    // Close rsmFilter enableBlur is true, Happens when leave the filed 
    rsmHandelBlur(){
        if(this.enableBlur){
            this.rsmFilter = false;
        }
    }

    // TBH Function
    // Happens when search quota by tbh show 5 quota based the on the letters thet user entered
    tbhHandelChange(e){
        this.filterTbhOptions = [];
        this.selectedTbh = '';
        this.tbhDataId = '';
        this.rsmDisabled = false;
        this.positionDisabled = false;
        let tbhChar = e.detail.value;
        if(tbhChar.length > 1) {
            this.tbhOptions.filter((tb) => {
                let tbStr = tb.name.toLowerCase();
                if(tbStr.indexOf(tbhChar.toLowerCase()) != -1 && this.filterTbhOptions.length < 5) {this.filterTbhOptions.push(tb)}
            })
        }
        this.tbhFilter = true;
    }

    // Happens when click with the mous, Passes the selected tbh
    rowOnMousUpTbh(e){
        this.selectedTbh = e.target.dataset.targetId;
        this.tbhDataId = e.target.dataset.id;
        this.tbhFilter = false;
        this.enableBlur = true;
        this.rsmDisabled = true; 
        this.positionDisabled = true;
    }

    // Close tbhFilter enableBlur is true, Happens when leave the filed 
    tbhHandelBlur(){
        if(this.enableBlur){
            this.tbhFilter = false;
        }
    }

    /// RSM Position
    // Happens when search quota by position  
    positionHandelChange(e){
        this.filterPositionOptions = [];
        this.selectedPosition = '';
        this.rsmDisabled = false;
        this.tbhDisabled = false;
        let positionChar = e.detail.value;
        if(positionChar.length > 1) {
            this.positionOptions.filter((rsmP) => {
                let positionStr = rsmP.positionId.toLowerCase();
                if(positionStr.indexOf(positionChar.toLowerCase()) != -1 && this.filterPositionOptions.length < 5) {this.filterPositionOptions.push(rsmP)}
            })
        }
        this.postionFilter = true;
    }

    // Happens when click with the mous, Passes the selected position id 
    rowOnMousUpPosition(e){
        const idTarget = e.target.dataset.targetId;
        this.selectedPosition = idTarget;
        this.postionFilter = false;
        this.enableBlur = true;
        this.rsmDisabled = true; 
        this.tbhDisabled = true;
    }

    // Close postionFilter enableBlur is true, Happens when leave the filed 
    positionHandelBlur(){
        if(this.enableBlur){
            this.postionFilter = false;
        }
    }

    /// Submit
    // Open the resultTable with the elevant records 
    handelSubmit() {
        this.compaerTable = false;
        this.quotaSelected = {};
        let resultrows = [];
        if(this.rsmDataId != ''){
            this.quotePlanningObject.filter((row)=>{
                if(row.RSM__c == this.rsmDataId) {
                    if(row.RSM__r != undefined) row.rsmName = row.RSM__r.Name;
                    resultrows.push(row);
                }
            })
        }else if(this.tbhDataId != ''){
            this.quotePlanningObject.filter((row)=>{
                if(row.TBH__c == this.tbhDataId) {
                    if(row.TBH__r != undefined) row.tbhName = row.TBH__r.Name;
                    resultrows.push(row);
                }
            })
        }else if(this.selectedPosition != ''){
            this.quotePlanningObject.filter((row)=>{
                if(row.RSM_PositionId__c == this.selectedPosition){
                    if(row.RSM__r != undefined) row.rsmName = row.RSM__r.Name;
                    resultrows.push(row);
                }
            })
        }else{
            return;
        }

        this.resultTable = resultrows;
        this.tableTemp = true;
    }

    /// table
    // Passes to the quotePlanningObject the selected quoraPlanning and open or close the compaer table. Prevents double selection 
    // if the region of the selected and current planningQuota is not equal open the popup note    
    handelClick(e){
        let onlyOneMarkt = true;
        if(e.target.checked){
            this.template.querySelectorAll('[data-id="tdtable"]').forEach((row)=>{
                if(row.dataset.targetId != e.target.dataset.targetId && row.checked){
                    this.template.querySelector(`[data-target-id =${e.target.dataset.targetId}]`).checked = false;
                    onlyOneMarkt = false;
                }
            })
            if(onlyOneMarkt) {
                for(let quotaPl in this.quotePlanningObject){
                   if(this.quotePlanningObject[quotaPl].Id == e.target.dataset.targetId){
                       this.quotaSelected = this.quotePlanningObject[quotaPl];
                       this.tableTemp = false;
                       if(this.quotaSelected.Region__c != this.currentPlanningQuota.Region__c){
                            this.notComment = true;
                            this.noteMess = 'You have selected a record from a different region. Click "Continue" or "Back" for changes.';
                            this.isModalOpen = true;
                       }
                   }  
                }
               this.compaerTable = true
           }
        }else{
            this.compaerTable = false;
            this.quotaSelected = {};
        }
    }

    // Close the popup note , clode the compaer table and  uncheck the comboBox
    closeModal(){
        this.compaerTable = false;
        this.isModalOpen = false;
        this.tableTemp = true;
        this.template.querySelectorAll('[data-id="tdtable"]').forEach((row)=>{
            if(row.checked){
                this.template.querySelector(`[data-target-id =${row.dataset.targetId}]`).checked = false;
                onlyOneMarkt = false;
            }
        })
    }

    // Close the note and continue
    submitDetails(){
        this.isModalOpen = false;
    }

    // Transfer values in the selected fields
    moveQuotaHandel(e){
        let sQuota1Nb = this.template.querySelector('[data-id="SQ1NB"]').value;
        let sQuota1NbLi = this.template.querySelector('[data-id="SQ1NBLi"]').value;
        let sQuota2Nb = this.template.querySelector('[data-id="SQ2NB"]').value;
        let sQuota2NbLi = this.template.querySelector('[data-id="SQ2NBLi"]').value;
        let sQuota3Nb = this.template.querySelector('[data-id="SQ3NB"]').value;
        let sQuota3NbLi = this.template.querySelector('[data-id="SQ3NBLi"]').value;
        let sQuota4Nb = this.template.querySelector('[data-id="SQ4NB"]').value;
        let sQuota4NbLi = this.template.querySelector('[data-id="SQ4NBLi"]').value;

        let sQuota1Up = this.template.querySelector('[data-id="SQ1Up"]').value;
        let sQuota1UPLi = this.template.querySelector('[data-id="SQ1UPLi"]').value;
        let sQuota2Up = this.template.querySelector('[data-id="SQ2Up"]').value;
        let sQuota2UPLi = this.template.querySelector('[data-id="SQ2UPLi"]').value;
        let sQuota3Up = this.template.querySelector('[data-id="SQ3Up"]').value;
        let sQuota3UPLi = this.template.querySelector('[data-id="SQ3UPLi"]').value;
        let sQuota4Up = this.template.querySelector('[data-id="SQ4Up"]').value;
        let sQuota4UPLi = this.template.querySelector('[data-id="SQ4UPLi"]').value;

        let tQuota1Nb = this.template.querySelector('[data-id="TQ1NB"]').value;
        let tQuota2Nb = this.template.querySelector('[data-id="TQ2NB"]').value;
        let tQuota3Nb = this.template.querySelector('[data-id="TQ3NB"]').value;
        let tQuota4Nb = this.template.querySelector('[data-id="TQ4NB"]').value;

        let tQuota1Up = this.template.querySelector('[data-id="TQ1Up"]').value;
        let tQuota2Up = this.template.querySelector('[data-id="TQ2Up"]').value;
        let tQuota3Up = this.template.querySelector('[data-id="TQ3Up"]').value;
        let tQuota4Up = this.template.querySelector('[data-id="TQ4Up"]').value;

        let newTQuota1Nb;
        let newTQuota2Nb;
        let newTQuota3Nb;
        let newTQuota4Nb;

        let newTQuota1Up;
        let newTQuota2Up;
        let newTQuota3Up;
        let newTQuota4Up;

        let changeIsMade = false;
        if(sQuota1Nb != '' && Number(sQuota1NbLi) >= Number(sQuota1Nb)) changeIsMade = true
        if(sQuota2Nb != '' && Number(sQuota2NbLi) >= Number(sQuota2Nb)) changeIsMade = true
        if(sQuota3Nb != '' && Number(sQuota3NbLi) >= Number(sQuota3Nb)) changeIsMade = true
        if(sQuota4Nb != '' && Number(sQuota4NbLi) >= Number(sQuota4Nb)) changeIsMade = true

        if(sQuota1Up != '' && Number(sQuota1UPLi) >= Number(sQuota1Up)) changeIsMade = true
        if(sQuota2Up != '' && Number(sQuota2UPLi) >= Number(sQuota2Up)) changeIsMade = true
        if(sQuota3Up != '' && Number(sQuota3UPLi) >= Number(sQuota3Up)) changeIsMade = true
        if(sQuota4Up != '' && Number(sQuota4UPLi) >= Number(sQuota4Up)) changeIsMade = true

        if(sQuota1Nb != '' && Number(sQuota1NbLi) >= Number(sQuota1Nb)) {newTQuota1Nb = Number(sQuota1Nb) + Number(tQuota1Nb);}else if(sQuota1Nb != '') this.popUpMess('The selected amount is greater then the Q1 NB balance', false);
        if(sQuota2Nb != '' && Number(sQuota2NbLi) >= Number(sQuota2Nb)) {newTQuota2Nb = Number(sQuota2Nb) + Number(tQuota2Nb);}else if(sQuota2Nb != '') this.popUpMess('The selected amount is greater then the Q2 NB balance', false);
        if(sQuota3Nb != '' && Number(sQuota3NbLi) >= Number(sQuota3Nb)) {newTQuota3Nb = Number(sQuota3Nb) + Number(tQuota3Nb);}else if(sQuota3Nb != '') this.popUpMess('The selected amount is greater then the Q3 NB balance', false);
        if(sQuota4Nb != '' && Number(sQuota4NbLi) >= Number(sQuota4Nb)) {newTQuota4Nb = Number(sQuota4Nb) + Number(tQuota4Nb);}else if(sQuota4Nb != '') this.popUpMess('The selected amount is greater then the Q4 NB balance', false);

        if(sQuota1Up != '' && Number(sQuota1UPLi) >= Number(sQuota1Up)) {newTQuota1Up = Number(sQuota1Up) + Number(tQuota1Up);}else if(sQuota1Up != '') this.popUpMess('The selected amount is greater then the Q1 upsell balance', false);
        if(sQuota2Up != '' && Number(sQuota2UPLi) >= Number(sQuota2Up)) {newTQuota2Up = Number(sQuota2Up) + Number(tQuota2Up);}else if(sQuota2Up != '') this.popUpMess('The selected amount is greater then the Q2 upsell balance', false);
        if(sQuota3Up != '' && Number(sQuota3UPLi) >= Number(sQuota3Up)) {newTQuota3Up = Number(sQuota3Up) + Number(tQuota3Up);}else if(sQuota3Up != '') this.popUpMess('The selected amount is greater then the Q3 upsell balance', false);
        if(sQuota4Up != '' && Number(sQuota4UPLi) >= Number(sQuota4Up)) {newTQuota4Up = Number(sQuota4Up) + Number(tQuota4Up);}else if(sQuota4Up != '') this.popUpMess('The selected amount is greater then the Q4 upsell balance', false);

        let objectTransferNBQ1 = {};
        let objectTransferNBQ2 = {};
        let objectTransferNBQ3 = {};
        let objectTransferNBQ4 = {};

        let objectTransferUpQ1 = {};
        let objectTransferUpQ2 = {};
        let objectTransferUpQ3 = {};
        let objectTransferUpQ4 = {};

        if((newTQuota1Nb != '' && newTQuota1Nb != undefined)){
            this.template.querySelector('[data-id="TQ1NB"]').value = newTQuota1Nb;
            this.template.querySelector('[data-id="SQ1NBLi"]').value = Number(sQuota1NbLi) - Number(sQuota1Nb);
            objectTransferNBQ1.title = 'Quota Transfer';
            if(this.quotaTransfers.Q1NB == undefined) {objectTransferNBQ1.moneyPassed = Number(sQuota1Nb);}
            if(this.quotaTransfers.Q1NB != undefined) {objectTransferNBQ1.moneyPassed = Number(sQuota1Nb) + this.quotaTransfers.Q1NB.moneyPassed;}
            objectTransferNBQ1.newTargetAmount = newTQuota1Nb;
            objectTransferNBQ1.newSourceAmount = Number(sQuota1NbLi) - Number(sQuota1Nb);
            objectTransferNBQ1.fieldNameChanged = 'Q1 NB';
            objectTransferNBQ1.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferNBQ1.targetRecord = this.quotaSelected.Name;
            objectTransferNBQ1.lastSourceAmount = this.currentPlanningQuota.Q1_NB_Target_ACV__c;
            objectTransferNBQ1.lastTargetAmount = this.quotaSelected.Q1_NB_Target_ACV__c;
            objectTransferNBQ1.sourceId = this.currentPlanningQuota.Id;
            objectTransferNBQ1.targetId = this.quotaSelected.Id;
            this.quotaTransfers.Q1NB = objectTransferNBQ1;
            changeIsMade = true;
        }

        if((newTQuota2Nb != '' && newTQuota2Nb != undefined)){
            this.template.querySelector('[data-id="TQ2NB"]').value = newTQuota2Nb;
            this.template.querySelector('[data-id="SQ2NBLi"]').value = Number(sQuota2NbLi) - Number(sQuota2Nb);
            objectTransferNBQ2.title = 'Quota Transfer';
            if(this.quotaTransfers.Q2NB == undefined) {objectTransferNBQ2.moneyPassed = Number(sQuota2Nb);}
            if(this.quotaTransfers.Q2NB != undefined) {objectTransferNBQ2.moneyPassed = Number(sQuota2Nb) + this.quotaTransfers.Q2NB.moneyPassed;}
            objectTransferNBQ2.newTargetAmount = newTQuota2Nb;
            objectTransferNBQ2.newSourceAmount = Number(sQuota2NbLi) - Number(sQuota2Nb);
            objectTransferNBQ2.fieldNameChanged = 'Q2 NB';
            objectTransferNBQ2.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferNBQ2.targetRecord = this.quotaSelected.Name;
            objectTransferNBQ2.lastSourceAmount = this.currentPlanningQuota.Q2_NB_Target_ACV__c;
            
            objectTransferNBQ2.lastTargetAmount = this.quotaSelected.Q2_NB_Target_ACV__c;
            
            objectTransferNBQ2.sourceId = this.currentPlanningQuota.Id;
            objectTransferNBQ2.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q2NB = objectTransferNBQ2;
            changeIsMade = true;
        }

        if(newTQuota3Nb != '' && newTQuota3Nb != undefined){
            this.template.querySelector('[data-id="TQ3NB"]').value = newTQuota3Nb;
            this.template.querySelector('[data-id="SQ3NBLi"]').value = Number(sQuota3NbLi) - Number(sQuota3Nb);
            objectTransferNBQ3.title = 'Quota Transfer';
            if(this.quotaTransfers.Q3NB == undefined) {objectTransferNBQ3.moneyPassed = Number(sQuota3Nb);}
            if(this.quotaTransfers.Q3NB != undefined) {objectTransferNBQ3.moneyPassed = Number(sQuota3Nb) + this.quotaTransfers.Q3NB.moneyPassed;}
            objectTransferNBQ3.newTargetAmount = newTQuota3Nb;
            objectTransferNBQ3.newSourceAmount = Number(sQuota3NbLi) - Number(sQuota3Nb);
            objectTransferNBQ3.fieldNameChanged = 'Q3 NB';
            objectTransferNBQ3.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferNBQ3.targetRecord = this.quotaSelected.Name;
            objectTransferNBQ3.lastSourceAmount = this.currentPlanningQuota.Q3_NB_Target_ACV__c;
            objectTransferNBQ3.lastTargetAmount = this.quotaSelected.Q3_NB_Target_ACV__c;
            objectTransferNBQ3.sourceId = this.currentPlanningQuota.Id;
            objectTransferNBQ3.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q3NB = objectTransferNBQ3;
            changeIsMade = true;
        }

        if(newTQuota4Nb != '' && newTQuota4Nb != undefined){
            this.template.querySelector('[data-id="TQ4NB"]').value = newTQuota4Nb;
            this.template.querySelector('[data-id="SQ4NBLi"]').value = Number(sQuota4NbLi) - Number(sQuota4Nb);
            objectTransferNBQ4.title = 'Quota Transfer';
            if(this.quotaTransfers.Q4NB == undefined) {objectTransferNBQ4.moneyPassed = Number(sQuota4Nb);}
            if(this.quotaTransfers.Q4NB != undefined) {objectTransferNBQ4.moneyPassed = Number(sQuota4Nb) + this.quotaTransfers.Q4NB.moneyPassed;}
            objectTransferNBQ4.newTargetAmount = newTQuota4Nb;
            objectTransferNBQ4.newSourceAmount = Number(sQuota4NbLi) - Number(sQuota4Nb);
            objectTransferNBQ4.fieldNameChanged = 'Q4 NB';
            objectTransferNBQ4.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferNBQ4.targetRecord = this.quotaSelected.Name;
            objectTransferNBQ4.lastSourceAmount = this.currentPlanningQuota.Q4_NB_Target_ACV__c;
            objectTransferNBQ4.lastTargetAmount = this.quotaSelected.Q4_NB_Target_ACV__c;
            objectTransferNBQ4.sourceId = this.currentPlanningQuota.Id;
            objectTransferNBQ4.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q4NB = objectTransferNBQ4;
            changeIsMade = true;
        }

        if(newTQuota1Up != '' && newTQuota1Up != undefined){
            this.template.querySelector('[data-id="TQ1Up"]').value = newTQuota1Up;
            this.template.querySelector('[data-id="SQ1UPLi"]').value = Number(sQuota1UPLi) - Number(sQuota1Up);          
            objectTransferUpQ1.title = 'Quota Transfer';
            if(this.quotaTransfers.Q1UP == undefined) {objectTransferUpQ1.moneyPassed = Number(sQuota1Up); }
            if(this.quotaTransfers.Q1UP != undefined) {objectTransferUpQ1.moneyPassed = Number(sQuota1Up) + this.quotaTransfers.Q1UP.moneyPassed;}
            objectTransferUpQ1.newTargetAmount = newTQuota1Up;
            objectTransferUpQ1.newSourceAmount = Number(sQuota1UPLi) - Number(sQuota1Up);
            objectTransferUpQ1.fieldNameChanged = 'Q1 Upsell';
            objectTransferUpQ1.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferUpQ1.targetRecord = this.quotaSelected.Name;
            objectTransferUpQ1.lastSourceAmount = this.currentPlanningQuota.Q1_Upsell_Target_ACV__c;
            objectTransferUpQ1.lastTargetAmount = this.quotaSelected.Q1_Upsell_Target_ACV__c;
            objectTransferUpQ1.sourceId = this.currentPlanningQuota.Id;
            objectTransferUpQ1.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q1UP = objectTransferUpQ1;
            changeIsMade = true;
        }
        if(newTQuota2Up != '' && newTQuota2Up != undefined){
            this.template.querySelector('[data-id="TQ2Up"]').value = newTQuota2Up;
            this.template.querySelector('[data-id="SQ2UPLi"]').value = Number(sQuota2UPLi) - Number(sQuota2Up);
            objectTransferUpQ2.title = 'Quota Transfer';
            if(this.quotaTransfers.Q2UP == undefined) {objectTransferUpQ2.moneyPassed = Number(sQuota2Up);}
            if(this.quotaTransfers.Q2UP != undefined) {objectTransferUpQ2.moneyPassed = Number(sQuota2Up) + this.quotaTransfers.Q2UP.moneyPassed;}
            objectTransferUpQ2.newTargetAmount = newTQuota2Up;
            objectTransferUpQ2.newSourceAmount = Number(sQuota2UPLi) - Number(sQuota2Up);
            objectTransferUpQ2.fieldNameChanged = 'Q2 Upsell';
            objectTransferUpQ2.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferUpQ2.targetRecord = this.quotaSelected.Name;
            objectTransferUpQ2.lastSourceAmount = this.currentPlanningQuota.Q2_Upsell_Target_ACV__c;
            
            objectTransferUpQ2.lastTargetAmount = this.quotaSelected.Q2_Upsell_Target_ACV__c;
            objectTransferUpQ2.sourceId = this.currentPlanningQuota.Id;
            objectTransferUpQ2.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q2UP = objectTransferUpQ2;
            changeIsMade = true;
        }
        if(newTQuota3Up != '' && newTQuota3Up != undefined){
            this.template.querySelector('[data-id="TQ3Up"]').value = newTQuota3Up;
            this.template.querySelector('[data-id="SQ3UPLi"]').value = Number(sQuota3UPLi) - Number(sQuota3Up);
            objectTransferUpQ3.title = 'Quota Transfer';
            if(this.quotaTransfers.Q3UP == undefined) {objectTransferUpQ3.moneyPassed = Number(sQuota3Up);}
            if(this.quotaTransfers.Q3UP != undefined) {objectTransferUpQ3.moneyPassed = Number(sQuota3Up) + this.quotaTransfers.Q3UP.moneyPassed;}
            objectTransferUpQ3.newTargetAmount = newTQuota3Up;
            objectTransferUpQ3.newSourceAmount = Number(sQuota3UPLi) - Number(sQuota3Up);
            objectTransferUpQ3.fieldNameChanged = 'Q3 Upsell';
            objectTransferUpQ3.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferUpQ3.targetRecord = this.quotaSelected.Name;
            objectTransferUpQ3.lastSourceAmount = this.currentPlanningQuota.Q3_Upsell_Target_ACV__c;
            
            objectTransferUpQ3.lastTargetAmount = this.quotaSelected.Q3_Upsell_Target_ACV__c;
            objectTransferUpQ3.sourceId = this.currentPlanningQuota.Id;
            objectTransferUpQ3.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q3UP = objectTransferUpQ3;
            changeIsMade = true;
        }
        if(newTQuota4Up != '' && newTQuota4Up != undefined){
            this.template.querySelector('[data-id="TQ4Up"]').value = newTQuota4Up;
            this.template.querySelector('[data-id="SQ4UPLi"]').value = Number(sQuota4UPLi) - Number(sQuota4Up);
            objectTransferUpQ4.title = 'Quota Transfer';
            if(this.quotaTransfers.Q4UP == undefined) {objectTransferUpQ4.moneyPassed = Number(sQuota4Up);}
            if(this.quotaTransfers.Q4UP != undefined) {objectTransferUpQ4.moneyPassed = Number(sQuota4Up) + this.quotaTransfers.Q4UP.moneyPassed;}
            objectTransferUpQ4.newTargetAmount = newTQuota4Up;
            objectTransferUpQ4.newSourceAmount = Number(sQuota4UPLi) - Number(sQuota4Up);
            objectTransferUpQ4.fieldNameChanged = 'Q4 Upsell';
            objectTransferUpQ4.sourceRecord = this.currentPlanningQuota.Name;
            objectTransferUpQ4.targetRecord = this.quotaSelected.Name;
            objectTransferUpQ4.lastSourceAmount = this.currentPlanningQuota.Q4_Upsell_Target_ACV__c;
            objectTransferUpQ4.lastTargetAmount = this.quotaSelected.Q4_Upsell_Target_ACV__c;
            objectTransferUpQ4.sourceId = this.currentPlanningQuota.Id;
            objectTransferUpQ4.targetId = this.quotaSelected.Id;

            this.quotaTransfers.Q4UP = objectTransferUpQ4;
            changeIsMade = true;
        }

        this.template.querySelector('[data-id="SQ1NB"]').value = '';
        this.template.querySelector('[data-id="SQ2NB"]').value = '';
        this.template.querySelector('[data-id="SQ3NB"]').value = '';
        this.template.querySelector('[data-id="SQ4NB"]').value = '';

        this.template.querySelector('[data-id="SQ1Up"]').value = '';
        this.template.querySelector('[data-id="SQ2Up"]').value = '';
        this.template.querySelector('[data-id="SQ3Up"]').value = '';
        this.template.querySelector('[data-id="SQ4Up"]').value = '';

        let comment = this.template.querySelector('[data-id="comment"]').value;
        if(changeIsMade && comment != undefined && comment != ''){
            this.template.querySelector('[data-id="saveButt"]').disabled = false;
        }
    }

    popUpMess(mess, comment){
        this.notComment = comment;
        this.noteMess = mess;
        this.isModalOpen = true;
    }

    commentOnChange(e){
        let comm = e.target.value;
        let keys = Object.keys(this.quotaTransfers);
        if(comm.length > 0 && keys.length > 0){
            this.template.querySelector('[data-id="saveButt"]').disabled = false;
        }else{
            this.template.querySelector('[data-id="saveButt"]').disabled = true;
        }
    }

    handelSave(){
        this.template.querySelector('[data-id="saveButt"]').disabled = true;
        this.spinner = true;
        // save the comment
        let inputComment = this.template.querySelector('[data-id="comment"]').value;
        this.quotaTransfers.comment = inputComment;
        // update the Source
        let sQuota1NbLi = this.template.querySelector('[data-id="SQ1NBLi"]').value;
        let sQuota2NbLi = this.template.querySelector('[data-id="SQ2NBLi"]').value;
        let sQuota3NbLi = this.template.querySelector('[data-id="SQ3NBLi"]').value;
        let sQuota4NbLi = this.template.querySelector('[data-id="SQ4NBLi"]').value;

        let sQuota1UPLi = this.template.querySelector('[data-id="SQ1UPLi"]').value;
        let sQuota2UPLi = this.template.querySelector('[data-id="SQ2UPLi"]').value;
        let sQuota3UPLi = this.template.querySelector('[data-id="SQ3UPLi"]').value;
        let sQuota4UPLi = this.template.querySelector('[data-id="SQ4UPLi"]').value;

        this.currentPlanningQuota.Q1_NB_Target_ACV__c = Number(sQuota1NbLi);
        this.currentPlanningQuota.Q2_NB_Target_ACV__c = Number(sQuota2NbLi);
        this.currentPlanningQuota.Q3_NB_Target_ACV__c = Number(sQuota3NbLi);
        this.currentPlanningQuota.Q4_NB_Target_ACV__c = Number(sQuota4NbLi);

        this.currentPlanningQuota.Q1_Upsell_Target_ACV__c = Number(sQuota1UPLi);
        this.currentPlanningQuota.Q2_Upsell_Target_ACV__c = Number(sQuota2UPLi);
        this.currentPlanningQuota.Q3_Upsell_Target_ACV__c = Number(sQuota3UPLi);
        this.currentPlanningQuota.Q4_Upsell_Target_ACV__c = Number(sQuota4UPLi);

        // update the Target
        let tQuota1Nb = this.template.querySelector('[data-id="TQ1NB"]').value;
        let tQuota2Nb = this.template.querySelector('[data-id="TQ2NB"]').value;
        let tQuota3Nb = this.template.querySelector('[data-id="TQ3NB"]').value;
        let tQuota4Nb = this.template.querySelector('[data-id="TQ4NB"]').value;

        let tQuota1Up = this.template.querySelector('[data-id="TQ1Up"]').value;
        let tQuota2Up = this.template.querySelector('[data-id="TQ2Up"]').value;
        let tQuota3Up = this.template.querySelector('[data-id="TQ3Up"]').value;
        let tQuota4Up = this.template.querySelector('[data-id="TQ4Up"]').value;

        this.quotaSelected.Q1_NB_Target_ACV__c = Number(tQuota1Nb);
        this.quotaSelected.Q2_NB_Target_ACV__c = Number(tQuota2Nb);
        this.quotaSelected.Q3_NB_Target_ACV__c = Number(tQuota3Nb);
        this.quotaSelected.Q4_NB_Target_ACV__c = Number(tQuota4Nb);

        this.quotaSelected.Q1_Upsell_Target_ACV__c = Number(tQuota1Up);
        this.quotaSelected.Q2_Upsell_Target_ACV__c = Number(tQuota2Up);
        this.quotaSelected.Q3_Upsell_Target_ACV__c = Number(tQuota3Up);
        this.quotaSelected.Q4_Upsell_Target_ACV__c = Number(tQuota4Up);

        updateQuotaPlanning({'quotaMess': this.quotaTransfers, 'quotaSource': this.currentPlanningQuota, 'quotaTarget': this.quotaSelected}).then((data) => {
            if(data.Succses){
                this.showNotification('Success', 'Successfully done', 'success');
                this.dispatchEvent(new CloseActionScreenEvent());
            }else{
                console.log('Error: ' + data.Error);
                this.template.querySelector('[data-id="saveButt"]').disabled = false;
                this.showNotification('Error', 'Something went wrong', 'error');
            }
            this.spinner = false;
        })
    }

    showNotification(titlee, mess, vari){
        const evt = new ShowToastEvent({
            title: titlee,
            message : mess,
            variant : vari
        });
        this.dispatchEvent(evt);
    }
}