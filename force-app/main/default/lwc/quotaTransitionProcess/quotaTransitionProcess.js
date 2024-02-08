import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import extStyle from '@salesforce/resourceUrl/hide_qa_close_button';
import init from '@salesforce/apex/QuotaTransitionProcessCtrl.init';
import updateQuotaPlanning from '@salesforce/apex/QuotaTransitionProcessCtrl.updateQuotaPlanning';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class QuotaTransitionProcess extends LightningElement {
    test = 0;
    showFilter = false;
    spinner = false;
    @api recordId; // the recoud id from the current page 
    initIsRunning = false; // check if the init function is wall ready runs 
    quotePlanningObject; // all the quota planning thet active from the database 
    currentPlanningQuota; // the current quota planning the one from the page 
    calculatedNumExpectedR = {};
    rsmFilter = false; tbhFilter =false; postionFilter = false; // boolean thet open or close the cards filter 
    enableBlur = true; // boolean thet help to open and close the card filter in the right way
    rsmOptions=[]; @track filterRsmOptions = []; selectedRsm = ''; rsmDisabled=false; rsmDataId = ''; // all the var for rsm
    tbhOptions=[]; @track filterTbhOptions = []; selectedTbh = ''; tbhDisabled=false; tbhDataId = ''; // all the var for tbh
    positionOptions=[]; @track filterPositionOptions = []; selectedPosition = ''; positionDisabled=false; quotaSelected = {}; // all the var for position
    resultTable = []; // Holding all the result
    tableTemp = false; // boolean thet open or close the table
    compaerTable = false; // boolean thet open or close the comaer table
    isModalOpen = false;
    quotaTemporaryTransfer = {};
    quotaTransfers = {};
    @track numberAfterTransfer = {};
    anotherTransferNote = false;
    notComment = true;
    noteMess  = '';
    quotaSourceName = '';
    closeAction = false;
    changeIs_Made = false;
    totalSNB = 0; totalSUpsell = 0; totalSRenewal = 0; totalSTargetRenewal = 0;
    totalTNB = 0; totalTUpsell = 0; totalTRenewal = 0; totalTTargetRenewal = 0;
    lastNBTransfer = 0; lastUpsellTransfer = 0; lastRenewalTransfer = 0;
    totalSQ1 = 0; totalSQ2 = 0; totalSQ3 = 0; totalSQ4 = 0;
    totalTQ1 = 0; totalTQ2 = 0; totalTQ3 = 0; totalTQ4 = 0;
    totalTotalS = 0; totalTotalT = 0;
    lastQ1Transfer = 0; lastQ2Transfer = 0; lastQ3Transfer = 0; lastQ4Transfer = 0;
    lastTransferObj = {};

    connectedCallback(){
        Promise.all([
            loadStyle(this, extStyle + '/hide_qa_close_button.css')
        ]).then(() => { console.log('Styles Loaded'); });
        console.log('Conn after');
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
                this.formatNumberToString(this.currentPlanningQuota.Q1_NB_Target_ACV__c, 'Q1_NB_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q2_NB_Target_ACV__c, 'Q2_NB_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q3_NB_Target_ACV__c, 'Q3_NB_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q4_NB_Target_ACV__c, 'Q4_NB_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q1_Upsell_Target_ACV__c, 'Q1_Upsell_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q2_Upsell_Target_ACV__c, 'Q2_Upsell_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q3_Upsell_Target_ACV__c, 'Q3_Upsell_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q4_Upsell_Target_ACV__c, 'Q4_Upsell_Target_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c, 'Q1_Expected_Renewal_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c, 'Q2_Expected_Renewal_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c, 'Q3_Expected_Renewal_ACV__c');
                this.formatNumberToString(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c, 'Q4_Expected_Renewal_ACV__c');
                
                let Region = this.transferToZero(this.currentPlanningQuota.Region_Retention_Factor__c) / 100;
                let calculatedNumQ1ExpectedR = this.transferToZero(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c) * Region;
                this.calculatedNumExpectedR.calculatedNumQ1ExpectedR = calculatedNumQ1ExpectedR;
                this.formatNumberToString(calculatedNumQ1ExpectedR, 'calculatedNumQ1ExpectedR', 'ren');
                let calculatedNumQ2ExpectedR = this.transferToZero(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c) * Region;
                this.calculatedNumExpectedR.calculatedNumQ2ExpectedR = calculatedNumQ2ExpectedR;
                this.formatNumberToString(calculatedNumQ2ExpectedR, 'calculatedNumQ2ExpectedR', 'ren');
                let calculatedNumQ3ExpectedR = this.transferToZero(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c) * Region;
                this.calculatedNumExpectedR.calculatedNumQ3ExpectedR = calculatedNumQ3ExpectedR;
                this.formatNumberToString(calculatedNumQ3ExpectedR, 'calculatedNumQ3ExpectedR', 'ren');
                let calculatedNumQ4ExpectedR = this.transferToZero(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c) * Region;
                this.calculatedNumExpectedR.calculatedNumQ4ExpectedR = calculatedNumQ4ExpectedR;
                this.formatNumberToString(calculatedNumQ4ExpectedR, 'calculatedNumQ4ExpectedR', 'ren');
                this.totalSTargetRenewal = calculatedNumQ1ExpectedR + calculatedNumQ2ExpectedR + calculatedNumQ3ExpectedR + calculatedNumQ4ExpectedR;
                this.formatNumberToString(this.totalSTargetRenewal, 'totalSTargetRenewal', 'ren');

                this.totalSNB = this.transferToZero(this.currentPlanningQuota.Q1_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_NB_Target_ACV__c);
                this.totalSUpsell = this.transferToZero(this.currentPlanningQuota.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Upsell_Target_ACV__c);
                this.totalSRenewal = this.transferToZero(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c);
                this.formatNumberToString(this.totalSNB, 'totalSNB');
                this.formatNumberToString(this.totalSUpsell, 'totalSUpsell');
                this.formatNumberToString(this.totalSRenewal, 'totalSRenewal');
                this.totalSQ1 = this.transferToZero(this.currentPlanningQuota.Q1_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c);
                this.totalSQ2 = this.transferToZero(this.currentPlanningQuota.Q2_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c);
                this.totalSQ3 = this.transferToZero(this.currentPlanningQuota.Q3_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c);
                this.totalSQ4 = this.transferToZero(this.currentPlanningQuota.Q4_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c);
                this.formatNumberToString(this.totalSQ1, 'totalSQ1');
                this.formatNumberToString(this.totalSQ2, 'totalSQ2');
                this.formatNumberToString(this.totalSQ3, 'totalSQ3');
                this.formatNumberToString(this.totalSQ4, 'totalSQ4');
                this.totalTotalS = this.totalSQ1 + this.totalSQ2 + this.totalSQ3 + this.totalSQ4;
                this.formatNumberToString(this.totalTotalS, 'totalTotalS');

                this.quotaSourceName = this.currentPlanningQuota.Name;
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

                if(this.rsmOptions.length || 0 && this.tbhOptions.length || 0 && this.positionOptions.length || 0) this.showFilter = true;
            }
        })
    }

    transferToZero(num){
        if(num == undefined) num = 0;
        return Number(num);
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
        this.resultTable = [];       
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
        this.resultTable = [];
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
        this.resultTable = [];
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
        this.changeIs_Made = false;
        this.quotaTemporaryTransfer = {};   
        this.quotaTransfers = {};
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
                       this.formatNumberToString(this.quotaSelected.Q1_NB_Target_ACV__c, 'DQ1_NB_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q2_NB_Target_ACV__c, 'DQ2_NB_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q3_NB_Target_ACV__c, 'DQ3_NB_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q4_NB_Target_ACV__c, 'DQ4_NB_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q1_Upsell_Target_ACV__c, 'DQ1_Upsell_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q2_Upsell_Target_ACV__c, 'DQ2_Upsell_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q3_Upsell_Target_ACV__c, 'DQ3_Upsell_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q4_Upsell_Target_ACV__c, 'DQ4_Upsell_Target_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q1_Expected_Renewal_ACV__c, 'DQ1_Expected_Renewal_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q2_Expected_Renewal_ACV__c, 'DQ2_Expected_Renewal_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q3_Expected_Renewal_ACV__c, 'DQ3_Expected_Renewal_ACV__c');
                       this.formatNumberToString(this.quotaSelected.Q4_Expected_Renewal_ACV__c, 'DQ4_Expected_Renewal_ACV__c');
                       this.tableTemp = false;

                       let Region = this.transferToZero(this.quotaSelected.Region_Retention_Factor__c) / 100;
                       let calculatedNumQ1ExpectedRT = this.transferToZero(this.quotaSelected.Q1_Expected_Renewal_ACV__c) * Region;
                       this.calculatedNumExpectedR.calculatedNumQ1ExpectedRT = calculatedNumQ1ExpectedRT;
                       this.formatNumberToString(calculatedNumQ1ExpectedRT, 'calculatedNumQ1ExpectedRT', 'ren');

                       let calculatedNumQ2ExpectedRT = this.transferToZero(this.quotaSelected.Q2_Expected_Renewal_ACV__c) * Region;
                       this.calculatedNumExpectedR.calculatedNumQ2ExpectedRT = calculatedNumQ2ExpectedRT;
                       this.formatNumberToString(calculatedNumQ2ExpectedRT, 'calculatedNumQ2ExpectedRT', 'ren');

                       let calculatedNumQ3ExpectedRT = this.transferToZero(this.quotaSelected.Q3_Expected_Renewal_ACV__c) * Region;
                       this.calculatedNumExpectedR.calculatedNumQ3ExpectedRT = calculatedNumQ3ExpectedRT;
                       this.formatNumberToString(calculatedNumQ3ExpectedRT, 'calculatedNumQ3ExpectedRT', 'ren');

                       let calculatedNumQ4ExpectedRT = this.transferToZero(this.quotaSelected.Q4_Expected_Renewal_ACV__c) * Region;
                       this.calculatedNumExpectedR.calculatedNumQ4ExpectedRT = calculatedNumQ4ExpectedRT;
                       this.formatNumberToString(calculatedNumQ4ExpectedRT, 'calculatedNumQ4ExpectedRT' , 'ren');

                       this.totalTTargetRenewal = calculatedNumQ1ExpectedRT + calculatedNumQ2ExpectedRT + calculatedNumQ3ExpectedRT + calculatedNumQ4ExpectedRT;
                       this.formatNumberToString(this.totalTTargetRenewal, 'totalTTargetRenewal', 'ren');

                       this.totalTNB = this.transferToZero(this.quotaSelected.Q1_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_NB_Target_ACV__c);
                       this.totalTUpsell = this.transferToZero(this.quotaSelected.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Upsell_Target_ACV__c);
                       this.totalTRenewal = this.transferToZero(this.quotaSelected.Q1_Expected_Renewal_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Expected_Renewal_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Expected_Renewal_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Expected_Renewal_ACV__c);
                       this.formatNumberToString(this.totalTNB, 'totalTNB');
                       this.formatNumberToString(this.totalTUpsell, 'totalTUpsell');
                       this.formatNumberToString(this.totalTRenewal, 'totalTRenewal');
                       this.totalTQ1 = this.transferToZero(this.quotaSelected.Q1_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q1_Expected_Renewal_ACV__c);
                       this.totalTQ2 = this.transferToZero(this.quotaSelected.Q2_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Expected_Renewal_ACV__c);
                       this.totalTQ3 = this.transferToZero(this.quotaSelected.Q3_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Expected_Renewal_ACV__c);
                       this.totalTQ4 = this.transferToZero(this.quotaSelected.Q4_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Expected_Renewal_ACV__c);
                       this.formatNumberToString(this.totalTQ1, 'totalTQ1');
                       this.formatNumberToString(this.totalTQ2, 'totalTQ2');
                       this.formatNumberToString(this.totalTQ3, 'totalTQ3');
                       this.formatNumberToString(this.totalTQ4, 'totalTQ4');
                       this.totalTotalT = this.totalTQ1 + this.totalTQ2 + this.totalTQ3 + this.totalTQ4;
                       this.formatNumberToString(this.totalTotalT, 'totalTotalT');
                       if(this.quotaSelected.Sub_Region__c != this.currentPlanningQuota.Sub_Region__c){
                            this.notComment = true;
                            this.noteMess = 'You have selected a record from a different sub region. Click "Continue" or "Back" for changes.';
                            this.isModalOpen = true;
                       }
                   }  
                }
               this.compaerTable = true
               this.showFilter = false;
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
        this.showFilter = true;
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
        this.closeAction = false;
    }

    canselTransfer(){
        // Source
        for(let i = 1; i <= 4; i++){
            let sqnb = 'SQ'+i+'NB'
            let sqnbli = 'SQ'+i+'NBLi';
            let qnbN = 'Q'+i+'_NB_Target_ACV__c'
            let tqnb = 'TQ'+i+'NB';
            let qupN = 'Q'+i+'_Upsell_Target_ACV__c';
            let squp = 'SQ'+i+'UP';
            let squpli = 'SQ'+i+'UPLi';
            let tqup = 'TQ'+i+'UP';
            let qreN = 'Q'+i+'_Expected_Renewal_ACV__c';
            let sqre = 'SQ'+i+'RE';
            let sqreli = 'SQ'+i+'RELi';
            let tqre = 'TQ'+i+'RE';
            let qnb = 'Q'+i+'NB';
            let qup = 'Q'+i+'UP';
            let qre = 'Q'+i+'RE';
            let cne = 'calculatedNumQ'+i+'ExpectedR';
            let cnet = 'calculatedNumQ'+i+'ExpectedRT';
            if(this.lastTransferObj[sqnb] != undefined && this.quotaTemporaryTransfer[sqnbli] != undefined){
                this.quotaTemporaryTransfer[sqnbli] = this.quotaTemporaryTransfer[sqnbli] + this.lastTransferObj[sqnb];
                this.formatNumberToString(this.quotaTemporaryTransfer[sqnbli], qnbN);
                this.quotaTemporaryTransfer[tqnb] = this.quotaTemporaryTransfer[tqnb] - this.lastTransferObj[sqnb];
                this.formatNumberToString(this.quotaTemporaryTransfer[sqnbli], 'D'+qnbN);
                this.quotaTransfers[qnb].moneyPassed = this.quotaTransfers[qnb].moneyPassed - this.lastTransferObj[sqnb];
            }
            if(this.lastTransferObj[squp] != undefined && this.quotaTemporaryTransfer[squpli] != undefined){
                this.quotaTemporaryTransfer[squpli] = this.quotaTemporaryTransfer[squpli] + this.lastTransferObj[squp];
                this.formatNumberToString(this.quotaTemporaryTransfer[squpli], qupN);
                this.quotaTemporaryTransfer[tqup] = this.quotaTemporaryTransfer[tqup] - this.lastTransferObj[squp];
                this.formatNumberToString(this.quotaTemporaryTransfer[squpli], 'D'+qupN);
                this.quotaTransfers[qup].moneyPassed = this.quotaTransfers[qup].moneyPassed - this.lastTransferObj[squp];
            }
            if(this.lastTransferObj[sqre] != undefined && this.quotaTemporaryTransfer[sqreli] != undefined){
                this.quotaTemporaryTransfer[sqreli] = this.quotaTemporaryTransfer[sqreli] + this.lastTransferObj[sqre];
                this.formatNumberToString(this.quotaTemporaryTransfer[sqreli], qreN);
                this.quotaTemporaryTransfer[tqre] = this.quotaTemporaryTransfer[tqre] - this.lastTransferObj[sqre];
                this.formatNumberToString(this.quotaTemporaryTransfer[sqreli], 'D'+qreN);
                this.quotaTransfers[qre].moneyPassed = this.quotaTransfers[qre].moneyPassed - this.lastTransferObj[sqre];
                this.calculatedNumExpectedR[cne] = this.calculatedNumExpectedR[cne] + this.lastTransferObj[sqre] * (this.transferToZero(this.currentPlanningQuota.Region_Retention_Factor__c) / 100);
                this.calculatedNumExpectedR[cnet] = this.calculatedNumExpectedR[cnet] - this.lastTransferObj[sqre] * (this.transferToZero(this.quotaSelected.Region_Retention_Factor__c) / 100);
                this.formatNumberToString(this.calculatedNumExpectedR[cne], cne);
                this.formatNumberToString(this.calculatedNumExpectedR[cnet], cnet);
                this.totalSTargetRenewal = this.totalSTargetRenewal + this.lastTransferObj[sqre] * (this.transferToZero(this.currentPlanningQuota.Region_Retention_Factor__c) / 100);
                this.formatNumberToString(this.totalSTargetRenewal, 'totalSTargetRenewal');
                this.totalTTargetRenewal = this.totalTTargetRenewal - this.lastTransferObj[sqre] * (this.transferToZero(this.quotaSelected.Region_Retention_Factor__c) / 100);
                this.formatNumberToString(this.totalTTargetRenewal, 'totalTTargetRenewal');
            }
        }

        this.totalSNB = this.totalSNB + this.lastNBTransfer;
        this.formatNumberToString(this.totalSNB, 'totalSNB');
        this.totalSUpsell = this.totalSUpsell + this.lastUpsellTransfer;
        this.formatNumberToString(this.totalSUpsell, 'totalSUpsell');
        this.totalSRenewal = this.totalSRenewal + this.lastRenewalTransfer;
        this.formatNumberToString(this.totalSRenewal, 'totalSRenewal');
        this.totalSQ1 = this.totalSQ1 + this.lastQ1Transfer;
        this.formatNumberToString(this.totalSQ1, 'totalSQ1');
        this.totalSQ2 = this.totalSQ2 + this.lastQ2Transfer;
        this.formatNumberToString(this.totalSQ2, 'totalSQ2');
        this.totalSQ3 = this.totalSQ3 + this.lastQ3Transfer;
        this.formatNumberToString(this.totalSQ3, 'totalSQ3');
        this.totalSQ4 = this.totalSQ4 + this.lastQ4Transfer;
        this.formatNumberToString(this.totalSQ4, 'totalSQ4');
        this.totalTotalS = this.totalSQ1 + this.totalSQ2 + this.totalSQ3 + this.totalSQ4;
        this.formatNumberToString(this.totalTotalS, 'totalTotalS');
        // Destination
        this.totalTNB = this.totalTNB  - this.lastNBTransfer;
        this.formatNumberToString(this.totalTNB, 'totalTNB');
        this.totalTUpsell = this.totalTUpsell - this.lastUpsellTransfer;
        this.formatNumberToString(this.totalTUpsell, 'totalTUpsell');
        this.totalTRenewal = this.totalTRenewal - this.lastRenewalTransfer;
        this.formatNumberToString(this.totalTRenewal, 'totalTRenewal');
        this.totalTQ1 = this.totalTQ1 - this.lastQ1Transfer;
        this.formatNumberToString(this.totalTQ1, 'totalTQ1');
        this.totalTQ2 = this.totalTQ2 - this.lastQ2Transfer;
        this.formatNumberToString(this.totalTQ2, 'totalTQ2');
        this.totalTQ3 = this.totalTQ3 - this.lastQ3Transfer;
        this.formatNumberToString(this.totalTQ3, 'totalTQ3');
        this.totalTQ4 = this.totalTQ4 - this.lastQ4Transfer;
        this.formatNumberToString(this.totalTQ4, 'totalTQ4');
        this.totalTotalT = this.totalTQ1 + this.totalTQ2 + this.totalTQ3 + this.totalTQ4;
        this.formatNumberToString(this.totalTotalT, 'totalTotalT');

        this.lastNBTransfer = 0;
        this.lastUpsellTransfer = 0;
        this.lastRenewalTransfer = 0;
        this.lastQ1Transfer = 0;
        this.lastQ2Transfer = 0;
        this.lastQ3Transfer = 0;
        this.lastQ4Transfer = 0;

        this.isModalOpen = false;
    }

    confirmTransfer(){
        this.isModalOpen = false;
        this.anotherTransferNote = false;
        
    }

    // Transfer values in the selected fields
    moveQuotaHandel(){
        this.lastTransferObj = {};
        let canRun = false;
        for(let i=1; i <= 4; i++){
            let sqnb = 'SQ'+i+'NB';
            let squp = 'SQ'+i+'UP';
            let sqre = 'SQ'+i+'RE';
            if(this.template.querySelector('[data-id="'+sqnb+'"]').value != undefined && this.template.querySelector('[data-id="'+sqnb+'"]').value != '') canRun = true;
            if(this.template.querySelector('[data-id="'+squp+'"]').value != undefined && this.template.querySelector('[data-id="'+squp+'"]').value != '') canRun = true;
            if(this.template.querySelector('[data-id="'+sqre+'"]').value != undefined && this.template.querySelector('[data-id="'+sqre+'"]').value != '') canRun = true;
            this.quotaTemporaryTransfer[sqnb] = '';
            this.quotaTemporaryTransfer[squp] = '';
            this.quotaTemporaryTransfer[sqre] = '';
        }
        if(!canRun) {this.popUpMess('No request has been registered!', false, false); return;}
        this.changeIs_Made = true;
        for(let i = 1; i <= 4; i++){
            let sqnb = 'SQ'+i+'NB';
            let sqnbN = 'Q'+i+'_NB_Target_ACV__c';
            let sqnbli = 'SQ'+i+'NBLi';
            let squp = 'SQ'+i+'UP';
            let squpN = 'Q'+i+'_Upsell_Target_ACV__c';
            let squpli = 'SQ'+i+'UPLi';
            let sqre = 'SQ'+i+'RE';
            let sqreN = 'Q'+i+'_Expected_Renewal_ACV__c';
            let sqreli = 'SQ'+i+'RELi';
            let tqnb = 'TQ'+i+'NB';
            let tqup = 'TQ'+i+'UP';
            let tqre = 'TQ'+i+'RE';
            let isValid = true;

            this.quotaTemporaryTransfer[sqnb] = this.template.querySelector('[data-id="'+sqnb+'"]').value;
            if(this.quotaTemporaryTransfer[sqnb] != '' && this.quotaTemporaryTransfer[sqnb] != undefined) isValid = this.approvedNumVal(this.quotaTemporaryTransfer[sqnb]);
            if(!isValid) {this.popUpMess('The selected amount of Q' + i + ' NB is invalid', false, false); return;}
            if(this.quotaTemporaryTransfer[sqnbli] == undefined) this.quotaTemporaryTransfer[sqnbli] = this.currentPlanningQuota[sqnbN];
            
            this.quotaTemporaryTransfer[squp] = this.template.querySelector('[data-id="'+squp+'"]').value;
            if(this.quotaTemporaryTransfer[squp] != '' && this.quotaTemporaryTransfer[squp] != undefined) isValid = this.approvedNumVal(this.quotaTemporaryTransfer[squp]);
            if(!isValid) {this.popUpMess('The selected amount of Q' + i + ' NB is invalid', false, false); return;}
            if(this.quotaTemporaryTransfer[squpli] == undefined) this.quotaTemporaryTransfer[squpli] = this.currentPlanningQuota[squpN];
            

            this.quotaTemporaryTransfer[sqre] = this.template.querySelector('[data-id="'+sqre+'"]').value;
            if(this.quotaTemporaryTransfer[sqre] != '' && this.quotaTemporaryTransfer[sqre] != undefined) isValid = this.approvedNumVal(this.quotaTemporaryTransfer[sqre]);
            if(!isValid) {this.popUpMess('The selected amount of Q' + i + ' NB is invalid', false, false); return;}
            if(this.quotaTemporaryTransfer[sqreli] == undefined) this.quotaTemporaryTransfer[sqreli] = this.currentPlanningQuota[sqreN];


            if(this.quotaTemporaryTransfer[tqnb] == undefined) this.quotaTemporaryTransfer[tqnb] = this.quotaSelected[sqnbN];
            if(this.quotaTemporaryTransfer[tqup] == undefined) this.quotaTemporaryTransfer[tqup] = this.quotaSelected[squpN];
            if(this.quotaTemporaryTransfer[tqre] == undefined) this.quotaTemporaryTransfer[tqre] = this.quotaSelected[sqreN];
        }

        let newTQuotaNb = {};
        let newTQuotaUp = {};
        let newTQuotaRe = {};
        let changeIsMade = false;
        for(let i = 1; i <= 4; i++){
            let sqnb = 'SQ'+i+'NB';
            let sqnbli = 'SQ'+i+'NBLi';
            let squp = 'SQ'+i+'UP';
            let squpli = 'SQ'+i+'UPLi';
            let sqre = 'SQ'+i+'RE';
            let sqreli = 'SQ'+i+'RELi';
            let newTqNB = 'newTQ' + i + 'NB';
            let newTqUP = 'newTQ'+i+'UP';
            let newTqRE = 'newTQ'+i+'RE';
            let tqnb = 'TQ' + i + 'NB';
            let tqup = 'TQ' + i + 'UP';
            let tqre = 'TQ' + i + 'RE';

            if(this.quotaTemporaryTransfer[sqnb] != '' && Number(this.quotaTemporaryTransfer[sqnbli]) >= Number(this.quotaTemporaryTransfer[sqnb])) {
                newTQuotaNb[newTqNB] = Number(this.quotaTemporaryTransfer[sqnb]) + Number(this.quotaTemporaryTransfer[tqnb]);
                changeIsMade = true;
            }else if(this.quotaTemporaryTransfer[sqnb] != undefined && this.quotaTemporaryTransfer[sqnb] != '') {
                this.popUpMess('The selected amount is greater then the Q' + i + ' NB balance', false, false);
            }

            if(this.quotaTemporaryTransfer[squp] != '' && Number(this.quotaTemporaryTransfer[squpli]) >= Number(this.quotaTemporaryTransfer[squp])) {
                newTQuotaUp[newTqUP] = Number(this.quotaTemporaryTransfer[squp]) + Number(this.quotaTemporaryTransfer[tqup]);
                changeIsMade = true
            }else if(this.quotaTemporaryTransfer[squp] != undefined && this.quotaTemporaryTransfer[squp] != '') {
                this.popUpMess('The selected amount is greater then the Q' + i + ' Upsell balance', false);
            }

            if(this.quotaTemporaryTransfer[sqre] != '' && Number(this.quotaTemporaryTransfer[sqreli]) >= Number(this.quotaTemporaryTransfer[sqre])) {
                newTQuotaRe[newTqRE] = Number(this.quotaTemporaryTransfer[sqre]) + Number(this.quotaTemporaryTransfer[tqre]);
                changeIsMade = true
            }else if(this.quotaTemporaryTransfer[sqre] != undefined && this.quotaTemporaryTransfer[sqre] != '') {
                this.popUpMess('The selected amount is greater then the Q' + i + ' Renewal balance', false);
            }
        } 

        let objectTransferNBQ = {};
        let objectTransferUpQ = {};
        let objectTransferREQ = {};

        this.lastNBTransfer = 0;
        this.lastQ1Transfer = 0; this.lastQ2Transfer = 0; this.lastQ3Transfer = 0; this.lastQ4Transfer = 0; 
        for(let i = 1;  i <= 4; i++){
            let qnb = 'Q'+i+'NB'
            let qnbN = 'Q'+i+'_NB_Target_ACV__c'
            let newTqnb = 'newTQ'+i+'NB';
            let newSqnbli = 'newSQ'+i+'NBLi';
            //let moneyPass = 'moneyPassQ'+i+'NB';
            let tqnb = 'TQ'+i+'NB';
            let sqnb = 'SQ'+i+'NB';
            let sqnbli = 'SQ'+i+'NBLi';
            if((newTQuotaNb[newTqnb] != undefined && newTQuotaNb[newTqnb] != '')){
                objectTransferNBQ = {};
                let tansferAmount = Number(this.quotaTemporaryTransfer[sqnb]);
                this.lastTransferObj[sqnb] = tansferAmount;
                this.quotaTemporaryTransfer[newTqnb] = newTQuotaNb[newTqnb];
                this.quotaTemporaryTransfer[newSqnbli] = Number(this.quotaTemporaryTransfer[sqnbli]) - tansferAmount;
                this.quotaTemporaryTransfer[tqnb] = newTQuotaNb[newTqnb];
                this.formatNumberToString(newTQuotaNb[newTqnb], 'D'+qnbN);
                let numSqnbli = Number(this.quotaTemporaryTransfer[sqnbli]) - tansferAmount;
                this.quotaTemporaryTransfer[sqnbli] = numSqnbli;
                this.formatNumberToString(numSqnbli, qnbN);
                if(this.quotaTransfers[qnb] != undefined) {objectTransferNBQ.moneyPassed = tansferAmount + this.quotaTransfers[qnb].moneyPassed;}
                if(this.quotaTransfers[qnb] == undefined) {objectTransferNBQ.moneyPassed = tansferAmount;}
                objectTransferNBQ.newSourceAmount = numSqnbli
                this.lastNBTransfer = this.lastNBTransfer + tansferAmount;
                this.totalSNB = this.totalSNB - tansferAmount;
                this.totalTNB = this.totalTNB + tansferAmount;
                this.formatNumberToString(this.totalTNB, 'totalTNB');
                this.formatNumberToString(this.totalSNB, 'totalSNB');
                if(i == 1) {
                    this.totalSQ1 = this.totalSQ1 - tansferAmount; 
                    this.totalTQ1 = this.totalTQ1 + tansferAmount; 
                    this.lastQ1Transfer = this.lastQ1Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ1, 'totalSQ1'); 
                    this.formatNumberToString(this.totalTQ1, 'totalTQ1');
                }
                if(i == 2) {
                    this.totalSQ2 = this.totalSQ2 - tansferAmount; 
                    this.totalTQ2 = this.totalTQ2 + tansferAmount; 
                    this.lastQ2Transfer = this.lastQ2Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ2, 'totalSQ2'); 
                    this.formatNumberToString(this.totalTQ2, 'totalTQ2');
                }
                if(i == 3) {
                    this.totalSQ3 = this.totalSQ3 - tansferAmount; 
                    this.totalTQ3 = this.totalTQ3 + tansferAmount; 
                    this.lastQ3Transfer = this.lastQ3Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ3, 'totalSQ3'); 
                    this.formatNumberToString(this.totalTQ3, 'totalTQ3');
                }
                if(i == 4) {
                    this.totalSQ4 = this.totalSQ4 - tansferAmount; 
                    this.totalTQ4 = this.totalTQ4 + tansferAmount; 
                    this.lastQ4Transfer = this.lastQ4Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ4, 'totalSQ4'); 
                    this.formatNumberToString(this.totalTQ4, 'totalTQ4');
                }
                
                if(this.quotaTransfers[qnb] != undefined) {this.popUpMess('You already have an open transaction on Q' + i + ' NB', false, true, false);}
                this.quotaTransfers[qnb] = objectTransferNBQ;
                changeIsMade = true;  
            }
        }

        this.lastUpsellTransfer = 0;
        for(let i = 1; i <= 4; i++){
            let qup = 'Q'+i+'UP'
            let newTqup = 'newTQ'+i+'UP';
            let qupN = 'Q'+i+'_Upsell_Target_ACV__c';
            let newSqupli = 'newSQ'+i+'UPLi';
            let squp = 'SQ'+i+'UP';
            let squpli = 'SQ'+i+'UPLi';
            let tqup = 'TQ'+i+'UP';
            if(newTQuotaUp[newTqup] != undefined && newTQuotaUp[newTqup] != ''){
                objectTransferUpQ = {};
                let tansferAmount = Number(this.quotaTemporaryTransfer[squp]);
                this.lastTransferObj[squp] = tansferAmount;
                this.quotaTemporaryTransfer[newTqup] = newTQuotaUp[newTqup];
                this.quotaTemporaryTransfer[newSqupli] = Number(this.quotaTemporaryTransfer[squpli]) - tansferAmount;
                this.quotaTemporaryTransfer[tqup] = newTQuotaUp[newTqup];
                this.formatNumberToString(newTQuotaUp[newTqup], 'D'+ qupN);
                let numSqupli = Number(this.quotaTemporaryTransfer[squpli]) - tansferAmount;
                this.quotaTemporaryTransfer[squpli] = numSqupli;
                this.formatNumberToString(numSqupli, qupN);
                if(this.quotaTransfers[qup] != undefined) {objectTransferUpQ.moneyPassed = tansferAmount + this.quotaTransfers[qup].moneyPassed;}
                if(this.quotaTransfers[qup] == undefined) {objectTransferUpQ.moneyPassed = tansferAmount;}
                objectTransferUpQ.newSourceAmount = numSqupli;
                this.lastUpsellTransfer = this.lastUpsellTransfer + tansferAmount;
                this.totalSUpsell = this.totalSUpsell - tansferAmount;
                this.totalTUpsell = this.totalTUpsell + tansferAmount;
                this.formatNumberToString(this.totalTUpsell, 'totalTUpsell');
                this.formatNumberToString(this.totalSUpsell, 'totalSUpsell');
                if(i == 1) {
                    this.totalSQ1 = this.totalSQ1 - tansferAmount; 
                    this.totalTQ1 = this.totalTQ1 + tansferAmount; 
                    this.lastQ1Transfer = this.lastQ1Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ1, 'totalSQ1'); 
                    this.formatNumberToString(this.totalTQ1, 'totalTQ1');
                }
                if(i == 2) {
                    this.totalSQ2 = this.totalSQ2 - tansferAmount; 
                    this.totalTQ2 = this.totalTQ2 + tansferAmount; 
                    this.lastQ2Transfer = this.lastQ2Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ2, 'totalSQ2'); 
                    this.formatNumberToString(this.totalTQ2, 'totalTQ2');
                }
                if(i == 3) {
                    this.totalSQ3 = this.totalSQ3 - tansferAmount; 
                    this.totalTQ3 = this.totalTQ3 + tansferAmount; 
                    this.lastQ3Transfer = this.lastQ3Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ3, 'totalSQ3'); 
                    this.formatNumberToString(this.totalTQ3, 'totalTQ3');
                }
                if(i == 4) {
                    this.totalSQ4 = this.totalSQ4 - tansferAmount; 
                    this.totalTQ4 = this.totalTQ4 + tansferAmount; 
                    this.lastQ4Transfer = this.lastQ4Transfer + tansferAmount;
                    this.formatNumberToString(this.totalSQ4, 'totalSQ4'); 
                    this.formatNumberToString(this.totalTQ4, 'totalTQ4');
                }

                if(this.quotaTransfers[qup] != undefined) {this.popUpMess('You already have an open transaction on this row', false, true, false);}
                this.quotaTransfers[qup] = objectTransferUpQ;
                changeIsMade = true;
            }
        }

        this.lastRenewalTransfer = 0;
        for(let i = 1; i <= 4; i++){
            let qre = 'Q'+i+'RE'
            let newTqre = 'newTQ'+i+'RE';
            let qreN = 'Q'+i+'_Expected_Renewal_ACV__c';
            let newSqreli = 'newSQ'+i+'RELi';
            let sqre = 'SQ'+i+'RE';
            let sqreli = 'SQ'+i+'RELi';
            let tqre = 'TQ'+i+'RE';

            if(newTQuotaRe[newTqre] != undefined && newTQuotaRe[newTqre] != ''){
                objectTransferREQ = {};
                let tansferAmount = Number(this.quotaTemporaryTransfer[sqre]);
                this.lastTransferObj[sqre] = tansferAmount;
                this.quotaTemporaryTransfer[newTqre] = newTQuotaRe[newTqre];
                this.quotaTemporaryTransfer[newSqreli] = Number(this.quotaTemporaryTransfer[sqreli]) - tansferAmount;
                this.quotaTemporaryTransfer[tqre] = newTQuotaRe[newTqre];
                this.formatNumberToString(newTQuotaRe[newTqre], 'D'+ qreN);
                let numSqreli = Number(this.quotaTemporaryTransfer[sqreli]) - tansferAmount;
                this.quotaTemporaryTransfer[sqreli] = numSqreli;
                this.formatNumberToString(numSqreli, qreN);
                if(this.quotaTransfers[qre] != undefined) {objectTransferREQ.moneyPassed = tansferAmount + this.quotaTransfers[qre].moneyPassed;}
                if(this.quotaTransfers[qre] == undefined) {objectTransferREQ.moneyPassed = tansferAmount;}
                objectTransferREQ.newSourceAmount = numSqreli;
                this.lastRenewalTransfer = this.lastRenewalTransfer + tansferAmount;
                this.totalSRenewal = this.totalSRenewal - tansferAmount;
                this.totalTRenewal = this.totalTRenewal + tansferAmount;
                this.formatNumberToString(this.totalTRenewal, 'totalTRenewal');
                this.formatNumberToString(this.totalSRenewal, 'totalSRenewal');
                
                let regionS = this.transferToZero(this.currentPlanningQuota.Region_Retention_Factor__c) / 100;
                let regionD = this.transferToZero(this.quotaSelected.Region_Retention_Factor__c) / 100;
                if(i == 1) {
                    this.totalSQ1 = this.totalSQ1 - tansferAmount; 
                    this.totalTQ1 = this.totalTQ1 + tansferAmount; 
                    this.lastQ1Transfer = this.lastQ1Transfer + tansferAmount; 
                    this.calculatedNumExpectedR.calculatedNumQ1ExpectedR = this.calculatedNumExpectedR.calculatedNumQ1ExpectedR - this.lastQ1Transfer * regionS;
                    this.calculatedNumExpectedR.calculatedNumQ1ExpectedRT = this.calculatedNumExpectedR.calculatedNumQ1ExpectedRT + this.lastQ1Transfer * regionD;
                    this.formatNumberToString(this.totalSQ1, 'totalSQ1');
                    this.formatNumberToString(this.totalTQ1, 'totalTQ1');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ1ExpectedR, 'calculatedNumQ1ExpectedR', 'ren');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ1ExpectedRT, 'calculatedNumQ1ExpectedRT', 'ren');
                    this.totalSTargetRenewal = this.totalSTargetRenewal - this.lastQ1Transfer * regionS;
                    this.formatNumberToString(this.totalSTargetRenewal, 'totalSTargetRenewal', 'ren');
                    this.totalTTargetRenewal = this.totalTTargetRenewal + this.lastQ1Transfer * regionD;
                    this.formatNumberToString(this.totalTTargetRenewal, 'totalTTargetRenewal', 'ren');
                }
                if(i == 2) {
                    this.totalSQ2 = this.totalSQ2 - tansferAmount; 
                    this.totalTQ2 = this.totalTQ2 + tansferAmount; 
                    this.lastQ2Transfer = this.lastQ2Transfer + tansferAmount; 
                    this.calculatedNumExpectedR.calculatedNumQ2ExpectedR = this.calculatedNumExpectedR.calculatedNumQ2ExpectedR - this.lastQ2Transfer * regionS;
                    this.calculatedNumExpectedR.calculatedNumQ2ExpectedRT = this.calculatedNumExpectedR.calculatedNumQ2ExpectedRT + this.lastQ2Transfer * regionD;
                    this.formatNumberToString(this.totalSQ2, 'totalSQ2'); 
                    this.formatNumberToString(this.totalTQ2, 'totalTQ2'); 
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ2ExpectedR, 'calculatedNumQ2ExpectedR', 'ren');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ2ExpectedRT, 'calculatedNumQ2ExpectedRT', 'ren');
                }
                if(i == 3) {
                    this.totalSQ3 = this.totalSQ3 - tansferAmount; 
                    this.totalTQ3 = this.totalTQ3 + tansferAmount; 
                    this.lastQ3Transfer = this.lastQ3Transfer + tansferAmount; 
                    this.calculatedNumExpectedR.calculatedNumQ3ExpectedR = this.calculatedNumExpectedR.calculatedNumQ3ExpectedR - this.lastQ3Transfer * regionS;
                    this.calculatedNumExpectedR.calculatedNumQ3ExpectedRT = this.calculatedNumExpectedR.calculatedNumQ3ExpectedRT + this.lastQ3Transfer * regionD;
                    this.formatNumberToString(this.totalSQ3, 'totalSQ3');
                    this.formatNumberToString(this.totalTQ3, 'totalTQ3');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ3ExpectedR, 'calculatedNumQ3ExpectedR', 'ren');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ3ExpectedRT, 'calculatedNumQ3ExpectedRT', 'ren');
                }
                if(i == 4) {
                    this.totalSQ4 = this.totalSQ4 - tansferAmount; 
                    this.totalTQ4 = this.totalTQ4 + tansferAmount; 
                    this.lastQ4Transfer = this.lastQ4Transfer + tansferAmount; 
                    this.calculatedNumExpectedR.calculatedNumQ4ExpectedR = this.calculatedNumExpectedR.calculatedNumQ4ExpectedR - this.lastQ4Transfer * regionS;
                    this.calculatedNumExpectedR.calculatedNumQ4ExpectedRT = this.calculatedNumExpectedR.calculatedNumQ4ExpectedRT + this.lastQ4Transfer * regionD;
                    this.formatNumberToString(this.totalSQ4, 'totalSQ4');
                    this.formatNumberToString(this.totalTQ4, 'totalTQ4');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ4ExpectedR, 'calculatedNumQ4ExpectedR', 'ren');
                    this.formatNumberToString(this.calculatedNumExpectedR.calculatedNumQ4ExpectedRT, 'calculatedNumQ4ExpectedRT', 'ren');
                }
                if(this.quotaTransfers[qre] != undefined) {this.popUpMess('You already have an open transaction on this row', false, true, false);}
                this.quotaTransfers[qre] = objectTransferREQ;
                changeIsMade = true;
            }
        }
        this.totalTotalS = this.totalSQ1 + this.totalSQ2 + this.totalSQ3 + this.totalSQ4;
        this.formatNumberToString(this.totalTotalS, 'totalTotalS');
        this.totalTotalT = this.totalTQ1 + this.totalTQ2 + this.totalTQ3 + this.totalTQ4;
        this.formatNumberToString(this.totalTotalT, 'totalTotalT');
        if(changeIsMade){
            for(let i = 1; i <= 4; i++){
                let sqnb = 'SQ'+i+'NB';
                let squp = 'SQ'+i+'UP';
                let sqre = 'SQ'+i+'RE';
                this.template.querySelector('[data-id="'+sqnb+'"]').value = '';
                this.template.querySelector('[data-id="'+squp+'"]').value = '';
                this.template.querySelector('[data-id="'+sqre+'"]').value = '';
            }  
            let comment = this.template.querySelector('[data-id="comment"]').value;
            if(changeIsMade && comment != undefined && comment != ''){
            //this.template.querySelector('[data-id="saveButt"]').disabled = false;
            }
        }
    }

    clearChangesHandler(){
        this.changeIs_Made = false;
        this.quotaTemporaryTransfer = {};
        this.quotaTransfers = {};

        this.formatNumberToString(this.currentPlanningQuota.Q1_NB_Target_ACV__c, 'Q1_NB_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q2_NB_Target_ACV__c, 'Q2_NB_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q3_NB_Target_ACV__c, 'Q3_NB_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q4_NB_Target_ACV__c, 'Q4_NB_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q1_Upsell_Target_ACV__c, 'Q1_Upsell_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q2_Upsell_Target_ACV__c, 'Q2_Upsell_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q3_Upsell_Target_ACV__c, 'Q3_Upsell_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q4_Upsell_Target_ACV__c, 'Q4_Upsell_Target_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c, 'Q1_Expected_Renewal_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c, 'Q2_Expected_Renewal_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c, 'Q3_Expected_Renewal_ACV__c');
        this.formatNumberToString(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c, 'Q4_Expected_Renewal_ACV__c');

        let Region = this.transferToZero(this.currentPlanningQuota.Region_Retention_Factor__c) / 100;
        
        let calculatedNumQ1ExpectedR = this.transferToZero(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c) * Region;
        this.calculatedNumExpectedR.calculatedNumQ1ExpectedR = calculatedNumQ1ExpectedR;
        this.formatNumberToString(calculatedNumQ1ExpectedR, 'calculatedNumQ1ExpectedR', 'ren');

        let calculatedNumQ2ExpectedR = this.transferToZero(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c) * Region;
        this.calculatedNumExpectedR.calculatedNumQ2ExpectedR = calculatedNumQ2ExpectedR;
        this.formatNumberToString(calculatedNumQ2ExpectedR, 'calculatedNumQ2ExpectedR', 'ren');

        let calculatedNumQ3ExpectedR = this.transferToZero(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c) * Region;
        this.calculatedNumExpectedR.calculatedNumQ3ExpectedR = calculatedNumQ3ExpectedR;
        this.formatNumberToString(calculatedNumQ3ExpectedR, 'calculatedNumQ3ExpectedR', 'ren');

        let calculatedNumQ4ExpectedR = this.transferToZero(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c) * Region;
        this.calculatedNumExpectedR.calculatedNumQ4ExpectedR = calculatedNumQ4ExpectedR;
        this.formatNumberToString(calculatedNumQ4ExpectedR, 'calculatedNumQ4ExpectedR', 'ren');

        let RegionT = this.transferToZero(this.quotaSelected.Region_Retention_Factor__c) / 100;
        let calculatedNumQ1ExpectedRT = this.transferToZero(this.quotaSelected.Q1_Expected_Renewal_ACV__c) * RegionT;
        this.calculatedNumExpectedR.calculatedNumQ1ExpectedRT = calculatedNumQ1ExpectedRT;
        this.formatNumberToString(calculatedNumQ1ExpectedRT, 'calculatedNumQ1ExpectedRT', 'ren');

        let calculatedNumQ2ExpectedRT = this.transferToZero(this.quotaSelected.Q2_Expected_Renewal_ACV__c) * RegionT;
        this.calculatedNumExpectedR.calculatedNumQ2ExpectedRT = calculatedNumQ2ExpectedRT;
        this.formatNumberToString(calculatedNumQ2ExpectedRT, 'calculatedNumQ2ExpectedRT', 'ren');

        let calculatedNumQ3ExpectedRT = this.transferToZero(this.quotaSelected.Q3_Expected_Renewal_ACV__c) * RegionT;
        this.calculatedNumExpectedR.calculatedNumQ3ExpectedRT = calculatedNumQ3ExpectedRT;
        this.formatNumberToString(calculatedNumQ3ExpectedRT, 'calculatedNumQ3ExpectedRT', 'ren');

        let calculatedNumQ4ExpectedRT = this.transferToZero(this.quotaSelected.Q4_Expected_Renewal_ACV__c) * RegionT;
        this.calculatedNumExpectedR.calculatedNumQ4ExpectedRT = calculatedNumQ4ExpectedRT;
        this.formatNumberToString(calculatedNumQ4ExpectedRT, 'calculatedNumQ4ExpectedRT', 'ren');

        this.totalSTargetRenewal = calculatedNumQ1ExpectedR + calculatedNumQ2ExpectedR + calculatedNumQ3ExpectedR + calculatedNumQ4ExpectedR;
        this.formatNumberToString(this.totalSTargetRenewal, 'totalSTargetRenewal', 'ren');

        this.totalTTargetRenewal = calculatedNumQ1ExpectedRT + calculatedNumQ2ExpectedRT + calculatedNumQ3ExpectedRT + calculatedNumQ4ExpectedRT;
        this.formatNumberToString(this.totalTTargetRenewal, 'totalTTargetRenewal', 'ren');

        this.totalSNB = this.transferToZero(this.currentPlanningQuota.Q1_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_NB_Target_ACV__c);
        this.totalSUpsell = this.transferToZero(this.currentPlanningQuota.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Upsell_Target_ACV__c);
        this.totalSRenewal = this.transferToZero(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c);
        this.formatNumberToString(this.totalSNB, 'totalSNB');
        this.formatNumberToString(this.totalSUpsell, 'totalSUpsell');
        this.formatNumberToString(this.totalSRenewal, 'totalSRenewal');
        this.totalSQ1 = this.transferToZero(this.currentPlanningQuota.Q1_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q1_Expected_Renewal_ACV__c);
        this.totalSQ2 = this.transferToZero(this.currentPlanningQuota.Q2_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q2_Expected_Renewal_ACV__c);
        this.totalSQ3 = this.transferToZero(this.currentPlanningQuota.Q3_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q3_Expected_Renewal_ACV__c);
        this.totalSQ4 = this.transferToZero(this.currentPlanningQuota.Q4_NB_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Upsell_Target_ACV__c) + this.transferToZero(this.currentPlanningQuota.Q4_Expected_Renewal_ACV__c);
        this.formatNumberToString(this.totalSQ1, 'totalSQ1');
        this.formatNumberToString(this.totalSQ2, 'totalSQ2');
        this.formatNumberToString(this.totalSQ3, 'totalSQ3');
        this.formatNumberToString(this.totalSQ4, 'totalSQ4');

        this.totalTotalS = this.totalSQ1 + this.totalSQ2 + this.totalSQ3 + this.totalSQ4;
        this.formatNumberToString(this.totalTotalS, 'totalTotalS');


        this.formatNumberToString(this.quotaSelected.Q1_NB_Target_ACV__c, 'DQ1_NB_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q2_NB_Target_ACV__c, 'DQ2_NB_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q3_NB_Target_ACV__c, 'DQ3_NB_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q4_NB_Target_ACV__c, 'DQ4_NB_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q1_Upsell_Target_ACV__c, 'DQ1_Upsell_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q2_Upsell_Target_ACV__c, 'DQ2_Upsell_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q3_Upsell_Target_ACV__c, 'DQ3_Upsell_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q4_Upsell_Target_ACV__c, 'DQ4_Upsell_Target_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q1_Expected_Renewal_ACV__c, 'DQ1_Expected_Renewal_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q2_Expected_Renewal_ACV__c, 'DQ2_Expected_Renewal_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q3_Expected_Renewal_ACV__c, 'DQ3_Expected_Renewal_ACV__c');
        this.formatNumberToString(this.quotaSelected.Q4_Expected_Renewal_ACV__c, 'DQ4_Expected_Renewal_ACV__c');
        this.tableTemp = false;

        this.totalTNB = this.transferToZero(this.quotaSelected.Q1_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_NB_Target_ACV__c);
        this.totalTUpsell = this.transferToZero(this.quotaSelected.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Upsell_Target_ACV__c);
        this.totalTRenewal = this.transferToZero(this.quotaSelected.Q1_Expected_Renewal_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Expected_Renewal_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Expected_Renewal_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Expected_Renewal_ACV__c);
        this.formatNumberToString(this.totalTNB, 'totalTNB');
        this.formatNumberToString(this.totalTUpsell, 'totalTUpsell');
        this.formatNumberToString(this.totalTRenewal, 'totalTRenewal');
        this.totalTQ1 = this.transferToZero(this.quotaSelected.Q1_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q1_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q1_Expected_Renewal_ACV__c);
        this.totalTQ2 = this.transferToZero(this.quotaSelected.Q2_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q2_Expected_Renewal_ACV__c);
        this.totalTQ3 = this.transferToZero(this.quotaSelected.Q3_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q3_Expected_Renewal_ACV__c);
        this.totalTQ4 = this.transferToZero(this.quotaSelected.Q4_NB_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Upsell_Target_ACV__c) + this.transferToZero(this.quotaSelected.Q4_Expected_Renewal_ACV__c);
        this.formatNumberToString(this.totalTQ1, 'totalTQ1');
        this.formatNumberToString(this.totalTQ2, 'totalTQ2');
        this.formatNumberToString(this.totalTQ3, 'totalTQ3');
        this.formatNumberToString(this.totalTQ4, 'totalTQ4');

        this.totalTotalT = this.totalTQ1 + this.totalTQ2 + this.totalTQ3 + this.totalTQ4;
        this.formatNumberToString(this.totalTotalT, 'totalTotalT');
    }

    popUpMess(mess, comment, anotherTransfer, closeAction){
        this.closeAction = closeAction;
        this.anotherTransferNote = anotherTransfer
        this.notComment = comment;
        this.noteMess = mess;
        this.isModalOpen = true;
    }

    approvedNumVal(numberVal){
        const numArray = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9','.'];
        let approvedVal = true;
        for(let num in numberVal){
            if(!numArray.includes(numberVal[num])) approvedVal = false;
        }
        return approvedVal;
    }

    handelSave(){
        let canSave = true;
        let cantSaveComments = false;
        if(!this.changeIs_Made) {this.popUpMess('Please click “Apply Changes” and review the targets in the destination section before saving', false, false);}
        if(this.template.querySelector('[data-id="SQ1NB"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ2NB"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ3NB"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ4NB"]').value != '') canSave = false;

        if(this.template.querySelector('[data-id="SQ1UP"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ2UP"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ3UP"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ4UP"]').value != '') canSave = false;

        if(this.template.querySelector('[data-id="SQ1RE"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ2RE"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ3RE"]').value != '') canSave = false;
        if(this.template.querySelector('[data-id="SQ4RE"]').value != '') canSave = false;

        if(!canSave) {this.popUpMess("Please click “Apply Changes” and review the targets in the destination section before saving", false, false);}

        let commentStr = this.template.querySelector('[data-id="comment"]').value;
        if(commentStr != '' && commentStr != undefined) cantSaveComments = true;
        if(!cantSaveComments) {this.popUpMess("Please fill a comment to accompany this quota transfer.", false, false);}
        
        if(cantSaveComments && canSave && this.changeIs_Made){
            this.template.querySelector('[data-id="saveButt"]').disabled = true;
            this.spinner = true;
            for(let i = 1; i<=4; i++){
                let objectTransferNB = {};
                let q = 'Q'+i;
                let qnb = 'Q'+i+'NB';
                let tqnb = 'TQ'+i+'NB';
                let sqnbli = 'SQ'+i+'NBLi';
                if(this.quotaTransfers[qnb] != undefined){
                    objectTransferNB.title = 'Quota Transfer';
                    objectTransferNB.newTargetAmount = this.template.querySelector('[data-id="'+tqnb+'"]').value;
                    this.formatNumberToString(this.quotaTransfers[qnb].moneyPassed, qnb + '_moneyPassed');
                    objectTransferNB.moneyPassed = this.numberAfterTransfer[qnb + '_moneyPassed'];
                    objectTransferNB.newSourceAmount = this.template.querySelector('[data-id="'+sqnbli+'"]').value;
                    objectTransferNB.fieldNameChanged = q + ' NB';
                    objectTransferNB.sourceRecord = this.currentPlanningQuota.Name;
                    objectTransferNB.targetRecord = this.quotaSelected.Name;
                    this.formatNumberToString(this.currentPlanningQuota[q+'_NB_Target_ACV__c'], qnb + '_currentPlanningStartAmount');
                    this.formatNumberToString(this.quotaSelected[q+'_NB_Target_ACV__c'], qnb + '_quotaSelectedStartAmount');
                    objectTransferNB.lastSourceAmount = this.numberAfterTransfer[qnb + '_currentPlanningStartAmount'];
                    objectTransferNB.lastTargetAmount = this.numberAfterTransfer[qnb + '_quotaSelectedStartAmount'];
                    this.currentPlanningQuota[q+'_NB_Target_ACV__c'] = Number(this.quotaTemporaryTransfer[sqnbli]);
                    this.quotaSelected[q+'_NB_Target_ACV__c'] = this.quotaTemporaryTransfer[tqnb];
                    objectTransferNB.sourceId = this.currentPlanningQuota.Id;
                    objectTransferNB.targetId = this.quotaSelected.Id;
                    this.quotaTransfers[qnb] = objectTransferNB;
                }
            }
            for(let i = 1; i<=4; i++){
                let q = 'Q'+i;
                let qup = 'Q'+i+'UP';
                let tqup = 'TQ'+i+'UP';
                let squpli = 'SQ'+i+'UPLi';
                let objectTransferUp = {};
                if(this.quotaTransfers[qup] != undefined){
                    objectTransferUp.title = 'Quota Transfer';
                    objectTransferUp.newTargetAmount = this.template.querySelector('[data-id="'+tqup+'"]').value;
                    this.formatNumberToString(this.quotaTransfers[qup].moneyPassed, qup + '_moneyPassed');
                    objectTransferUp.moneyPassed = this.numberAfterTransfer[qup + '_moneyPassed'];
                    objectTransferUp.newSourceAmount = this.template.querySelector('[data-id="'+squpli+'"]').value;
                    objectTransferUp.fieldNameChanged = q + ' Upsell';
                    objectTransferUp.sourceRecord = this.currentPlanningQuota.Name;
                    objectTransferUp.targetRecord = this.quotaSelected.Name;
                    this.formatNumberToString(this.currentPlanningQuota[q+'_Upsell_Target_ACV__c'], qup + '_currentPlanningStartAmount');
                    this.formatNumberToString(this.quotaSelected[q+'_Upsell_Target_ACV__c'], qup + '_quotaSelectedStartAmount');
                    objectTransferUp.lastSourceAmount = this.numberAfterTransfer[qup + '_currentPlanningStartAmount'];
                    objectTransferUp.lastTargetAmount = this.numberAfterTransfer[qup + '_quotaSelectedStartAmount'];
                    this.currentPlanningQuota[q+'_Upsell_Target_ACV__c'] = this.quotaTemporaryTransfer[squpli];
                    this.quotaSelected[q+'_Upsell_Target_ACV__c'] = this.quotaTemporaryTransfer[tqup];
                    objectTransferUp.sourceId = this.currentPlanningQuota.Id;
                    objectTransferUp.targetId = this.quotaSelected.Id;
                    this.quotaTransfers[qup] = objectTransferUp;
                }
            }
            for(let i = 1; i<=4; i++){
                let q = 'Q'+i;
                let qre = 'Q'+i+'RE';
                let tqre = 'TQ'+i+'RE';
                let sqreli = 'SQ'+i+'RELi';
                let objectTransferRE = {};
                if(this.quotaTransfers[qre] != undefined){
                    objectTransferRE.title = 'Quota Transfer';
                    objectTransferRE.newTargetAmount = this.template.querySelector('[data-id="'+tqre+'"]').value;
                    this.formatNumberToString(this.quotaTransfers[qre].moneyPassed, qre + '_moneyPassed');
                    objectTransferRE.moneyPassed = this.numberAfterTransfer[qre + '_moneyPassed'];
                    objectTransferRE.newSourceAmount = this.template.querySelector('[data-id="'+sqreli+'"]').value;
                    objectTransferRE.fieldNameChanged = q + ' Expected Renewal';
                    objectTransferRE.sourceRecord = this.currentPlanningQuota.Name;
                    objectTransferRE.targetRecord = this.quotaSelected.Name;
                    this.formatNumberToString(this.currentPlanningQuota[q+'_Expected_Renewal_ACV__c'], qre + '_currentPlanningStartAmount');
                    this.formatNumberToString(this.quotaSelected[q+'_Expected_Renewal_ACV__c'], qre + '_quotaSelectedStartAmount');
                    objectTransferRE.lastSourceAmount = this.numberAfterTransfer[qre + '_currentPlanningStartAmount'];
                    objectTransferRE.lastTargetAmount = this.numberAfterTransfer[qre + '_quotaSelectedStartAmount'];
                    this.currentPlanningQuota[q+'_Expected_Renewal_ACV__c'] = this.quotaTemporaryTransfer[sqreli];
                    this.quotaSelected[q+'_Expected_Renewal_ACV__c'] = this.quotaTemporaryTransfer[tqre];
                    objectTransferRE.sourceId = this.currentPlanningQuota.Id;
                    objectTransferRE.targetId = this.quotaSelected.Id;
                    this.quotaTransfers[qre] = objectTransferRE;
                }
            }
            // save the comment
            this.quotaTransfers.comment = commentStr;
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
    }

    cancelAction(){
        let mess = '';
        if(this.changeIs_Made) mess = 'Please note, you have unsaved changes. Are you sure you want to exit?';
        if(!this.changeIs_Made) mess = 'Are you sure you want to exit?';
        this.popUpMess(mess, false, false, true);
    }

    closeActionCard(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showNotification(titlee, mess, vari){
        const evt = new ShowToastEvent({
            title: titlee,
            message : mess,
            variant : vari
        });
        this.dispatchEvent(evt);
    }

    formatNumberToString(num, name, strRen){
        console.log('strRen: ' + strRen);
        if(num == undefined) {num = 0;}
        if(strRen === 'ren') console.log('num first: ' + num);
        if(strRen === 'ren') num = Math.trunc(num);
        if(strRen === 'ren') console.log('num sec: ' + num);
        if(num.toString().includes('.')){
            num = Math.round(num*100)/100;
        } 
        if(strRen === 'ren') console.log('num end: ' + num);
        //if (this.isEmpty(num)) return num;
        let numAsString = num.toString();

        let numProcessed = '';

        //if (numAsString.length < 4)  return num;
        for (let i = 0; i < numAsString.length; i++){
            if (i != 0 && (i % 3) == 0 && numAsString.substr((numAsString.length - i), 1) != '.') numProcessed = ',' + numProcessed;
            numProcessed = numAsString.substr((numAsString.length - 1 - i), 1) + numProcessed;
        }
        this.numberAfterTransfer[name] = numProcessed + ' $';
    }

    isEmpty(obj){
        return ((obj == null || obj == 'undefined' || typeof(obj) == 'undefined' || obj == '') && obj !== false && obj !== '0' && obj !== 0);
    }
}